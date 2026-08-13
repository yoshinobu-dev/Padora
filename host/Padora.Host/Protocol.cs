namespace Padora.Host;

internal static class Protocol
{
    public const byte Magic = (byte)'W';
    public const byte Version = 1;
    public const int PacketSize = 6;
    public const int DefaultPort = 21780;

    public const byte ButtonUp = 1;
    public const byte ButtonDown = 2;
    public const byte ButtonLeft = 3;
    public const byte ButtonRight = 4;
    public const byte ButtonZ = 10;
    public const byte ButtonX = 11;
    public const byte ButtonShift = 12;
    public const byte ButtonEnter = 13;
    public const byte ButtonSpace = 14;
    public const byte ButtonEsc = 15;
    public const byte ButtonC = 16;
    public const byte ButtonA = 17;
    public const byte ButtonS = 18;
    public const byte ButtonF4 = 20;
    public const byte ButtonF11 = 21;
    public const byte ButtonF5 = 22;
    public const byte ButtonF8 = 23;
    public const byte ButtonF12 = 24;

    // Back-compat aliases used by older UI names.
    public const byte ButtonConfirm = ButtonZ;
    public const byte ButtonCancel = ButtonX;
    public const byte ButtonSub = ButtonShift;

    public static bool TryParse(ReadOnlySpan<byte> data, out byte buttonId, out bool pressed, out ushort sequence)
    {
        buttonId = 0;
        pressed = false;
        sequence = 0;

        if (data.Length < PacketSize)
        {
            return false;
        }

        if (data[0] != Magic || data[1] != Version)
        {
            return false;
        }

        buttonId = data[2];
        pressed = data[3] == 1;
        sequence = (ushort)(data[4] | (data[5] << 8));
        return true;
    }
}
