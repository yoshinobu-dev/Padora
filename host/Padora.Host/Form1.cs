using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;

namespace Padora.Host;

public partial class Form1 : Form
{
    private readonly UdpPadServer _server = new();
    private readonly TextBox _log = new();
    private readonly Label _status = new();

    public Form1()
    {
        InitializeComponent();
        var version = typeof(Form1).Assembly.GetName().Version;
        var versionLabel = version == null ? "1.0.0" : $"{version.Major}.{version.Minor}.{version.Build}";
        Text = $"Padora Host v{versionLabel}";
        Width = 520;
        Height = 360;
        StartPosition = FormStartPosition.CenterScreen;

        _status.Dock = DockStyle.Top;
        _status.Height = 36;
        _status.TextAlign = ContentAlignment.MiddleLeft;
        _status.Padding = new Padding(12, 0, 12, 0);
        _status.Text = "Starting...";

        var ipBox = new TextBox
        {
            Dock = DockStyle.Top,
            Height = 72,
            Multiline = true,
            ReadOnly = true,
            BorderStyle = BorderStyle.None,
            Font = new Font(FontFamily.GenericMonospace, 9f),
            Text = BuildIpHelpText(),
        };

        var buttons = new FlowLayoutPanel
        {
            Dock = DockStyle.Top,
            Height = 40,
            Padding = new Padding(8, 4, 8, 4),
        };

        var testButton = new Button { Text = "Self-test Z (into focused window)", AutoSize = true };
        testButton.Click += (_, _) =>
        {
            AppendLog("Self-test: focus Notepad within 2 seconds...");
            Task.Run(() =>
            {
                Thread.Sleep(2000);
                var ok = InputInjector.SelfTestZ(out var error);
                BeginInvoke(() => AppendLog(ok ? "Self-test Z: OK" : $"Self-test Z: FAIL {error}"));
            });
        };
        buttons.Controls.Add(testButton);

        _log.Dock = DockStyle.Fill;
        _log.Multiline = true;
        _log.ReadOnly = true;
        _log.ScrollBars = ScrollBars.Vertical;
        _log.Font = new Font(FontFamily.GenericMonospace, 9f);

        var hint = new Label
        {
            Dock = DockStyle.Bottom,
            Height = 40,
            TextAlign = ContentAlignment.MiddleLeft,
            Padding = new Padding(12, 0, 12, 0),
            Text = "Client needs THIS PC's tether IP (not 192.168.42.129). Allow firewall if asked.",
        };

        Controls.Add(_log);
        Controls.Add(hint);
        Controls.Add(buttons);
        Controls.Add(ipBox);
        Controls.Add(_status);

        _server.StatusChanged += msg => BeginInvoke(() => _status.Text = msg);
        _server.PacketReceived += msg => BeginInvoke(() => AppendLog(msg));

        Shown += (_, _) =>
        {
            _server.Start();
            AppendLog("Waiting for UDP packets...");
            AppendLog("If nothing appears when you tap Confirm, IP/firewall is wrong.");
        };
        FormClosed += (_, _) => _server.Dispose();
    }

    private void AppendLog(string msg)
    {
        _log.AppendText($"[{DateTime.Now:HH:mm:ss}] {msg}{Environment.NewLine}");
    }

    private static string BuildIpHelpText()
    {
        var ips = GetLikelyHostIps().ToList();
        if (ips.Count == 0)
        {
            return "No IPv4 found. Enable USB tethering, then restart Host.";
        }

        return "Enter one of these IPs in Padora client:" + Environment.NewLine +
               string.Join(Environment.NewLine, ips.Select(ip => $"  → {ip}"));
    }

    private static IEnumerable<string> GetLikelyHostIps()
    {
        foreach (var nic in NetworkInterface.GetAllNetworkInterfaces())
        {
            if (nic.OperationalStatus != OperationalStatus.Up)
            {
                continue;
            }

            if (nic.NetworkInterfaceType is NetworkInterfaceType.Loopback)
            {
                continue;
            }

            var props = nic.GetIPProperties();
            foreach (var addr in props.UnicastAddresses)
            {
                if (addr.Address.AddressFamily != AddressFamily.InterNetwork)
                {
                    continue;
                }

                var ip = addr.Address.ToString();
                if (IPAddress.IsLoopback(addr.Address))
                {
                    continue;
                }

                yield return $"{ip}  ({nic.Name})";
            }
        }
    }
}
