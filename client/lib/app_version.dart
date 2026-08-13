/// Keep [name] in sync with pubspec.yaml `version` (the part before `+`).
/// The `+build` suffix is for Android versionCode only — not shown in the UI.
abstract final class AppVersion {
  static const name = '1.0.0';

  static String get label => 'v$name';
}
