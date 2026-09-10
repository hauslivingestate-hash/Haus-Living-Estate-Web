# Full copy OLD -> NEW: structure, data, accounts, grants, storage policies, cron, event trigger,
# then a line-by-line diff of both projects. Safe to re-run: NEW is rebuilt from a fresh dump
# every time. Run the real one only while the team has stopped saving AND nobody is applying
# migrations to the old project.
#
#   powershell -File db\migrate_project\full_cutover.ps1
#
# Last line of output must be "NONE - identical" before switching the app over.
. "$PSScriptRoot\env.ps1"
$d = $DUMP
$enc = New-Object System.Text.UTF8Encoding($false)
function Run-Psql([string[]]$a) {
  & "$PGBIN\psql.exe" -X -q -v ON_ERROR_STOP=1 @a -o NUL 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch "NOTICE:" }
  if ($LASTEXITCODE) { throw "psql failed: $a" }
}
$t0 = Get-Date
try {
  # ---- 1. snapshot OLD
  Use-Old
  $photos = & "$PGBIN\psql.exe" -X -A -t -c "select count(*) from storage.objects"
  if ([int]$photos -gt 0) { throw "old project now has $photos photo(s) in Storage - pg_dump does not copy the files, copy them separately first" }
  & "$PGBIN\pg_dump.exe" -Fc -s -n public -f "$d\schema.dump";                       if ($LASTEXITCODE) { throw "schema dump" }
  # 2>$null: pg_dump warns about the main_1_hr <-> teams FK cycle; harmless under replica mode
  & "$PGBIN\pg_dump.exe" -a -n public -f "$d\data_public.sql" 2>$null;                if ($LASTEXITCODE) { throw "data dump" }
  & "$PGBIN\pg_dump.exe" -a -t auth.users -t auth.identities -f "$d\data_auth.sql";   if ($LASTEXITCODE) { throw "auth dump" }
  & "$PGBIN\psql.exe" -X -A -t -f "$PSScriptRoot\gen_extras.sql" -o "$d\extras.sql"; if ($LASTEXITCODE) { throw "extras gen" }
  $x = [IO.File]::ReadAllText("$d\extras.sql") -replace '\bhas_perm\(', 'public.has_perm(' -replace 'execute function rls_auto_enable\(\)', 'execute function public.rls_auto_enable()'
  [IO.File]::WriteAllText("$d\extras.sql", $x, $enc)
  # the new project already owns the public schema, its comment and the default ACLs
  $list = & "$PGBIN\pg_restore.exe" -l "$d\schema.dump" | ForEach-Object { if ($_ -match 'SCHEMA - public|COMMENT - SCHEMA public|DEFAULT ACL') { ";$_" } else { $_ } }
  [IO.File]::WriteAllLines("$d\schema.filtered.list", [string[]]$list, $enc)
  "[{0:N0}s] snapshot of OLD taken" -f ((Get-Date) - $t0).TotalSeconds

  # ---- 2. rebuild NEW
  Use-New
  Run-Psql @('-f', "$PSScriptRoot\pre.sql")
  & "$PGBIN\pg_restore.exe" --clean --if-exists --single-transaction --exit-on-error -L "$d\schema.filtered.list" -d $env:PGDATABASE "$d\schema.dump"
  if ($LASTEXITCODE) { throw "schema restore" }
  Run-Psql @('--single-transaction', '-f', "$PSScriptRoot\final_reset.sql", '-f', "$d\data_auth.sql", '-f', "$d\data_public.sql")
  Run-Psql @('-f', "$PSScriptRoot\post.sql")
  Run-Psql @('--single-transaction', '-f', "$d\extras.sql")
  "[{0:N0}s] NEW rebuilt" -f ((Get-Date) - $t0).TotalSeconds
} catch {
  "FAILED: $_"
  # never leave NEW with the auto-grant defaults switched off
  Use-New; & "$PGBIN\psql.exe" -X -q -f "$PSScriptRoot\post.sql" -o NUL
  exit 1
}

# ---- 3. verify
& "$PSScriptRoot\compare.ps1"
"total {0:N0}s" -f ((Get-Date) - $t0).TotalSeconds
