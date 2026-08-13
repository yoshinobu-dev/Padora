import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padora_client/app_settings.dart';
import 'package:padora_client/settings_backup.dart';

void main() {
  group('SettingsBackup', () {
    test('roundtrip preserves settings except IP', () {
      final settings = AppSettings()
        ..themeMode = ThemeMode.dark
        ..keepAwake = false
        ..hapticFeedback = false
        ..mirrorActionButtons = true
        ..autoConnectOnLaunch = true
        ..confirmId = 13
        ..cancelId = 15
        ..subId = 12
        ..customId = 22
        ..lastHostIp = '192.168.0.10';

      final json = SettingsBackup.encodeJson(settings);
      final payload = SettingsBackup.decodeJson(json);

      expect(payload.themeMode, ThemeMode.dark);
      expect(payload.keepAwake, false);
      expect(payload.hapticFeedback, false);
      expect(payload.mirrorActionButtons, true);
      expect(payload.autoConnectOnLaunch, true);
      expect(payload.confirmId, 13);
      expect(payload.cancelId, 15);
      expect(payload.subId, 12);
      expect(payload.customId, 22);
      expect(json.contains('192.168.0.10'), isFalse);
    });

    test('rejects unknown schema version', () {
      expect(
        () => SettingsBackup.decode({
          'schemaVersion': 99,
          'app': 'padora',
          'settings': {},
        }),
        throwsA(isA<SettingsBackupException>()),
      );
    });

    test('rejects invalid key id', () {
      expect(
        () => SettingsBackup.decode({
          'schemaVersion': 1,
          'app': 'padora',
          'settings': {
            'themeMode': 'system',
            'keepAwake': true,
            'hapticFeedback': true,
            'mirrorActionButtons': false,
            'autoConnectOnLaunch': false,
            'slots': {
              'confirm': 10,
              'cancel': 11,
              'sub': 12,
              'custom': 999,
            },
          },
        }),
        throwsA(
          predicate<SettingsBackupException>(
            (error) => error.message.contains('未対応のキー ID'),
          ),
        ),
      );
    });
  });
}
