$ErrorActionPreference = 'Stop'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$s) { [void]$lines.Add($s) }

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  $wb = $excel.Workbooks.Add()
  $ws = $wb.Worksheets.Item(1)
  $ws.DisplayRightToLeft = $true

  $c = $ws.Range('A1')
  $c.Value2 = "23 ساعة و 42 دقيقة"
  $c.ReadingOrder = -4131  # xlLTR
  $c.HorizontalAlignment = -4131
  L ("Set xlLTR(-4131) => RO=$($c.ReadingOrder) Text=[$($c.Text)]")

  $c2 = $ws.Range('A2')
  $c2.Value2 = "23 ساعة و 42 دقيقة"
  $c2.ReadingOrder = -4154 # xlRTL
  L ("Set xlRTL(-4154) => RO=$($c2.ReadingOrder) Text=[$($c2.Text)]")

  $c3 = $ws.Range('A3')
  $c3.Value2 = "23 ساعة و 42 دقيقة"
  $c3.ReadingOrder = -5002 # xlContext
  L ("Set xlContext(-5002) => RO=$($c3.ReadingOrder) Text=[$($c3.Text)]")

  # Save via Excel and inspect OOXML readingOrder written by Excel itself
  $path = Join-Path (Get-Location) 'tmp-ro-probe.xlsx'
  if (Test-Path $path) { Remove-Item $path -Force }
  $wb.SaveAs($path, 51) # xlOpenXMLWorkbook
  $wb.Close($false)
}
finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  $wb = $excel.Workbooks.Open((Resolve-Path '.\tmp-ro-probe.xlsx').Path)
  $ws = $wb.Worksheets.Item(1)
  foreach ($a in @('A1','A2','A3')) {
    $cell = $ws.Range($a)
    L ("Reopen $a RO=$($cell.ReadingOrder) Text=[$($cell.Text)]")
  }
  $wb.Close($false)
}
finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}

$outPath = Join-Path (Get-Location) 'excel-ro-probe-out.txt'
[System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Wrote $outPath"
