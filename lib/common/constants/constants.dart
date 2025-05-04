import '../generated/pubspec.g.dart';
import 'project_info_constants.dart';

abstract final class Constants {
  // TODO: Once a bug template is created, make this link more specific
  static const reportBugLink =
      '${ProjectInfoConstants.githubRepoLink}/issues/new';
  static const askQuestionLink =
      '${ProjectInfoConstants.githubRepoLink}/discussions/new?category=q-a';
  static const appDisplayVersion =
      'v${Pubspec.version} (${Pubspec.versionBuildNumber})';
  static const licenseDisplayName = 'MIT';
}
