import '../generated/pubspec.g.dart';

abstract final class Constants {
  static const displayName = 'Kraft Launcher';
  static const website =
      'https://github.com/EchoEllet/kraft-launcher/blob/main/README.md';
  static const contactEmail = 'kraftlauncher@gmail.com';

  static const githubRepoLink = Pubspec.repository;
  // TODO: Once a bug template is created, make this link more specific
  static const reportBugLink = '$githubRepoLink/issues/new';
  static const askQuestionLink = '$githubRepoLink/discussions/new?category=q-a';
  static const appDisplayVersion =
      'v${Pubspec.version} (${Pubspec.versionBuildNumber})';
  static const licenseDisplayName = 'MIT';
}
