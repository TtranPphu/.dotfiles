# Read ZMK split keyboard battery levels via Windows Bluetooth LE APIs
# Output: "left_percent right_percent" or exits 1 on failure

Add-Type -AssemblyName System.Runtime.WindowsRuntime

# C# helper to read a byte from WinRT IBuffer via IBufferByteAccess COM interface
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[ComImport]
[Guid("905a0fef-bc53-11df-8c49-001e4fc686da")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IBufferByteAccess
{
    IntPtr Buffer();
}

public static class BufferHelper
{
    public static byte ReadFirstByte(object comObject)
    {
        var acc = (IBufferByteAccess)comObject;
        IntPtr ptr = acc.Buffer();
        byte[] data = new byte[1];
        Marshal.Copy(ptr, data, 0, 1);
        return data[0];
    }
}
"@

$null = [Windows.Devices.Bluetooth.BluetoothLEDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]
$null = [Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceService, Windows.Devices.Bluetooth.GenericAttributeProfile, ContentType = WindowsRuntime]
$null = [Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult, Windows.Devices.Bluetooth.GenericAttributeProfile, ContentType = WindowsRuntime]
$null = [Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult, Windows.Devices.Bluetooth.GenericAttributeProfile, ContentType = WindowsRuntime]

function AwaitOp($asyncOp, $resultType) {
  $m = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq "AsTask" -and $_.IsGenericMethodDefinition -and $_.GetGenericArguments().Length -eq 1 -and $_.GetParameters().Length -eq 1 -and $_.GetParameters()[0].ParameterType.Name.Contains("IAsyncOperation") }
  if (-not $m) { exit 1 }
  $g = $m.MakeGenericMethod($resultType)
  $t = $g.Invoke($null, @(, $asyncOp))
  if (-not $t.Wait(10000)) { exit 1 }
  return $t.Result
}

$btAddr = $null
try {
  $device = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -like "*Cornix*" } | Select-Object -First 1
  if (-not $device) { exit 1 }
  $instanceId = $device.InstanceId
  if ($instanceId -match 'BTHLE\\DEV_([0-9A-Fa-f]{12})') {
    $btAddr = [System.Convert]::ToInt64($matches[1].ToUpper(), 16)
  }
} catch { exit 1 }
if (-not $btAddr) { exit 1 }

try {
  $ble = AwaitOp ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($btAddr)) ([Windows.Devices.Bluetooth.BluetoothLEDevice])
} catch { exit 1 }
if (-not $ble) { exit 1 }

$left  = $null
$right = $null

try {
  $gattResult = AwaitOp ($ble.GetGattServicesAsync()) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult])
} catch { $ble.Dispose(); exit 1 }

if ($gattResult -and $gattResult.Status -eq "Success") {
  foreach ($svc in $gattResult.Services) {
    if ($svc.Uuid.ToString() -ne "0000180f-0000-1000-8000-00805f9b34fb") { continue }

    try {
      $charResult = AwaitOp ($svc.GetCharacteristicsAsync()) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
    } catch { continue }
    if (-not $charResult -or $charResult.Status -ne "Success") { continue }

    foreach ($ch in $charResult.Characteristics) {
      if ($ch.Uuid.ToString() -ne "00002a19-0000-1000-8000-00805f9b34fb") { continue }

      # Detect right (auxiliary) vs left (main) via UserDescription property
      $isAux = ($ch.UserDescription -eq "auxiliary" -or $ch.UserDescription -eq "Peripheral 0")

      try {
        $rv = AwaitOp ($ch.ReadValueAsync()) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattReadResult])
      } catch { continue }
      if (-not $rv -or $rv.Status -ne "Success") { continue }

      $lvl = [int][BufferHelper]::ReadFirstByte($rv.Value)
      if ($lvl -lt 0 -or $lvl -gt 100) { continue }

      if ($isAux) { $right = $lvl }
      elseif ($null -eq $left) { $left = $lvl }
      elseif ($null -eq $right) { $right = $lvl }
    }
  }
}

$ble.Dispose()

if ($null -ne $left) {
  Write-Output "$left $(if ($null -ne $right) { $right } else { 0 })"
  exit 0
}
exit 1
