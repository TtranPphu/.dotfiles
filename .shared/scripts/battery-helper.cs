// Read Bluetooth device battery levels on Windows.
//
// The Windows host runs PowerShell in ConstrainedLanguage mode, which blocks
// Add-Type and WinRT method calls. This helper does the GATT reads as a native
// process instead.
//
// Usage: battery-helper.exe keyboard|mouse
// Output: keyboard "left right", mouse "<percent>"; exit 1 on failure.
using System;
using System.Management;
using System.Text.RegularExpressions;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Storage.Streams;

internal static class Program
{
    private static readonly Guid BatteryService =
        Guid.Parse("0000180f-0000-1000-8000-00805f9b34fb");
    private static readonly Guid BatteryLevel =
        Guid.Parse("00002a19-0000-1000-8000-00805f9b34fb");

    private static int Main(string[] args)
    {
        string mode = args.Length > 0 ? args[0] : "";
        string name;
        if (mode == "keyboard") name = "Cornix";
        else if (mode == "mouse") name = "LIFT";
        else return 1;

        ulong address;
        if (!FindAddress(name, out address)) return 1;

        var deviceOp = BluetoothLEDevice.FromBluetoothAddressAsync(address).AsTask();
        if (!deviceOp.Wait(5000) || deviceOp.Result == null) return 1;

        using (var device = deviceOp.Result)
        {
            var servicesOp = device.GetGattServicesAsync().AsTask();
            if (!servicesOp.Wait(5000)) return 1;
            var services = servicesOp.Result;
            if (services.Status != GattCommunicationStatus.Success) return 1;

            int? left = null;
            int? right = null;

            foreach (var service in services.Services)
            {
                if (service.Uuid != BatteryService) continue;

                var charsOp = service.GetCharacteristicsAsync().AsTask();
                if (!charsOp.Wait(5000)) continue;
                var chars = charsOp.Result;
                if (chars.Status != GattCommunicationStatus.Success) continue;

                foreach (var characteristic in chars.Characteristics)
                {
                    if (characteristic.Uuid != BatteryLevel) continue;

                    var readOp = characteristic
                        .ReadValueAsync(BluetoothCacheMode.Uncached).AsTask();
                    if (!readOp.Wait(5000)) continue;
                    var read = readOp.Result;
                    if (read.Status != GattCommunicationStatus.Success) continue;

                    int level = DataReader.FromBuffer(read.Value).ReadByte();
                    if (level < 0 || level > 100) continue;

                    if (mode == "mouse")
                    {
                        Console.WriteLine(level);
                        return 0;
                    }

                    bool auxiliary =
                        characteristic.UserDescription == "auxiliary" ||
                        characteristic.UserDescription == "Peripheral 0";
                    if (auxiliary) right = level;
                    else if (!left.HasValue) left = level;
                    else if (!right.HasValue) right = level;
                }
            }

            if (left.HasValue)
            {
                Console.WriteLine("{0} {1}", left.Value, right ?? 0);
                return 0;
            }
        }

        return 1;
    }

    // Match the PnP friendly name and pull the BLE address from its instance ID.
    private static bool FindAddress(string name, out ulong address)
    {
        address = 0;
        using (var searcher = new ManagementObjectSearcher(
            "SELECT Name,PNPDeviceID,Status FROM Win32_PnPEntity " +
            "WHERE PNPClass='Bluetooth'"))
        {
            foreach (ManagementObject device in searcher.Get())
            {
                string friendly = device["Name"] as string;
                string id = device["PNPDeviceID"] as string;
                string status = device["Status"] as string;
                if (friendly == null || id == null || status != "OK") continue;
                if (!friendly.Contains(name)) continue;

                var match = Regex.Match(id, @"DEV_([0-9A-Fa-f]{12})");
                if (!match.Success) continue;

                address = Convert.ToUInt64(match.Groups[1].Value, 16);
                return true;
            }
        }
        return false;
    }
}
