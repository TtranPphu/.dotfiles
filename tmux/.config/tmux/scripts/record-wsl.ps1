param(
    [string]$Action = "start"
)

$eventName = "TmuxSpeechStop_$env:USERNAME"
$outputPath = "$env:TEMP\tmux-speech.wav"

if ($Action -eq "stop") {
    try {
        $stopEvent = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::AutoReset, $eventName)
        [void]$stopEvent.Set()
        $stopEvent.Dispose()
        $elapsed = 0
        while (!(Test-Path $outputPath) -and $elapsed -lt 10) {
            Start-Sleep -Milliseconds 200
            $elapsed += 0.2
        }
        if (!(Test-Path $outputPath)) { exit 1 }
        exit 0
    } catch {
        Write-Error "Failed to signal stop event: $_"
        exit 1
    }
}

$code = @'
using System;
using System.Collections.Concurrent;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;

public class WavCapture
{
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInOpen(out IntPtr hWaveIn, int uDeviceID,
        ref WaveFormat lpFormat, WaveProc dwCallback, IntPtr dwInstance, int fdwOpen);

    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInClose(IntPtr hWaveIn);

    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInPrepareHeader(IntPtr hWaveIn, IntPtr lpWaveInHdr, uint uSize);

    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInUnprepareHeader(IntPtr hWaveIn, IntPtr lpWaveInHdr, uint uSize);

    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInAddBuffer(IntPtr hWaveIn, IntPtr lpWaveInHdr, uint uSize);

    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInStart(IntPtr hWaveIn);

    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInStop(IntPtr hWaveIn);

    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveInReset(IntPtr hWaveIn);

    public const int WAVE_MAPPER = -1;
    public const int CALLBACK_FUNCTION = 0x30000;
    public const int WIM_OPEN = 0x3BE;
    public const int WIM_CLOSE = 0x3BF;
    public const int WIM_DATA = 0x3C0;
    public const int WHDR_DONE = 0x00000001;
    public const int MMSYSERR_NOERROR = 0;

    [StructLayout(LayoutKind.Sequential)]
    public struct WaveFormat
    {
        public ushort wFormatTag;
        public ushort nChannels;
        public uint nSamplesPerSec;
        public uint nAvgBytesPerSec;
        public ushort nBlockAlign;
        public ushort wBitsPerSample;
        public ushort cbSize;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WaveHeader
    {
        public IntPtr lpData;
        public uint dwBufferLength;
        public uint dwBytesRecorded;
        public IntPtr dwUser;
        public uint dwFlags;
        public uint dwLoops;
        public IntPtr lpNext;
        public IntPtr reserved;
    }

    public delegate void WaveProc(IntPtr hWaveIn, int uMsg, IntPtr dwInstance,
        IntPtr dwParam1, IntPtr dwParam2);

    private static BlockingCollection<byte[]> _dataQueue = new BlockingCollection<byte[]>();
    private static volatile bool _stopping = false;

    public static int Run(string outputPath, string stopEventName)
    {
        WaveFormat fmt = new WaveFormat();
        fmt.wFormatTag = 1;
        fmt.nChannels = 1;
        fmt.nSamplesPerSec = 16000;
        fmt.wBitsPerSample = 16;
        fmt.nBlockAlign = 2;
        fmt.nAvgBytesPerSec = 32000;
        fmt.cbSize = 0;

        WaveProc callback = OnWaveMessage;
        GCHandle callbackHandle = GCHandle.Alloc(callback);

        IntPtr hWaveIn;
        int result = waveInOpen(out hWaveIn, WAVE_MAPPER, ref fmt,
            callback, IntPtr.Zero, CALLBACK_FUNCTION);
        if (result != MMSYSERR_NOERROR)
        {
            callbackHandle.Free();
            Console.Error.WriteLine("waveInOpen failed: " + result);
            return 1;
        }

        int bufferSize = 32000;
        int numBuffers = 4;
        IntPtr[] bufferPtrs = new IntPtr[numBuffers];
        IntPtr[] headerPtrs = new IntPtr[numBuffers];
        int hdrSize = Marshal.SizeOf(typeof(WaveHeader));

        for (int i = 0; i < numBuffers; i++)
        {
            bufferPtrs[i] = Marshal.AllocHGlobal(bufferSize);
            WaveHeader header = new WaveHeader();
            header.lpData = bufferPtrs[i];
            header.dwBufferLength = (uint)bufferSize;
            header.dwFlags = 0;
            headerPtrs[i] = Marshal.AllocHGlobal(hdrSize);
            Marshal.StructureToPtr(header, headerPtrs[i], false);
            waveInPrepareHeader(hWaveIn, headerPtrs[i], (uint)hdrSize);
            waveInAddBuffer(hWaveIn, headerPtrs[i], (uint)hdrSize);
        }

        waveInStart(hWaveIn);

        bool createdNew = false;
        try
        {
            EventWaitHandle stopEvent = new EventWaitHandle(false,
                EventResetMode.AutoReset, stopEventName, out createdNew);
            if (!createdNew)
            {
                stopEvent.Reset();
            }
            stopEvent.WaitOne();
            stopEvent.Dispose();
        }
        catch
        {
            try
            {
                EventWaitHandle stopEvent = EventWaitHandle.OpenExisting(stopEventName);
                stopEvent.WaitOne();
                stopEvent.Dispose();
            }
            catch { }
        }

        _stopping = true;
        waveInStop(hWaveIn);
        waveInReset(hWaveIn);
        Thread.Sleep(300);
        waveInClose(hWaveIn);
        callbackHandle.Free();

        _dataQueue.CompleteAdding();

        var allData = new System.Collections.Generic.List<byte[]>();
        int totalSize = 0;
        foreach (byte[] data in _dataQueue.GetConsumingEnumerable())
        {
            allData.Add(data);
            totalSize += data.Length;
        }

        if (totalSize == 0)
        {
            Console.Error.WriteLine("No audio data recorded");
            return 2;
        }

        try
        {
            using (FileStream fs = new FileStream(outputPath, FileMode.Create, FileAccess.Write))
            using (BinaryWriter bw = new BinaryWriter(fs))
            {
                int dataSize = totalSize;
                bw.Write(new byte[] { (byte)'R', (byte)'I', (byte)'F', (byte)'F' });
                bw.Write(36 + dataSize);
                bw.Write(new byte[] { (byte)'W', (byte)'A', (byte)'V', (byte)'E' });
                bw.Write(new byte[] { (byte)'f', (byte)'m', (byte)'t', (byte)' ' });
                bw.Write(16);
                bw.Write((short)1);
                bw.Write((short)1);
                bw.Write(16000);
                bw.Write(32000);
                bw.Write((short)2);
                bw.Write((short)16);
                bw.Write(new byte[] { (byte)'d', (byte)'a', (byte)'t', (byte)'a' });
                bw.Write(dataSize);
                foreach (byte[] chunk in allData) bw.Write(chunk);
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("Failed to write WAV: " + ex.Message);
            return 1;
        }

        for (int i = 0; i < numBuffers; i++)
        {
            try { waveInUnprepareHeader(hWaveIn, headerPtrs[i], (uint)hdrSize); } catch { }
            Marshal.FreeHGlobal(headerPtrs[i]);
            Marshal.FreeHGlobal(bufferPtrs[i]);
        }

        return 0;
    }

    private static void OnWaveMessage(IntPtr hWaveIn, int uMsg, IntPtr dwInstance,
        IntPtr dwParam1, IntPtr dwParam2)
    {
        if (uMsg == WIM_DATA)
        {
            WaveHeader header = Marshal.PtrToStructure<WaveHeader>(dwParam1);
            if (header.dwBytesRecorded > 0 && (header.dwFlags & WHDR_DONE) != 0)
            {
                byte[] data = new byte[header.dwBytesRecorded];
                Marshal.Copy(header.lpData, data, 0, (int)header.dwBytesRecorded);
                _dataQueue.Add(data);
            }
            if (!_stopping)
            {
                waveInAddBuffer(hWaveIn, dwParam1, (uint)Marshal.SizeOf(typeof(WaveHeader)));
            }
        }
    }
}
'@

Add-Type -TypeDefinition $code -Language CSharp

try {
    $result = [WavCapture]::Run($outputPath, $eventName)
    if ($result -ne 0) {
        exit $result
    }
} catch {
    Write-Error "Recording error: $_"
    exit 1
}