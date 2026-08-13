import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_settings.dart';
import 'app_version.dart';
import 'key_catalog.dart';
import 'legal_page.dart';
import 'settings_backup.dart';

const int _pickerCleared = -99998;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  Future<void> _editSlot(BuildContext context, PadSlot slot) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _KeyPickerSheet(
        title: switch (slot) {
          PadSlot.confirm => '決定ボタンのキー',
          PadSlot.cancel => '取消ボタンのキー',
          PadSlot.sub => 'Shift枠のキー',
          PadSlot.custom => 'カスタムボタンのキー',
        },
        allowClear: slot == PadSlot.custom,
        currentId: switch (slot) {
          PadSlot.confirm => settings.confirmId,
          PadSlot.cancel => settings.cancelId,
          PadSlot.sub => settings.subId,
          PadSlot.custom => settings.customId,
        },
      ),
    );

    if (selected == null) {
      return;
    }
    if (selected == _pickerCleared) {
      await settings.setSlot(slot, null);
      return;
    }
    await settings.setSlot(slot, selected);
  }

  String _slotSummary(KeySpec? key, {required String emptyLabel}) {
    if (key == null) {
      return emptyLabel;
    }
    if (key.role == null || key.role!.isEmpty) {
      return key.label;
    }
    return '${key.label}（${key.role}）';
  }

  Future<void> _exportSettings(BuildContext context) async {
    try {
      final json = settings.exportBackupJson();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${SettingsBackup.fileName}');
      await file.writeAsString(json, encoding: utf8);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: SettingsBackup.fileName)],
        subject: 'Padora settings backup',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('書き出しに失敗しました: $error')),
      );
    }
  }

  Future<void> _importSettings(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルを読み込めませんでした')),
      );
      return;
    }

    final raw = utf8.decode(bytes);
    SettingsBackupPayload payload;
    try {
      payload = SettingsBackup.decodeJson(raw);
    } on SettingsBackupException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定を読み込みますか？'),
        content: const Text(
          '現在のキー割り当て・表示設定を上書きします。\n接続用 IP は含まれません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('読み込む'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }

    try {
      await settings.applyBackup(payload);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を読み込みました')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('読み込みに失敗しました: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text('接続', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('起動時に自動接続'),
                      subtitle: const Text('保存した IP があるとき、起動後すぐ接続を試みる'),
                      value: settings.autoConnectOnLaunch,
                      onChanged: settings.setAutoConnectOnLaunch,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('保存した IP を消す'),
                      subtitle: Text(
                        settings.lastHostIp == null
                            ? '保存されている IP はありません'
                            : settings.lastHostIp!,
                      ),
                      trailing: const Icon(Icons.delete_outline_rounded),
                      enabled: settings.lastHostIp != null,
                      onTap: settings.lastHostIp == null
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('保存した IP を消しますか？'),
                                  content: Text(
                                    '${settings.lastHostIp}\n\n端末内の保存と入力欄を空にします。',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('消す'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true || !context.mounted) {
                                return;
                              }
                              await settings.clearLastHostIp();
                              if (context.mounted) {
                                Navigator.pop(context, 'ip_cleared');
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('表示', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('画面を消灯しない'),
                      subtitle: const Text('コントローラー使用中にスリープさせない'),
                      value: settings.keepAwake,
                      onChanged: settings.setKeepAwake,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('短タップの触覚'),
                      subtitle: const Text('十字・決定・取消を短くタップしたときだけ振動（長押し中は鳴らない）'),
                      value: settings.hapticFeedback,
                      onChanged: settings.setHapticFeedback,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('ボタン左右反転'),
                      subtitle: const Text('十字キーは固定のまま、決定・取消などの並びだけ左右を入れ替え'),
                      value: settings.mirrorActionButtons,
                      onChanged: settings.setMirrorActionButtons,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('テーマ'),
                      subtitle: Text(settings.themeLabel),
                      trailing: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_rounded),
                            tooltip: 'システム',
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded),
                            tooltip: 'ライト',
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded),
                            tooltip: 'ダーク',
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (value) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          settings.setThemeMode(value.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('キー割り当て', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'ボタンを連打しても誤って設定が開かないように、ここだけで変更します。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('決定'),
                      subtitle: Text(_slotSummary(settings.confirmKey, emptyLabel: '未設定')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editSlot(context, PadSlot.confirm),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('取消'),
                      subtitle: Text(_slotSummary(settings.cancelKey, emptyLabel: '未設定')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editSlot(context, PadSlot.cancel),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Shift枠'),
                      subtitle: Text(_slotSummary(settings.subKey, emptyLabel: '未設定')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editSlot(context, PadSlot.sub),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('カスタム枠'),
                      subtitle: Text(
                        _slotSummary(settings.customKey, emptyLabel: '未設定（タップで割り当て）'),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editSlot(context, PadSlot.custom),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('バックアップ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '機種変更や再インストール用。接続 IP は含まれません。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('設定を書き出す'),
                      subtitle: const Text('JSON ファイルとして共有'),
                      trailing: const Icon(Icons.upload_rounded),
                      onTap: () => _exportSettings(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('設定を読み込む'),
                      subtitle: const Text('保存した JSON から復元'),
                      trailing: const Icon(Icons.download_rounded),
                      onTap: () => _importSettings(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('情報', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('非公式について'),
                      subtitle: const Text('WOLF RPG 公式・公認ではありません'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalPage(document: LegalDocument.about),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('利用規約'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalPage(document: LegalDocument.terms),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('プライバシーポリシー'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalPage(document: LegalDocument.privacy),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Padora ${AppVersion.label}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KeyPickerSheet extends StatelessWidget {
  const _KeyPickerSheet({
    required this.title,
    required this.currentId,
    required this.allowClear,
  });

  final String title;
  final int? currentId;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in KeyCatalog.assignable)
                      ChoiceChip(
                        label: Text(
                          key.role == null ? key.label : '${key.label}（${key.role}）',
                        ),
                        selected: currentId == key.id,
                        onSelected: (_) => Navigator.pop(context, key.id),
                      ),
                  ],
                ),
              ),
            ),
            if (allowClear) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, _pickerCleared),
                child: const Text('未設定に戻す'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
