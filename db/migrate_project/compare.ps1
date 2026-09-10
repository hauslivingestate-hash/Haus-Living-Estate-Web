# Runs fingerprint.sql on both projects and diffs the output. "NONE - identical" = safe to switch.
. "$PSScriptRoot\env.ps1"
foreach ($w in 'OLD','NEW') {
  Use-Db $w
  & "$PGBIN\psql.exe" -X -q -v ON_ERROR_STOP=1 -f "$PSScriptRoot\fingerprint.sql" -o "$DUMP\fp_$w.txt" 2>&1
  "$w exit=$LASTEXITCODE"
}
# multi-line policy bodies spill onto continuation lines; keep only the tagged lines
$old = Get-Content "$DUMP\fp_OLD.txt" -Encoding UTF8 | Where-Object { $_ -match '^[A-Z]+\|' }
$new = Get-Content "$DUMP\fp_NEW.txt" -Encoding UTF8 | Where-Object { $_ -match '^[A-Z]+\|' }
"--- lines by kind (OLD / NEW)"
$kinds = ($old + $new) | ForEach-Object { ($_ -split '\|')[0] } | Sort-Object -Unique
foreach ($k in $kinds) { "{0,-10} {1,5} / {2,5}" -f $k, @($old | Where-Object { $_ -like "$k|*" }).Count, @($new | Where-Object { $_ -like "$k|*" }).Count }
"--- differences ( <= only in OLD, => only in NEW )"
$diff = Compare-Object (Get-Content "$DUMP\fp_OLD.txt" -Encoding UTF8) (Get-Content "$DUMP\fp_NEW.txt" -Encoding UTF8)
if (-not $diff) { "NONE - identical" } else { $diff | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" } | Select-Object -First 80 }
