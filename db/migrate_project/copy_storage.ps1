# Brings NEW's Storage in line with OLD: the buckets, then the FILES themselves.
#
# pg_dump moves rows, never bytes, so without this every avatar and listing photo 404s after
# the cutover. Buckets are created through the storage API and files are re-uploaded through it
# (rather than inserted as storage.objects rows) so the new project owns them properly; ids and
# timestamps are new by design, and fingerprint.sql compares bucket/name/size instead.
#
# Reads from the old project over its PUBLIC url - both buckets are public. A private bucket
# would need the old project's secret key, which this script does not have; it says so and stops.
#
# Safe to re-run: buckets are updated in place, files are upserted, and files that exist only
# in NEW (left over from an earlier copy) are deleted.
. "$PSScriptRoot\env.ps1"

function Get-Ref($which) {
  # the pooler user is "postgres.<project-ref>"
  $u = (Split-PgUrl $MIG["${which}_DB_URL"]).User
  if ($u -notmatch '^postgres\.([a-z0-9]+)$') { throw "cannot read project ref from $which user '$u'" }
  $matches[1]
}
$oldRef = Get-Ref "OLD"
$newRef = Get-Ref "NEW"
$secret = $MIG["NEW_SECRET_KEY"]
# Supabase rejects secret keys sent with a browser-looking User-Agent, and PowerShell sends
# "Mozilla/..." by default - hence the explicit one on every call below.
$UA = "haus-migration/1.0"
$H  = @{ apikey = $secret; Authorization = "Bearer $secret" }
function Esc($name) { ($name -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/' }

# ---- 1. buckets
Use-Old
$bucketJson = & "$PGBIN\psql.exe" -X -A -t -c @"
select coalesce(json_agg(json_build_object('id', id, 'name', name, 'public', public,
       'file_size_limit', file_size_limit, 'allowed_mime_types', allowed_mime_types))::text, '[]')
from storage.buckets
"@
if ($LASTEXITCODE) { throw "could not list buckets on OLD" }
$buckets = $bucketJson | ConvertFrom-Json
foreach ($b in $buckets) {
  $body = @{ id = $b.id; name = $b.name; public = $b.public }
  if ($null -ne $b.file_size_limit)    { $body.file_size_limit = $b.file_size_limit }
  if ($null -ne $b.allowed_mime_types) { $body.allowed_mime_types = @($b.allowed_mime_types) }
  $json = $body | ConvertTo-Json -Compress
  try {
    Invoke-WebRequest -Uri "https://$newRef.supabase.co/storage/v1/bucket" -Method Post -Headers $H `
      -ContentType "application/json" -Body $json -UseBasicParsing -UserAgent $UA -ErrorAction Stop | Out-Null
    "bucket $($b.id): created"
  } catch {
    # already there - push the settings instead (public flag, size limit, mime types)
    $body.Remove('id')
    Invoke-WebRequest -Uri "https://$newRef.supabase.co/storage/v1/bucket/$($b.id)" -Method Put -Headers $H `
      -ContentType "application/json" -Body ($body | ConvertTo-Json -Compress) -UseBasicParsing -UserAgent $UA -ErrorAction Stop | Out-Null
    "bucket $($b.id): updated"
  }
}

# ---- 2. files
$rows = & "$PGBIN\psql.exe" -X -A -t -F "`t" -c @"
select o.bucket_id, o.name, coalesce(o.metadata->>'mimetype','application/octet-stream'), coalesce(o.metadata->>'size','0'), b.public
from storage.objects o join storage.buckets b on b.id = o.bucket_id order by 1, 2
"@
if ($LASTEXITCODE) { throw "could not list objects on OLD" }
$rows = @($rows | Where-Object { $_ })
"$($rows.Count) file(s) to copy from $oldRef -> $newRef"

$private = @($rows | Where-Object { ($_ -split "`t")[4] -ne 't' })
if ($private.Count -gt 0) { throw "$($private.Count) file(s) sit in a private bucket - this script can only read public ones" }

$ok = 0; $failed = @(); $wanted = @{}
foreach ($r in $rows) {
  $b, $name, $mime, $size, $null = $r -split "`t"
  $wanted["$b/$name"] = $true
  $tmp = Join-Path $DUMP ("obj_" + [guid]::NewGuid().ToString('N'))
  try {
    Invoke-WebRequest -Uri "https://$oldRef.supabase.co/storage/v1/object/public/$b/$(Esc $name)" -OutFile $tmp -UseBasicParsing -UserAgent $UA -ErrorAction Stop
    $got = (Get-Item $tmp).Length
    if ($size -ne '0' -and [int]$got -ne [int]$size) { throw "size mismatch: got $got, expected $size" }
    Invoke-WebRequest -Uri "https://$newRef.supabase.co/storage/v1/object/$b/$(Esc $name)" -Method Post `
      -Headers ($H + @{ "x-upsert" = "true" }) -ContentType $mime `
      -InFile $tmp -UseBasicParsing -UserAgent $UA -ErrorAction Stop | Out-Null
    $ok++
  } catch {
    $failed += "$b/$name -> $($_.Exception.Message)"
  } finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
  }
}
"uploaded $ok/$($rows.Count)"
if ($failed) { $failed | ForEach-Object { "FAILED $_" }; throw "$($failed.Count) file(s) did not copy" }

# ---- 3. drop anything NEW has that OLD does not (leftovers from an earlier copy)
Use-New
$have = @(& "$PGBIN\psql.exe" -X -A -t -c "select bucket_id || '/' || name from storage.objects" | Where-Object { $_ })
$stale = @($have | Where-Object { -not $wanted.ContainsKey($_) })
foreach ($s in $stale) {
  $b, $name = $s -split '/', 2
  Invoke-WebRequest -Uri "https://$newRef.supabase.co/storage/v1/object/$b/$(Esc $name)" -Method Delete `
    -Headers $H -UseBasicParsing -UserAgent $UA -ErrorAction Stop | Out-Null
  "deleted stale $s"
}

# verify against the new project's own catalogue, not against what this script thinks it did
& "$PGBIN\psql.exe" -X -A -t -F ' :: ' -c "select bucket_id, count(*), sum((metadata->>'size')::bigint) from storage.objects group by 1 order by 1"
