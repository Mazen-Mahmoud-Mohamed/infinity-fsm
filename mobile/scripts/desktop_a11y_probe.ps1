Add-Type -ReferencedAssemblies @('System.Drawing','System.Windows.Forms') -TypeDefinition @"
using System; using System.Runtime.InteropServices; using System.Drawing;
public static class MO { 
  [DllImport("user32.dll")] public static extern void mouse_event(int f,int x,int y,int d,int e);
  public static void Click(int x,int y){ System.Windows.Forms.Cursor.Position=new Point(x,y); System.Threading.Thread.Sleep(120); mouse_event(2,0,0,0,0); mouse_event(4,0,0,0,0);} }
"@
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Click-Leftmost([string]$Label) {
  $root = [System.Windows.Automation.AutomationElement]::RootElement
  $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $Label)
  $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
  if ($all.Count -eq 0) { return }
  $best = $all.Item(0); $bestX = [double]::MaxValue
  for ($i=0; $i -lt $all.Count; $i++) { $r = $all.Item($i).Current.BoundingRectangle; if ($r.X -lt $bestX) { $bestX = $r.X; $best = $all.Item($i) } }
  $r = $best.Current.BoundingRectangle
  [MO]::Click([int]($r.X + $r.Width/2), [int]($r.Y + $r.Height/2))
}

Get-Process mobile -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 1
$proc = Start-Process "c:\Users\mmahm\OneDrive\Desktop\new infinity project\mobile\build\windows\x64\runner\Release\mobile.exe" -PassThru -WindowStyle Maximized
Start-Sleep 12
Click-Leftmost 'Work Orders'
Start-Sleep 4
Click-Leftmost 'Overtime'
Start-Sleep 4

function Dump([string]$Name) {
  $root = [System.Windows.Automation.AutomationElement]::RootElement
  $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $Name)
  $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
  Write-Output "=== $Name count=$($all.Count) ==="
  for ($i=0; $i -lt $all.Count; $i++) {
    $r = $all.Item($i).Current.BoundingRectangle
    Write-Output "  [$i] x=$([int]$r.X) y=$([int]$r.Y) w=$([int]$r.Width) h=$([int]$r.Height)"
  }
}

Dump 'Export Excel'
Dump 'Create Order'
Dump 'Retry'

Get-Process -Id $proc.Id -ErrorAction SilentlyContinue | Stop-Process -Force
