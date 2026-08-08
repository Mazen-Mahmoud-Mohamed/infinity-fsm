$ErrorActionPreference = 'Continue'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$s) { [void]$lines.Add($s) }

$files = @(
  'tmp-strategy-rtl-ro-ltr.xlsx',
  'tmp-strategy-rtl-no-ro.xlsx',
  'tmp-strategy-rtl-ro-rtl.xlsx',
  'tmp-strategy-ltr-no-ro.xlsx',
  'tmp-strategy-ltr-ro-ltr.xlsx',
  'tmp-inspect.xlsx'
)

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  foreach ($f in $files) {
    if (-not (Test-Path $f)) { L "MISSING $f"; continue }
    $wb = $excel.Workbooks.Open((Resolve-Path $f).Path)
    $ws = $wb.Worksheets.Item(1)

    $addr = 'C2'
    $c = $ws.Range($addr)
    if ([string]::IsNullOrEmpty([string]$c.Text)) {
      $addr = 'C24'
      $c = $ws.Range($addr)
    }
    $row = $c.Row
    $fVal = [string]$ws.Cells.Item($row, 6).Text
    $gVal = [string]$ws.Cells.Item($row, 7).Text
    $aVal = [string]$ws.Cells.Item($row, 1).Text
    $text = [string]$c.Text

    # Export single cell area to HTML to capture dir / visual markup
    $htmlPath = Join-Path (Get-Location) ("tmp-html-" + [IO.Path]::GetFileNameWithoutExtension($f) + ".html")
    $tmpWb = $excel.Workbooks.Add()
    $tmpWs = $tmpWb.Worksheets.Item(1)
    $tmpWs.DisplayRightToLeft = $ws.DisplayRightToLeft
    $tmpWs.Range('A1').Value2 = $c.Value2
    $tmpWs.Range('A1').HorizontalAlignment = $c.HorizontalAlignment
    try { $tmpWs.Range('A1').ReadingOrder = $c.ReadingOrder } catch {}
    $tmpWb.SaveAs($htmlPath, 44) # xlHtml
    $tmpWb.Close($false)

    $html = ''
    if (Test-Path $htmlPath) {
      $html = [IO.File]::ReadAllText($htmlPath, [Text.Encoding]::UTF8)
    }
    $dirMatch = [regex]::Match($html, 'dir=(?:\"|'')?(rtl|ltr)', 'IgnoreCase')
    $tdSnippet = ''
    $m = [regex]::Match($html, '<td[^>]*>[\s\S]{0,80}ساعة[\s\S]{0,80}</td>', 'IgnoreCase')
    if ($m.Success) { $tdSnippet = $m.Value -replace '\s+', ' ' }

    L ("FILE $f sheetRTL=$($ws.DisplayRightToLeft) cell=$addr RO=$($c.ReadingOrder) Text=[$text] A=[$aVal] F=[$fVal] G=[$gVal] htmlDir=$($dirMatch.Value) td=$tdSnippet")
    $wb.Close($false)
  }
}
finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

$outPath = Join-Path (Get-Location) 'excel-strategies-out.txt'
[System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Wrote $outPath"
