using System.Net.Sockets;

namespace Padora.Host;

internal sealed class UdpPadServer : IDisposable
{
    private readonly UdpClient _udp;
    private CancellationTokenSource? _cts;
    private Task? _loop;

    public event Action<string>? StatusChanged;
    public event Action<string>? PacketReceived;

    public UdpPadServer(int port = Protocol.DefaultPort)
    {
        _udp = new UdpClient(port);
    }

    public void Start()
    {
        if (_loop != null)
        {
            return;
        }

        _cts = new CancellationTokenSource();
        _loop = Task.Run(() => ReceiveLoopAsync(_cts.Token));
        StatusChanged?.Invoke($"Listening UDP :{Protocol.DefaultPort}");
    }

    public void Dispose()
    {
        _cts?.Cancel();
        try
        {
            _loop?.Wait(500);
        }
        catch
        {
            // ignore shutdown races
        }

        _udp.Dispose();
        _cts?.Dispose();
    }

    private async Task ReceiveLoopAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested)
        {
            try
            {
                var result = await _udp.ReceiveAsync(token);
                if (!Protocol.TryParse(result.Buffer, out var buttonId, out var pressed, out var sequence))
                {
                    PacketReceived?.Invoke($"bad packet from {result.RemoteEndPoint} ({result.Buffer.Length} bytes)");
                    continue;
                }

                if (!InputInjector.SetKey(buttonId, pressed, out var error))
                {
                    PacketReceived?.Invoke($"inject fail btn={buttonId}: {error}");
                    continue;
                }

                PacketReceived?.Invoke(
                    $"{result.RemoteEndPoint} btn={buttonId} {(pressed ? "down" : "up")} seq={sequence}");
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                StatusChanged?.Invoke($"Receive error: {ex.Message}");
            }
        }
    }
}
