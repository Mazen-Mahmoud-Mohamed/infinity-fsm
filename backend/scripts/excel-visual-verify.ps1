$ErrorActionPreference = 'Stop'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$s) { [void]$lines.Add($s) }

$path = (Resolve-Path '.\tmp-inspect.xlsx').Path
$htmlPath = Join-Path (Get-Location) 'tmp-visual-verify.html'
$htmlDir = Join-Path (Get-Location) 'tmp-visual-verify_files'
if (Test-Path $htmlPath) { Remove-Item $htmlPath -Force }
if (Test-Path $htmlDir) { Remove-Item $htmlDir -Recurse -Force }

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  $wb = $excel.Workbooks.Open($path)
  $ws = $wb.Worksheets.Item(1)
  L ("sheetRTL=$($ws.DisplayRightToLeft)")

  # Find header by scanning column A for known ASCII-safe marker via Value2 length + neighbor
  $headerRow = 0
  for ($r = 1; $r -le 40; $r++) {
    $a = [string]$ws.Cells.Item($r, 1).Value2
    $f = [string]$ws.Cells.Item($r, 6).Value2
    $g = [string]$ws.Cells.Item($r, 7).Value2
    # Employee header row: A and F/G are non-empty Arabic labels; next row has email-like B
    $bNext = [string]$ws.Cells.Item($r + 1, 2).Value2
    if ($a -and $f -and $g -and $bNext -like '*@*') {
      $headerRow = $r
      break
    }
  }
  L ("headerRow=$headerRow")
  if ($headerRow -eq 0) { throw 'Employee header row not found' }

  $dr = $headerRow + 1
  $labels = @('A','B','C','D','E','F','G','H','I','J','K')
  for ($c = 1; $c -le 11; $c++) {
    L ("H$($labels[$c-1])=[$($ws.Cells.Item($headerRow,$c).Text)]")
  }
  for ($c = 1; $c -le 11; $c++) {
    $cell = $ws.Cells.Item($dr, $c)
    L ("D$($labels[$c-1]) Text=[$($cell.Text)] RO=$($cell.ReadingOrder)")
  }

  # Duration-only HTML export (Excel writes dir=LTR when readingOrder is LTR)
  $tmp = $excel.Workbooks.Add()
  $tmpWs = $tmp.Worksheets.Item(1)
  $tmpWs.DisplayRightToLeft = $false
  $src = $ws.Cells.Item($dr, 3)
  $dst = $tmpWs.Range('A1')
  $dst.Value2 = $src.Value2
  $dst.HorizontalAlignment = $src.HorizontalAlignment
  try { $dst.ReadingOrder = $src.ReadingOrder } catch { L ("copy RO failed: $($_.Exception.Message)") }
  $tmp.SaveAs($htmlPath, 44)
  $tmp.Close($false)
  $wb.Close($false)
}
finally {
  try { $excel.Quit() } catch {}
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

$sheetHtml = Join-Path $htmlDir 'sheet001.html'
if (-not (Test-Path $sheetHtml)) { $sheetHtml = Join-Path $htmlDir 'sheet001.htm' }
if (Test-Path $sheetHtml) {
  $bytes = [IO.File]::ReadAllBytes($sheetHtml)
  $html = [Text.Encoding]::Default.GetString($bytes)
  L ("htmlHasDirLTR=$($html -match 'dir=LTR')")
  L ("htmlHasTdDirRTL=$($html -match '<td[^>]*dir=RTL')")
  if ($html -match 'dir=LTR') {
    L 'EXCEL_RENDER_DIR=LTR (hours-before-minutes visual base)'
  } elseif ($html -match 'dir=RTL') {
    L 'EXCEL_RENDER_DIR=RTL (would reverse duration visually)'
  }
} else {
  L 'html sheet file missing'
}

$outPath = Join-Path (Get-Location) 'excel-visual-verify-out.txt'
[System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Wrote $outPath"
