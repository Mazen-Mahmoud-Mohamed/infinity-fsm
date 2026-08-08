$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$path = Resolve-Path '.\tmp-inspect.xlsx'
$outPath = Join-Path (Get-Location) 'excel-com-out.txt'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$s) { [void]$lines.Add($s) }

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  L ("Excel version: " + $excel.Version)
  $wb = $excel.Workbooks.Open($path.Path)
  $ws = $wb.Worksheets.Item(1)
  L ("Sheet name: " + $ws.Name)
  L ("DisplayRightToLeft: " + $ws.DisplayRightToLeft)

  for ($r = 20; $r -le 26; $r++) {
    for ($c = 1; $c -le 11; $c++) {
      $cell = $ws.Cells.Item($r, $c)
      $text = [string]$cell.Text
      if (-not [string]::IsNullOrWhiteSpace($text)) {
        $addr = $cell.Address($false, $false)
        L ("$addr Text=[$text] RO=$($cell.ReadingOrder) Val=[$($cell.Value2)]")
      }
    }
  }

  foreach ($addr in @('C24','D24','C25','D25','A24','F24','G24','A23','F23','G23')) {
    $cell = $ws.Range($addr)
    L ("PROBE $addr Text=[$($cell.Text)] RO=$($cell.ReadingOrder) HAlign=$($cell.HorizontalAlignment)")
  }

  $wb.Close($false)
}
finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

[System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Output ("Wrote $outPath")
