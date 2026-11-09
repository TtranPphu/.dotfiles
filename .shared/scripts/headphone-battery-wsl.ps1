# Read headphone/earbud battery levels via Windows PnP.
# Output: "<level> 0 0" (the util uses the first value); exit 1 when unknown.
#
# The host runs PowerShell in ConstrainedLanguage mode, so this avoids WinRT
# and Add-Type. The Hands-Free AG child only exposes
# DEVPKEY_Device_BatteryLevel while the earbuds are connected.
$patterns = @("*OPPO Enco*", "*Nothing Ear*")

foreach ($device in Get-PnpDevice -Class Bluetooth) {
  if ($device.Status -ne "OK") { continue }

  $matched = $false
  foreach ($pattern in $patterns) {
    if ($device.FriendlyName -like $pattern) { $matched = $true; break }
  }
  if (-not $matched) { continue }
  if ($device.InstanceId -notmatch 'DEV_([0-9A-Fa-f]{12})') { continue }

  $mac = $matches[1].ToUpper()
  foreach ($child in Get-PnpDevice | Where-Object {
      $_.InstanceId -match $mac -and
      $_.InstanceId -notlike "BTHENUM\DEV_*" -and
      $_.Class -ne "Bluetooth"
    }) {
    $level = Get-PnpDeviceProperty -InstanceId $child.InstanceId `
      -KeyName "DEVPKEY_Device_BatteryLevel" -ErrorAction SilentlyContinue
    if ($level -and $level.Data -match '^\d+$' -and
        [int]$level.Data -ge 0 -and [int]$level.Data -le 100) {
      Write-Output "$([int]$level.Data) 0 0"
      exit 0
    }
  }
}

exit 1
