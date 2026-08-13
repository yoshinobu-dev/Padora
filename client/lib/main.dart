import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_settings.dart';
import 'pad_client.dart';
import 'pad_haptics.dart';
import 'protocol.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final settings = AppSettings();
  await settings.load();
  runApp(PadoraApp(settings: settings));
}

class PadoraApp extends StatelessWidget {
  const PadoraApp({super.key, required this.settings});

  final AppSettings settings;

  static const _seed = Color(0xFF1F6B4A);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Padora',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seed,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seed,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: PadPage(settings: settings),
        );
      },
    );
  }
}

class PadPage extends StatefulWidget {
  const PadPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<PadPage> createState() => _PadPageState();
}

class _PadPageState extends State<PadPage> {
  final _ipController = TextEditingController();
  final _client = PadClient();
  String _status = 'Host に表示された PC の IP を入れて接続';
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _applySavedHostIp();
    if (widget.settings.autoConnectOnLaunch && widget.settings.lastHostIp != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
    }
  }

  void _applySavedHostIp() {
    final saved = widget.settings.lastHostIp;
    if (saved == null || saved.isEmpty) {
      return;
    }
    _ipController.text = saved;
    _status = '前回の IP を表示中。接続を押してください';
  }

  @override
  void dispose() {
    _ipController.dispose();
    _client.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() {
        _connected = false;
        _status = 'IP を入力してください';
      });
      return;
    }

    try {
      await _client.connect(ip);
      await widget.settings.saveLastHostIp(ip);
      setState(() {
        _connected = true;
        _status = '接続中 → $ip:${PadoraProtocol.defaultPort}';
      });
    } catch (e) {
      setState(() {
        _connected = false;
        _status = '接続失敗: $e';
      });
    }
  }

  void _bind(int? buttonId, bool pressed) {
    if (buttonId == null) {
      if (pressed) {
        setState(() => _status = 'カスタム未設定。右上の歯車から割り当て');
      }
      return;
    }
    if (!_client.isReady) {
      if (pressed) {
        setState(() => _status = '先に接続してください');
      }
      return;
    }
    _client.send(buttonId, pressed);
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(settings: widget.settings),
      ),
    );
    if (!mounted) {
      return;
    }
    if (result == 'ip_cleared') {
      _ipController.clear();
      setState(() {
        _connected = false;
        _status = 'Host に表示された PC の IP を入れて接続';
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: PadLayout.maxContentWidth,
                  maxHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    children: [
                      _TopBar(
                        onBind: _bind,
                        onOpenSettings: _openSettings,
                      ),
                      const SizedBox(height: 12),
                      _ConnectionCard(
                        ipController: _ipController,
                        status: _status,
                        connected: _connected,
                        onConnect: _connect,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _Dpad(
                                settings: widget.settings,
                                onBind: _bind,
                              ),
                            ),
                            const SizedBox(height: PadLayout.padZonesGap),
                            Expanded(
                              flex: 4,
                              child: _ActionCluster(
                                settings: widget.settings,
                                onBind: _bind,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBind,
    required this.onOpenSettings,
  });

  final void Function(int? buttonId, bool pressed) onBind;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          'Padora',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const Spacer(),
        _ChipKey(
          label: 'F4',
          tooltip: 'F4（画面サイズ）',
          onBind: (pressed) => onBind(PadoraProtocol.buttonF4, pressed),
        ),
        const SizedBox(width: 4),
        _ChipKey(
          label: 'F11',
          tooltip: 'F11（最大化）',
          onBind: (pressed) => onBind(PadoraProtocol.buttonF11, pressed),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: '設定',
          onPressed: onOpenSettings,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.onSurfaceVariant,
          ),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _ChipKey extends StatefulWidget {
  const _ChipKey({
    required this.label,
    required this.tooltip,
    required this.onBind,
  });

  final String label;
  final String tooltip;
  final ValueChanged<bool> onBind;

  @override
  State<_ChipKey> createState() => _ChipKeyState();
}

class _ChipKeyState extends State<_ChipKey> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
    widget.onBind(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.tooltip,
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.ipController,
    required this.status,
    required this.connected,
    required this.onConnect,
  });

  final TextEditingController ipController;
  final String status;
  final bool connected;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ipController,
                  decoration: InputDecoration(
                    labelText: 'PC の IP',
                    hintText: '例: 192.168.x.x',
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onConnect(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onConnect,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(96, 48),
                  backgroundColor: _monoFill(context),
                  foregroundColor: _monoOnFill(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(connected ? '再接続' : '接続'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                connected ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 16,
                color: connected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _monoFill(BuildContext context) {
  final light = Theme.of(context).brightness == Brightness.light;
  return light ? const Color(0xFF1C1C1C) : const Color(0xFFF2F2F2);
}

Color _monoOnFill(BuildContext context) {
  final light = Theme.of(context).brightness == Brightness.light;
  return light ? const Color(0xFFF5F5F5) : const Color(0xFF151515);
}

class _Dpad extends StatelessWidget {
  const _Dpad({
    required this.settings,
    required this.onBind,
  });

  final AppSettings settings;
  final void Function(int? buttonId, bool pressed) onBind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _monoFill(context);
    final fg = _monoOnFill(context);

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        Widget arm(
          String label,
          int id, {
          double? visualWidthFactor,
          double? visualHeightFactor,
        }) {
          return _PadButton(
            title: label,
            color: color,
            foreground: fg,
            haptic: PadHaptic.dpad,
            hapticEnabled: settings.hapticFeedback,
            stepTap: true,
            visualWidthFactor: visualWidthFactor,
            visualHeightFactor: visualHeightFactor,
            onBind: (pressed) => onBind(id, pressed),
          );
        }

        return Container(
          padding: const EdgeInsets.all(PadLayout.panelPadding),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Expanded(
                child: arm(
                  '↑',
                  PadoraProtocol.buttonUp,
                  visualWidthFactor: PadLayout.dpadVisualArmWidthFactor,
                ),
              ),
              const SizedBox(height: PadLayout.dpadBandGap),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: arm(
                        '←',
                        PadoraProtocol.buttonLeft,
                        visualWidthFactor: PadLayout.dpadVisualSideWidthFactor,
                      ),
                    ),
                    Expanded(
                      child: arm(
                        '→',
                        PadoraProtocol.buttonRight,
                        visualWidthFactor: PadLayout.dpadVisualSideWidthFactor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PadLayout.dpadBandGap),
              Expanded(
                child: arm(
                  '↓',
                  PadoraProtocol.buttonDown,
                  visualWidthFactor: PadLayout.dpadVisualArmWidthFactor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.settings,
    required this.onBind,
  });

  final AppSettings settings;
  final void Function(int? buttonId, bool pressed) onBind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final confirm = settings.confirmKey;
        final cancel = settings.cancelKey;
        final sub = settings.subKey;
        final custom = settings.customKey;
        final mirror = settings.mirrorActionButtons;

        Widget cancelBtn() => Expanded(
              child: _PadButton(
                title: cancel.label,
                subtitle: cancel.role ?? '取消',
                color: scheme.errorContainer,
                foreground: scheme.onErrorContainer,
                haptic: PadHaptic.cancel,
                hapticEnabled: settings.hapticFeedback,
                onBind: (pressed) => onBind(cancel.id, pressed),
              ),
            );

        Widget confirmBtn() => Expanded(
              child: _PadButton(
                title: confirm.label,
                subtitle: confirm.role ?? '決定',
                color: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
                haptic: PadHaptic.confirm,
                hapticEnabled: settings.hapticFeedback,
                onBind: (pressed) => onBind(confirm.id, pressed),
              ),
            );

        Widget customBtn() => Expanded(
              child: _PadButton(
                title: custom?.label ?? 'Custom',
                subtitle: custom?.role,
                color: scheme.surfaceContainerHighest,
                foreground: scheme.onSurfaceVariant,
                dashed: custom == null,
                haptic: custom != null ? PadHaptic.custom : PadHaptic.none,
                hapticEnabled: settings.hapticFeedback,
                onBind: (pressed) => onBind(custom?.id, pressed),
              ),
            );

        Widget subBtn() => Expanded(
              child: _PadButton(
                title: sub.label,
                subtitle: sub.role,
                color: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
                haptic: PadHaptic.shift,
                hapticEnabled: settings.hapticFeedback,
                onBind: (pressed) => onBind(sub.id, pressed),
              ),
            );

        return Container(
          padding: const EdgeInsets.all(PadLayout.panelPadding),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: mirror
                      ? [confirmBtn(), const SizedBox(width: PadLayout.actionGap), cancelBtn()]
                      : [cancelBtn(), const SizedBox(width: PadLayout.actionGap), confirmBtn()],
                ),
              ),
              const SizedBox(height: PadLayout.rowGap),
              Expanded(
                child: Row(
                  children: mirror
                      ? [subBtn(), const SizedBox(width: PadLayout.actionGap), customBtn()]
                      : [customBtn(), const SizedBox(width: PadLayout.actionGap), subBtn()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PadButton extends StatefulWidget {
  const _PadButton({
    required this.title,
    required this.color,
    required this.foreground,
    required this.onBind,
    this.subtitle,
    this.dashed = false,
    this.haptic = PadHaptic.none,
    this.hapticEnabled = false,
    this.stepTap = false,
    this.visualWidthFactor,
    this.visualHeightFactor,
  });

  final String title;
  final String? subtitle;
  final Color color;
  final Color foreground;
  final ValueChanged<bool> onBind;
  final bool dashed;
  final PadHaptic haptic;
  final bool hapticEnabled;
  final bool stepTap;
  final double? visualWidthFactor;
  final double? visualHeightFactor;

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  bool _pressed = false;
  DateTime? _downAt;
  bool _walking = false;
  bool _pulseActive = false;
  Timer? _longPressTimer;
  Timer? _pulseReleaseTimer;

  @override
  void dispose() {
    _cancelStepTimers(releaseKey: true);
    super.dispose();
  }

  void _cancelStepTimers({required bool releaseKey}) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _pulseReleaseTimer?.cancel();
    _pulseReleaseTimer = null;
    if (releaseKey) {
      if (_walking || _pulseActive) {
        widget.onBind(false);
      }
      _walking = false;
      _pulseActive = false;
    }
  }

  void _finishStepPulse() {
    if (!_pulseActive) {
      return;
    }
    widget.onBind(false);
    _pulseActive = false;
  }

  void _onStepDown() {
    _cancelStepTimers(releaseKey: true);
    _downAt = DateTime.now();
    setState(() => _pressed = true);
    _longPressTimer = Timer(PadStepPolicy.holdThreshold, () {
      if (!_pressed) {
        return;
      }
      _walking = true;
      widget.onBind(true);
    });
  }

  void _onStepUp() {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    final downAt = _downAt;
    _downAt = null;

    if (_walking) {
      widget.onBind(false);
      _walking = false;
    } else {
      if (downAt != null &&
          widget.hapticEnabled &&
          widget.haptic != PadHaptic.none) {
        triggerPadHaptic(widget.haptic, enabled: true);
      }
      widget.onBind(true);
      _pulseActive = true;
      _pulseReleaseTimer = Timer(PadStepPolicy.pulseDuration, () {
        if (!mounted) {
          return;
        }
        _finishStepPulse();
      });
    }

    setState(() => _pressed = false);
  }

  void _setPressed(bool value) {
    if (widget.stepTap) {
      if (value) {
        if (!_pressed) {
          _onStepDown();
        }
      } else if (_pressed) {
        _onStepUp();
      }
      return;
    }

    if (_pressed == value) {
      return;
    }

    if (value) {
      _downAt = DateTime.now();
    } else {
      final downAt = _downAt;
      _downAt = null;
      if (downAt != null &&
          widget.hapticEnabled &&
          widget.haptic != PadHaptic.none &&
          DateTime.now().difference(downAt) < PadHapticPolicy.shortTapMax) {
        triggerPadHaptic(widget.haptic, enabled: true);
      }
    }

    setState(() => _pressed = value);
    widget.onBind(value);
  }

  @override
  Widget build(BuildContext context) {
    final visual = AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 80),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pressed
              ? Color.lerp(widget.color, Colors.black, 0.12)
              : widget.color,
          borderRadius: BorderRadius.circular(22),
          border: widget.dashed
              ? Border.all(
                  color: widget.foreground.withValues(alpha: 0.35),
                  width: 1.5,
                )
              : null,
          boxShadow: _pressed || widget.dashed
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.title.isNotEmpty)
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: widget.foreground.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final hasReducedVisual =
        widget.visualWidthFactor != null || widget.visualHeightFactor != null;
    final body = hasReducedVisual
        ? Center(
            child: FractionallySizedBox(
              widthFactor: widget.visualWidthFactor ?? 1,
              heightFactor: widget.visualHeightFactor ?? 1,
              child: visual,
            ),
          )
        : visual;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: body,
    );
  }
}
