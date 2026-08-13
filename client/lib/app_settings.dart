import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'key_catalog.dart';
import 'settings_backup.dart';

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _keepAwakeKey = 'keep_awake';
  static const _confirmKey = 'slot_confirm';
  static const _cancelKey = 'slot_cancel';
  static const _subKey = 'slot_sub';
  static const _customKey = 'slot_custom';
  static const _hapticKey = 'haptic_feedback';
  static const _lastHostIpKey = 'last_host_ip';
  static const _autoConnectKey = 'auto_connect_on_launch';
  static const _mirrorActionsKey = 'mirror_action_buttons';

  ThemeMode themeMode = ThemeMode.system;
  bool keepAwake = true;
  bool hapticFeedback = true;
  bool mirrorActionButtons = false;
  String? lastHostIp;
  bool autoConnectOnLaunch = false;

  int confirmId = KeyCatalog.z.id;
  int cancelId = KeyCatalog.x.id;
  int subId = KeyCatalog.shift.id;
  int? customId;

  KeySpec get confirmKey => KeyCatalog.byId(confirmId) ?? KeyCatalog.z;
  KeySpec get cancelKey => KeyCatalog.byId(cancelId) ?? KeyCatalog.x;
  KeySpec get subKey => KeyCatalog.byId(subId) ?? KeyCatalog.shift;
  KeySpec? get customKey => KeyCatalog.byId(customId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      themeMode = ThemeMode.values[themeIndex];
    }
    keepAwake = prefs.getBool(_keepAwakeKey) ?? true;
    hapticFeedback = prefs.getBool(_hapticKey) ?? true;
    lastHostIp = prefs.getString(_lastHostIpKey);
    autoConnectOnLaunch = prefs.getBool(_autoConnectKey) ?? false;
    mirrorActionButtons = prefs.getBool(_mirrorActionsKey) ?? false;
    confirmId = prefs.getInt(_confirmKey) ?? KeyCatalog.z.id;
    cancelId = prefs.getInt(_cancelKey) ?? KeyCatalog.x.id;
    subId = prefs.getInt(_subKey) ?? KeyCatalog.shift.id;
    customId = prefs.getInt(_customKey);

    await _applyKeepAwake();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> cycleThemeMode() async {
    final next = switch (themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }

  Future<void> setKeepAwake(bool value) async {
    keepAwake = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepAwakeKey, value);
    await _applyKeepAwake();
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    hapticFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticKey, value);
    notifyListeners();
  }

  /// Saves [ip] only after a successful connection (local device storage).
  Future<void> saveLastHostIp(String ip) async {
    final trimmed = ip.trim();
    if (trimmed.isEmpty) {
      return;
    }
    lastHostIp = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastHostIpKey, trimmed);
    notifyListeners();
  }

  Future<void> clearLastHostIp() async {
    lastHostIp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastHostIpKey);
    notifyListeners();
  }

  Future<void> setAutoConnectOnLaunch(bool value) async {
    autoConnectOnLaunch = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoConnectKey, value);
    notifyListeners();
  }

  Future<void> setMirrorActionButtons(bool value) async {
    mirrorActionButtons = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mirrorActionsKey, value);
    notifyListeners();
  }

  Map<String, dynamic> exportBackup() => SettingsBackup.encode(this);

  String exportBackupJson() => SettingsBackup.encodeJson(this);

  Future<void> importBackupJson(String raw) async {
    await applyBackup(SettingsBackup.decodeJson(raw));
  }

  Future<void> applyBackup(SettingsBackupPayload payload) async {
    final prefs = await SharedPreferences.getInstance();

    themeMode = payload.themeMode;
    keepAwake = payload.keepAwake;
    hapticFeedback = payload.hapticFeedback;
    mirrorActionButtons = payload.mirrorActionButtons;
    autoConnectOnLaunch = payload.autoConnectOnLaunch;
    confirmId = payload.confirmId;
    cancelId = payload.cancelId;
    subId = payload.subId;
    customId = payload.customId;

    await prefs.setInt(_themeKey, themeMode.index);
    await prefs.setBool(_keepAwakeKey, keepAwake);
    await prefs.setBool(_hapticKey, hapticFeedback);
    await prefs.setBool(_mirrorActionsKey, mirrorActionButtons);
    await prefs.setBool(_autoConnectKey, autoConnectOnLaunch);
    await prefs.setInt(_confirmKey, confirmId);
    await prefs.setInt(_cancelKey, cancelId);
    await prefs.setInt(_subKey, subId);
    if (customId == null) {
      await prefs.remove(_customKey);
    } else {
      await prefs.setInt(_customKey, customId!);
    }

    await _applyKeepAwake();
    notifyListeners();
  }

  Future<void> setSlot(PadSlot slot, int? keyId) async {
    final prefs = await SharedPreferences.getInstance();
    switch (slot) {
      case PadSlot.confirm:
        confirmId = keyId ?? KeyCatalog.z.id;
        await prefs.setInt(_confirmKey, confirmId);
      case PadSlot.cancel:
        cancelId = keyId ?? KeyCatalog.x.id;
        await prefs.setInt(_cancelKey, cancelId);
      case PadSlot.sub:
        subId = keyId ?? KeyCatalog.shift.id;
        await prefs.setInt(_subKey, subId);
      case PadSlot.custom:
        customId = keyId;
        if (keyId == null) {
          await prefs.remove(_customKey);
        } else {
          await prefs.setInt(_customKey, keyId);
        }
    }
    notifyListeners();
  }

  Future<void> _applyKeepAwake() async {
    if (keepAwake) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  String get themeLabel => switch (themeMode) {
        ThemeMode.system => 'システム',
        ThemeMode.light => 'ライト',
        ThemeMode.dark => 'ダーク',
      };
}

enum PadSlot { confirm, cancel, sub, custom }
