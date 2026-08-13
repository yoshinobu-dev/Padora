import 'dart:convert';

import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'key_catalog.dart';

/// Local JSON backup format for the free single-configuration export/import.
abstract final class SettingsBackup {
  static const schemaVersion = 1;
  static const appId = 'padora';
  static const fileName = 'padora-backup-v1.json';

  static Map<String, dynamic> encode(AppSettings settings) {
    return {
      'schemaVersion': schemaVersion,
      'app': appId,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': {
        'themeMode': _themeModeToString(settings.themeMode),
        'keepAwake': settings.keepAwake,
        'hapticFeedback': settings.hapticFeedback,
        'mirrorActionButtons': settings.mirrorActionButtons,
        'autoConnectOnLaunch': settings.autoConnectOnLaunch,
        'slots': {
          'confirm': settings.confirmId,
          'cancel': settings.cancelId,
          'sub': settings.subId,
          'custom': settings.customId,
        },
      },
    };
  }

  static String encodeJson(AppSettings settings) {
    return const JsonEncoder.withIndent('  ').convert(encode(settings));
  }

  static SettingsBackupPayload decodeJson(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const SettingsBackupException('JSON の形式が正しくありません');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const SettingsBackupException('バックアップファイルの形式が正しくありません');
    }
    return decode(decoded);
  }

  static SettingsBackupPayload decode(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || version != schemaVersion) {
      throw SettingsBackupException(
        '未対応のバックアップ形式です（schemaVersion: $version）',
      );
    }

    final app = json['app'];
    if (app is! String || app != appId) {
      throw const SettingsBackupException('Padora 用のバックアップファイルではありません');
    }

    final settings = json['settings'];
    if (settings is! Map<String, dynamic>) {
      throw const SettingsBackupException('settings が見つかりません');
    }

    final themeMode = _themeModeFromString(settings['themeMode'] as String?);
    final keepAwake = _requireBool(settings, 'keepAwake');
    final hapticFeedback = _requireBool(settings, 'hapticFeedback');
    final mirrorActionButtons = _requireBool(settings, 'mirrorActionButtons');
    final autoConnectOnLaunch = _requireBool(settings, 'autoConnectOnLaunch');

    final slots = settings['slots'];
    if (slots is! Map<String, dynamic>) {
      throw const SettingsBackupException('キー割り当て（slots）が見つかりません');
    }

    final confirmId = _requireSlotKey(slots, 'confirm', allowNull: false);
    final cancelId = _requireSlotKey(slots, 'cancel', allowNull: false);
    final subId = _requireSlotKey(slots, 'sub', allowNull: false);
    final customId = _requireSlotKey(slots, 'custom', allowNull: true);

    return SettingsBackupPayload(
      themeMode: themeMode,
      keepAwake: keepAwake,
      hapticFeedback: hapticFeedback,
      mirrorActionButtons: mirrorActionButtons,
      autoConnectOnLaunch: autoConnectOnLaunch,
      confirmId: confirmId!,
      cancelId: cancelId!,
      subId: subId!,
      customId: customId,
    );
  }

  static bool _requireBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw SettingsBackupException('$key が正しくありません');
    }
    return value;
  }

  static int? _requireSlotKey(
    Map<String, dynamic> slots,
    String key, {
    required bool allowNull,
  }) {
    if (!slots.containsKey(key)) {
      throw SettingsBackupException('キー割り当て $key が見つかりません');
    }
    final value = slots[key];
    if (value == null) {
      if (allowNull) {
        return null;
      }
      throw SettingsBackupException('$key は必須です');
    }
    if (value is! int) {
      throw SettingsBackupException('$key が正しくありません');
    }
    if (KeyCatalog.byId(value) == null) {
      throw SettingsBackupException('未対応のキー ID です: $value');
    }
    return value;
  }

  static String _themeModeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode _themeModeFromString(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => throw SettingsBackupException('themeMode が正しくありません: $raw'),
      };
}

class SettingsBackupPayload {
  const SettingsBackupPayload({
    required this.themeMode,
    required this.keepAwake,
    required this.hapticFeedback,
    required this.mirrorActionButtons,
    required this.autoConnectOnLaunch,
    required this.confirmId,
    required this.cancelId,
    required this.subId,
    this.customId,
  });

  final ThemeMode themeMode;
  final bool keepAwake;
  final bool hapticFeedback;
  final bool mirrorActionButtons;
  final bool autoConnectOnLaunch;
  final int confirmId;
  final int cancelId;
  final int subId;
  final int? customId;
}

class SettingsBackupException implements Exception {
  const SettingsBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
