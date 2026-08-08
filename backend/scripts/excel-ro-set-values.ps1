$ErrorActionPreference = 'Continue'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$s) { [void]$lines.Add($s) }

$path = (Resolve-Path '.\tmp-inspect.xlsx').Path
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  $wb = $excel.Workbooks.Open($path)
  $ws = $wb.Worksheets.Item(1)
  $cell = $ws.Range('C24')
  L ("Initial RO=$($cell.ReadingOrder) Text=[$($cell.Text)]")

  foreach ($v in @(-4131, -4154, -5002, -5003, 0, 1, 2, 3)) {
    try {
      $cell.ReadingOrder = $v
      L ("Set $v => RO=$($cell.ReadingOrder) OK Text=[$($cell.Text)]")
    } catch {
      L ("Set $v FAILED: $($_.Exception.Message)")
    }
  }

  # Try Format via NumberFormat / Orientation no-op; try Characters
  try {
    $cell.Characters(1, 2).Font.Bold = $true
    L ("Characters API works; Text=[$($cell.Text)]")
  } catch {
    L ("Characters failed: $($_.Exception.Message)")
  }

  $wb.Close($false)
}
finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}

$outPath = Join-Path (Get-Location) 'excel-ro-set-out.txt'
[System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Wrote $outPath"
