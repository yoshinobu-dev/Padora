/// Keep in sync with pubspec.yaml `version: x.y.z+build`.
abstract final class AppVersion {
  static const name = '1.0.0';
  static const build = '2';

  static String get label => '$name ($build)';
}
