using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Windows;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Storage.Streams;

namespace AevraPCNotify;

public partial class MainWindow : Window
{
    private const int DiscoveryPort = 4748;
    private const int TcpPort = 4747;
    private static readonly Guid ServiceUuid = Guid.Parse("A3E90001-4B4F-4D3A-9A11-57F2D7A9E001");
    private static readonly Guid MessageUuid = Guid.Parse("A3E90002-4B4F-4D3A-9A11-57F2D7A9E001");
    private IPEndPoint? _wifiEndpoint;
    private ulong? _bluetoothAddress;

    public MainWindow() => InitializeComponent();

    private async void Discover_Click(object sender, RoutedEventArgs e) => await DiscoverAsync();
    private async void Test_Click(object sender, RoutedEventArgs e) => await SendAsync("ping");
    private async void Send_Click(object sender, RoutedEventArgs e) => await SendAsync("notify");

    private async Task DiscoverAsync()
    {
        StatusText.Text = "Searching over Wi-Fi…";
        _wifiEndpoint = await DiscoverWifiAsync();
        if (_wifiEndpoint != null)
        {
            ConnectionText.Text = $"Wi-Fi • {_wifiEndpoint.Address}";
            StatusText.Text = "Aevra found automatically over Wi-Fi.";
            return;
        }

        StatusText.Text = "Wi-Fi discovery did not find Aevra. Searching Bluetooth…";
        _bluetoothAddress = await DiscoverBluetoothAsync();
        if (_bluetoothAddress != null)
        {
            ConnectionText.Text = "Bluetooth • Aevra";
            StatusText.Text = "Aevra found over Bluetooth.";
        }
        else
        {
            ConnectionText.Text = "Not connected";
            StatusText.Text = "Aevra was not found. Keep the iPhone app open on the Live screen and enable Wi-Fi, Bluetooth, Local Network, and Bluetooth permissions.";
        }
    }

    private async Task<IPEndPoint?> DiscoverWifiAsync()
    {
        using var udp = new UdpClient(0) { EnableBroadcast = true };
        byte[] request = Encoding.UTF8.GetBytes("AEVRA_DISCOVER_V1");
        await udp.SendAsync(request, request.Length, new IPEndPoint(IPAddress.Broadcast, DiscoveryPort));
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(3));
        try
        {
            UdpReceiveResult result = await udp.ReceiveAsync(timeout.Token);
            var reply = JsonSerializer.Deserialize<DiscoveryReply>(result.Buffer, JsonOptions);
            return new IPEndPoint(result.RemoteEndPoint.Address, reply?.tcpPort ?? TcpPort);
        }
        catch { return null; }
    }

    private async Task<ulong?> DiscoverBluetoothAsync()
    {
        var tcs = new TaskCompletionSource<ulong?>();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(8));
        var watcher = new BluetoothLEAdvertisementWatcher { ScanningMode = BluetoothLEScanningMode.Active };
        watcher.AdvertisementFilter.Advertisement.ServiceUuids.Add(ServiceUuid);
        watcher.Received += (_, args) => tcs.TrySetResult(args.BluetoothAddress);
        timeout.Token.Register(() => tcs.TrySetResult(null));
        watcher.Start();
        ulong? result = await tcs.Task;
        watcher.Stop();
        return result;
    }

    private async Task SendAsync(string type)
    {
        if (string.IsNullOrWhiteSpace(CodeBox.Text))
        {
            StatusText.Text = "Enter the pairing code shown in Aevra.";
            return;
        }
        if (_wifiEndpoint == null && _bluetoothAddress == null)
            await DiscoverAsync();

        var packet = new Packet(type, CodeBox.Text.Trim(), TitleBox.Text.Trim(), MessageBox.Text.Trim());
        byte[] data = JsonSerializer.SerializeToUtf8Bytes(packet, JsonOptions);

        if (_wifiEndpoint != null && await SendWifiAsync(data))
        {
            StatusText.Text = type == "ping" ? "Wi-Fi connection test passed." : "Notification sent over Wi-Fi.";
            return;
        }
        if (_bluetoothAddress == null)
            _bluetoothAddress = await DiscoverBluetoothAsync();
        if (_bluetoothAddress != null && await SendBluetoothAsync(_bluetoothAddress.Value, data))
        {
            ConnectionText.Text = "Bluetooth • Aevra";
            StatusText.Text = type == "ping" ? "Bluetooth connection test passed." : "Notification sent over Bluetooth.";
            return;
        }
        StatusText.Text = "Could not deliver the message. Open Aevra on the iPhone and verify the pairing code and permissions.";
    }

    private async Task<bool> SendWifiAsync(byte[] data)
    {
        try
        {
            using var client = new TcpClient();
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            await client.ConnectAsync(_wifiEndpoint!.Address, _wifiEndpoint.Port, timeout.Token);
            await client.GetStream().WriteAsync(data, timeout.Token);
            byte[] response = new byte[256];
            int count = await client.GetStream().ReadAsync(response, timeout.Token);
            return Encoding.UTF8.GetString(response, 0, count).StartsWith("OK");
        }
        catch { _wifiEndpoint = null; return false; }
    }

    private static async Task<bool> SendBluetoothAsync(ulong address, byte[] data)
    {
        try
        {
            using BluetoothLEDevice device = await BluetoothLEDevice.FromBluetoothAddressAsync(address);
            if (device == null) return false;
            var services = await device.GetGattServicesForUuidAsync(ServiceUuid, BluetoothCacheMode.Uncached);
            if (services.Status != GattCommunicationStatus.Success || services.Services.Count == 0) return false;
            var chars = await services.Services[0].GetCharacteristicsForUuidAsync(MessageUuid, BluetoothCacheMode.Uncached);
            if (chars.Status != GattCommunicationStatus.Success || chars.Characteristics.Count == 0) return false;
            using var writer = new DataWriter();
            writer.WriteBytes(data);
            var status = await chars.Characteristics[0].WriteValueAsync(writer.DetachBuffer(), GattWriteOption.WriteWithResponse);
            return status == GattCommunicationStatus.Success;
        }
        catch { return false; }
    }

    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    private sealed record Packet(string Type, string PairingCode, string Title, string Message);
    private sealed record DiscoveryReply(string name, string pairingHint, int tcpPort);
}
