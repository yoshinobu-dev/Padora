using System.ComponentModel;
using System.Runtime.InteropServices;

namespace Padora.Host;

internal static class InputInjector
{
    private const uint InputKeyboard = 1;
    private const uint KeyEventFKeyUp = 0x0002;
    private const uint KeyEventFExtendedKey = 0x0001;
    private const uint KeyEventFScancode = 0x0008;
    private const uint MapVkToVsc = 0;

    public static bool SetKey(byte buttonId, bool pressed, out string error)
    {
        error = string.Empty;
        if (!TryMap(buttonId, out var vk, out var extended))
        {
            error = $"unknown button {buttonId}";
            return false;
        }

        var scan = (ushort)MapVirtualKey(vk, MapVkToVsc);
        var flags = KeyEventFScancode | (pressed ? 0u : KeyEventFKeyUp);
        if (extended)
        {
            flags |= KeyEventFExtendedKey;
        }

        var input = new Input
        {
            type = InputKeyboard,
            U = new InputUnion
            {
                ki = new KeybdInput
                {
                    wVk = 0,
                    wScan = scan,
                    dwFlags = flags,
                    time = 0,
                    dwExtraInfo = nint.Zero,
                },
            },
        };

        var sent = SendInput(1, [input], Marshal.SizeOf<Input>());
        if (sent != 1)
        {
            error = $"SendInput failed (size={Marshal.SizeOf<Input>()}, err={new Win32Exception(Marshal.GetLastWin32Error()).Message})";
            return false;
        }

        return true;
    }

    /// <summary>Host単体で注入できるか確認する。</summary>
    public static bool SelfTestZ(out string error)
    {
        if (!SetKey(Protocol.ButtonConfirm, true, out error))
        {
            return false;
        }

        Thread.Sleep(30);
        return SetKey(Protocol.ButtonConfirm, false, out error);
    }

    private static bool TryMap(byte buttonId, out ushort vk, out bool extended)
    {
        extended = false;
        vk = buttonId switch
        {
            Protocol.ButtonUp => 0x26,
            Protocol.ButtonDown => 0x28,
            Protocol.ButtonLeft => 0x25,
            Protocol.ButtonRight => 0x27,
            Protocol.ButtonZ => 0x5A,
            Protocol.ButtonX => 0x58,
            Protocol.ButtonShift => 0x10,
            Protocol.ButtonEnter => 0x0D,
            Protocol.ButtonSpace => 0x20,
            Protocol.ButtonEsc => 0x1B,
            Protocol.ButtonC => 0x43,
            Protocol.ButtonA => 0x41,
            Protocol.ButtonS => 0x53,
            Protocol.ButtonF4 => 0x73,
            Protocol.ButtonF5 => 0x74,
            Protocol.ButtonF8 => 0x77,
            Protocol.ButtonF11 => 0x7A,
            Protocol.ButtonF12 => 0x7B,
            _ => (ushort)0,
        };

        extended = buttonId is Protocol.ButtonUp or Protocol.ButtonDown or Protocol.ButtonLeft or Protocol.ButtonRight;
        return vk != 0;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint nInputs, Input[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    private static extern uint MapVirtualKey(uint uCode, uint uMapType);

    [StructLayout(LayoutKind.Sequential)]
    private struct Input
    {
        public uint type;
        public InputUnion U;
    }

    // Union must be sized like the native INPUT union (MOUSEINPUT is largest).
    [StructLayout(LayoutKind.Explicit)]
    private struct InputUnion
    {
        [FieldOffset(0)]
        public MouseInput mi;

        [FieldOffset(0)]
        public KeybdInput ki;

        [FieldOffset(0)]
        public HardwareInput hi;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MouseInput
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public nint dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct KeybdInput
    {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public nint dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct HardwareInput
    {
        public uint uMsg;
        public ushort wParamL;
        public ushort wParamH;
    }
}
