# Desktop runtime verification — captures screenshots from the release Windows app.
$ErrorActionPreference = 'Stop'

Add-Type -ReferencedAssemblies @('System.Drawing','System.Windows.Forms') -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Drawing.Imaging;

public static class WinCapture {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, int nFlags);
  [DllImport("user32.dll")] public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

  public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public const int LEFTDOWN = 0x02;
  public const int LEFTUP = 0x04;

  public static void ClickAt(int x, int y) {
    System.Windows.Forms.Cursor.Position = new System.Drawing.Point(x, y);
    System.Threading.Thread.Sleep(150);
    mouse_event(LEFTDOWN, 0, 0, 0, 0);
    mouse_event(LEFTUP, 0, 0, 0, 0);
  }

  public static void Capture(IntPtr hwnd, string path) {
    ShowWindow(hwnd, 9);
    SetForegroundWindow(hwnd);
    System.Threading.Thread.Sleep(500);
    RECT rect;
    GetWindowRect(hwnd, out rect);
    int w = rect.Right - rect.Left;
    int h = rect.Bottom - rect.Top;
    using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(bmp)) {
        IntPtr hdc = g.GetHdc();
        PrintWindow(hwnd, hdc, 2);
        g.ReleaseHdc(hdc);
      }
      bmp.Save(path, ImageFormat.Png);
    }
  }
}
"@

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

function Wait-AppWindow {
  param([int]$TimeoutSec = 90)
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    $proc = Get-Process -Name 'mobile' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($proc -and $proc.MainWindowHandle -ne [IntPtr]::Zero) { return $proc.MainWindowHandle }
    Start-Sleep -Milliseconds 500
  }
  throw 'INFINITY/mobile window not found'
}

function Find-UiElement {
  param([string]$Name, [int]$TimeoutSec = 15)
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $cond = New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::NameProperty, $Name)
    $el = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if ($el) { return $el }
    Start-Sleep -Milliseconds 400
  }
  return $null
}

function Invoke-UiClick {
  param($Element)
  if (-not $Element) { return $false }
  try {
    $pattern = $Element.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    if ($pattern) { $pattern.Invoke(); return $true }
  } catch {}
  $rect = $Element.Current.BoundingRectangle
  [WinCapture]::ClickAt([int]($rect.X + $rect.Width / 2), [int]($rect.Y + $rect.Height / 2))
  return $true
}

function Click-SidebarLabel {
  param([string]$Label)
  $root = [System.Windows.Automation.AutomationElement]::RootElement
  $cond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, $Label)
  $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
  if ($all.Count -eq 0) { return $false }
  $best = $null
  $bestX = [double]::MaxValue
  for ($i = 0; $i -lt $all.Count; $i++) {
    $rect = $all.Item($i).Current.BoundingRectangle
    if ($rect.Width -gt 0 -and $rect.X -lt $bestX) {
      $bestX = $rect.X
      $best = $all.Item($i)
    }
  }
  return Invoke-UiClick $best
}

function Save-Shot {
  param([IntPtr]$Hwnd, [string]$Path)
  $dir = Split-Path $Path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  [WinCapture]::Capture($Hwnd, $Path)
  Write-Host "Saved $Path"
}

function Try-Login {
  param([IntPtr]$Hwnd)
  Start-Sleep -Seconds 3
  $email = Find-UiElement -Name 'Email' -TimeoutSec 4
  if (-not $email) { return }
  [WinCapture]::SetForegroundWindow($Hwnd) | Out-Null
  Start-Sleep -Milliseconds 300
  [System.Windows.Forms.SendKeys]::SendWait('admin@infinity-tech.com{TAB}Admin@12345{ENTER}')
  Start-Sleep -Seconds 8
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$exe = Join-Path $repoRoot 'mobile\build\windows\x64\runner\Release\mobile.exe'
$outDir = Join-Path $repoRoot 'mobile\build\desktop_verification'

if (-not (Test-Path $exe)) { throw "Release exe not found: $exe" }

Get-Process -Name 'mobile' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

$proc = Start-Process -FilePath $exe -PassThru -WindowStyle Maximized
$hwnd = Wait-AppWindow -TimeoutSec 120
Start-Sleep -Seconds 2
Try-Login -Hwnd $hwnd

# Work Orders
if (-not (Click-SidebarLabel 'Work Orders')) { Click-SidebarLabel 'أوامر العمل' | Out-Null }
Start-Sleep -Seconds 5
Save-Shot -Hwnd $hwnd -Path (Join-Path $outDir 'runtime_work_orders_actions_fixed.png')

# Overtime
if (-not (Click-SidebarLabel 'Overtime')) {
  Click-SidebarLabel 'Overtime Management' | Out-Null
  if (-not $?) { Click-SidebarLabel 'العمل الإضافي' | Out-Null }
}
Start-Sleep -Seconds 5
$export = Find-UiElement -Name 'Export Excel' -TimeoutSec 3
Write-Host "Export Excel a11y: $(if ($export) { 'FOUND' } else { 'missing' })"
Save-Shot -Hwnd $hwnd -Path (Join-Path $outDir 'runtime_overtime_export_fixed.png')

# Open first work order from table (click center-right content area row)
Click-SidebarLabel 'Work Orders' | Out-Null
Start-Sleep -Seconds 4
$rect = New-Object WinCapture+RECT
[WinCapture]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
[WinCapture]::ClickAt([int]($rect.Left + 520), [int]($rect.Top + 380))
Start-Sleep -Seconds 5
Save-Shot -Hwnd $hwnd -Path (Join-Path $outDir 'runtime_work_order_detail_actions_fixed.png')

$edit = Find-UiElement -Name 'Edit' -TimeoutSec 8
if ($edit) {
  Invoke-UiClick $edit | Out-Null
  Start-Sleep -Seconds 5
  Save-Shot -Hwnd $hwnd -Path (Join-Path $outDir 'runtime_work_order_edit_actions_fixed.png')
} else {
  Write-Warning 'Edit button not found for work order edit screenshot'
}

Get-Process -Id $proc.Id -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host 'Desktop verification complete.'
