# Dot-source this: loads C:\Users\thinn\haus-migration.env and exposes Use-Old / Use-New,
# which point psql/pg_dump at a project through PG* env vars (never the command line, so
# passwords don't need URL-encoding and don't show up in process listings).
#
# Kept OUTSIDE OneDrive on purpose:
#   pg tools  -> C:\Users\thinn\pgtools\pg17    (73 MB, no reason to sync)
#   dumps     -> %TEMP%\haus-migration-dump     (contain salaries + password hashes)
#
# The tools used to live in %TEMP%, but Windows cleaned out the half of them that had not been
# touched in a week - pg_restore vanished mid-migration - so they now sit outside temp.
$global:PGBIN = if ($env:PGBIN) { $env:PGBIN } else { "C:\Users\thinn\pgtools\pg17" }
$global:DUMP  = Join-Path $env:TEMP "haus-migration-dump"
New-Item -ItemType Directory -Force $global:DUMP | Out-Null

if (-not (Test-Path (Join-Path $global:PGBIN "pg_dump.exe"))) {
  throw @"
pg_dump not found in $global:PGBIN. Download the portable client once (no install):
  `$z = "`$env:TEMP\pg17.zip"
  Invoke-WebRequest https://get.enterprisedb.com/postgresql/postgresql-17.6-1-windows-x64-binaries.zip -OutFile `$z -UseBasicParsing
  then extract only pgsql/bin/* into $global:PGBIN
"@
}

$envFile = "C:\Users\thinn\haus-migration.env"
if (-not (Test-Path $envFile)) { throw "missing $envFile (OLD_DB_URL / NEW_DB_URL / NEW_PUBLISHABLE_KEY / NEW_SECRET_KEY)" }
$global:MIG = @{}
Get-Content $envFile -Encoding UTF8 | ForEach-Object {
  if ($_ -match '^\s*([A-Za-z_]+)\s*=\s*(.*)$') {
    $v = $matches[2].Trim().Trim('"').Trim("'")
    if ($v.StartsWith('<') -and $v.EndsWith('>')) { $v = $v.Substring(1, $v.Length - 2) }
    $global:MIG[$matches[1]] = $v.Trim()
  }
}

# Must be the SESSION pooler (port 5432). Direct connections are IPv6-only and this PC has no
# IPv6; the transaction pooler (6543) breaks pg_dump.
function global:Split-PgUrl($url) {
  if ($url -notmatch '^postgres(?:ql)?://([^:]+):(.*)@([^:/@]+):(\d+)/([^?]+)') { throw "Cannot parse DB URL" }
  $p = @{ User = $matches[1]; Pass = [uri]::UnescapeDataString($matches[2]); Host = $matches[3]; Port = $matches[4]; Db = $matches[5] }
  if ($p.Pass -match 'YOUR-PASSWORD|^\[.*\]$') { throw "password in haus-migration.env is still the [YOUR-PASSWORD] placeholder - a wrong password can get this IP banned" }
  $p
}
function global:Use-Db($which) {
  $p = Split-PgUrl $global:MIG["${which}_DB_URL"]
  $env:PGHOST = $p.Host; $env:PGPORT = $p.Port; $env:PGUSER = $p.User
  $env:PGPASSWORD = $p.Pass; $env:PGDATABASE = $p.Db; $env:PGSSLMODE = "require"
  $env:PGCLIENTENCODING = "UTF8"
}
function global:Use-Old { Use-Db "OLD" }
function global:Use-New { Use-Db "NEW" }
