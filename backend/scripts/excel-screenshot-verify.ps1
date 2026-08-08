$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$path = (Resolve-Path '.\tmp-inspect.xlsx').Path
$shot = Join-Path (Get-Location) 'excel-visual-verify.png'
$outTxt = Join-Path (Get-Location) 'excel-visual-verify.txt'
$lines = New-Object System.Collections.Generic.List[string]
function L([string]$s) { [void]$lines.Add($s) }

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$excel.DisplayAlerts = $false
$excel.WindowState = -4137 # xlMaximized
Start-Sleep -Milliseconds 800
try {
  $wb = $excel.Workbooks.Open($path)
  $ws = $wb.Worksheets.Item(1)
  $ws.Activate()
  L ("DisplayRightToLeft=$($ws.DisplayRightToLeft)")

  # Focus employee summary area A22:K25
  $range = $ws.Range('A22:K25')
  $range.Select()
  $excel.ActiveWindow.Zoom = 120
  Start-Sleep -Milliseconds 1000

  # ReadingOrder constants probe without setting (read-only check of our cells)
  foreach ($addr in @('C24','D24','F24','G24')) {
    $cell = $ws.Range($addr)
    L ("$addr Text=[$($cell.Text)] RO=$($cell.ReadingOrder)")
  }

  # Try set via Style
  try {
    $ws.Range('C24').ReadingOrder = 1
    L ("Set RO=1 on C24 => $($ws.Range('C24').ReadingOrder)")
  } catch {
    L ("Set RO=1 failed: $($_.Exception.Message)")
  }
  try {
    $ws.Range('C24').ReadingOrder = -4131
    L ("Set RO=-4131 on C24 => $($ws.Range('C24').ReadingOrder)")
  } catch {
    L ("Set RO=-4131 failed: $($_.Exception.Message)")
  }

  # Screenshot the Excel window
  $hwnd = $excel.Hwnd
  $proc = Get-Process | Where-Object { $_.MainWindowHandle -eq $hwnd } | Select-Object -First 1
  Start-Sleep -Milliseconds 500
  [System.Windows.Forms.SendKeys]::SendWait('%{PRTSC}')
  Start-Sleep -Milliseconds 700
  if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    $img.Save($shot, [System.Drawing.Imaging.ImageFormat]::Png)
    L ("Saved screenshot $shot")
  } else {
    L 'Clipboard had no image; trying form bounds capture'
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $bmp.Save($shot, [System.Drawing.Imaging.ImageFormat]::Png)
    L ("Saved fullscreen screenshot $shot")
  }

  $wb.Close($false)
}
finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

[System.IO.File]::WriteAllLines($outTxt, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Wrote $outTxt"
