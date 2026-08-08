$ErrorActionPreference = 'Stop'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$s) { [void]$lines.Add($s) }

$path = (Resolve-Path '.\tmp-inspect.xlsx').Path
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  $wb = $excel.Workbooks.Open($path)
  $ws = $wb.Worksheets.Item(1)
  L ("RTL=$($ws.DisplayRightToLeft)")
  L ("C24 before RO=$($ws.Range('C24').ReadingOrder) Text=[$($ws.Range('C24').Text)]")

  # Turn OFF sheet RTL and re-check Text (visual BiDi base often follows sheet)
  $ws.DisplayRightToLeft = $false
  L ("After sheet LTR: C24 RO=$($ws.Range('C24').ReadingOrder) Text=[$($ws.Range('C24').Text)]")
  L ("F24=[$($ws.Range('F24').Text)] G24=[$($ws.Range('G24').Text)] A24=[$($ws.Range('A24').Text)]")

  # Save a LTR-sheet copy for OOXML compare
  $savePath = Join-Path (Get-Location) 'tmp-inspect-ltr-sheet.xlsx'
  if (Test-Path $savePath) { Remove-Item $savePath -Force }
  $wb.SaveAs($savePath, 51)
  $wb.Close($false)
}
finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

$outPath = Join-Path (Get-Location) 'excel-ro-fix-out.txt'
[System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Wrote $outPath"
