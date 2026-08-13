import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'app_version.dart';
import 'key_catalog.dart';
import 'legal_page.dart';

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
