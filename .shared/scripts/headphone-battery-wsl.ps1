# Read headphone/earbud battery levels via Windows PnP
# Output: "<left> <right> <case>" — three space-separated ints (0 = unknown)
#
# Uses WinRT BluetoothDevice API to find connected device by name,
# then reads battery via PnP DEVPKEY_Device_BatteryLevel.
# Falls back to PnP-only scan if WinRT unavailable.

$patterns = @("*OPPO Enco*", "*Nothing Ear*")

$connectedAddr = $null

# Try WinRT first to find which device is actually connected
try {
  Add-Type -AssemblyName System.Runtime.WindowsRuntime
  $null = [Windows.Devices.Bluetooth.BluetoothDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]

  $m = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq "AsTask" -and $_.IsGenericMethodDefinition -and $_.GetGenericArguments().Length -eq 1 -and $_.GetParameters().Length -eq 1 -and $_.GetParameters()[0].ParameterType.Name.Contains("IAsyncOperation") }
  if ($m) {
    $g = $m.MakeGenericMethod([Windows.Devices.Bluetooth.BluetoothDevice])
    foreach ($pattern in $patterns) {
      $devices = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -like $pattern -and $_.Status -eq "OK" }
      foreach ($device in $devices) {
        $instanceId = $device.InstanceId
        if ($instanceId -match 'DEV_([0-9A-Fa-f]{12})') {
          $btAddr = [System.Convert]::ToInt64($matches[1].ToUpper(), 16)
          try {
            $asyncOp = [Windows.Devices.Bluetooth.BluetoothDevice]::FromBluetoothAddressAsync($btAddr)
            $t = $g.Invoke($null, @(, $asyncOp))
            if ($t.Wait(3000)) {
              $btDev = $t.Result
              if ($btDev.ConnectionStatus -eq "Connected") {
                $connectedAddr = $btAddr
                $btDev.Dispose()
                break
              }
              $btDev.Dispose()
            }
          } catch { continue }
        }
      }
      if ($connectedAddr) { break }
    }
  }
} catch { <# WinRT unavailable, fall through to PnP #> }

if ($connectedAddr) {
  # PnP lookup by MAC for the connected device
  $mac = "{0:X12}" -f $connectedAddr
  $children = Get-PnpDevice | Where-Object {
    $_.InstanceId -match $mac -and $_.InstanceId -notlike "BTHENUM\\DEV_*" -and $_.Class -ne "Bluetooth"
  }
  foreach ($child in $children) {
    $level = Get-PnpDeviceProperty -InstanceId $child.InstanceId -KeyName "DEVPKEY_Device_BatteryLevel" -ErrorAction SilentlyContinue
    if ($level -and $level.Data -match '^\d+$' -and [int]$level.Data -ge 0 -and [int]$level.Data -le 100) {
      Write-Output "$([int]$level.Data) 0 0"
      exit 0
    }
  }
  exit 1
}

# Fallback: PnP-only scan (may return stale data for disconnected devices)
foreach ($pattern in $patterns) {
  $device = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -like $pattern -and $_.Status -eq "OK" } | Select-Object -First 1
  if (-not $device) { continue }
  $instanceId = $device.InstanceId
  if ($instanceId -match 'DEV_([0-9A-Fa-f]{12})') {
    $mac = $matches[1]
    $children = Get-PnpDevice | Where-Object {
      $_.InstanceId -match $mac -and $_.InstanceId -notlike "BTHENUM\\DEV_*" -and $_.Class -ne "Bluetooth"
    }
    foreach ($child in $children) {
      $level = Get-PnpDeviceProperty -InstanceId $child.InstanceId -KeyName "DEVPKEY_Device_BatteryLevel" -ErrorAction SilentlyContinue
      if ($level -and $level.Data -match '^\d+$' -and [int]$level.Data -ge 0 -and [int]$level.Data -le 100) {
        Write-Output "$([int]$level.Data) 0 0"
        exit 0
      }
    }
  }
}
exit 1
