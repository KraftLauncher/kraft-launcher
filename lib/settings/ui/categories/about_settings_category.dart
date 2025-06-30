import 'package:flutter/material.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/generated/assets.gen.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsCategory extends StatelessWidget {
  const AboutSettingsCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Assets.branding.iconFramed.image(width: 128, height: 128),
        Text(
          ProjectInfoConstants.displayName,
          style: context.theme.textTheme.titleLarge,
        ),
        Text(
          Constants.appDisplayVersion,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.loc.legalDisclaimerMessage(ProjectInfoConstants.displayName),
          textAlign: TextAlign.center,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: context.theme.colorScheme.outline),
        const SizedBox(height: 6),
        ListTile(
          title: Text(context.loc.sourceCode),
          subtitle: Text(
            ProjectInfoConstants.githubRepoLink.replaceFirst('https://', ''),
          ),
          leading: const Icon(Icons.code),
          onTap:
              () => launchUrl(Uri.parse(ProjectInfoConstants.githubRepoLink)),
        ),
        ListTile(
          leading: const Icon(Icons.question_answer),
          title: Text(context.loc.askQuestion),
          onTap: () => launchUrl(Uri.parse(Constants.askQuestionLink)),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: Text(context.loc.reportBug),
          onTap: () => launchUrl(Uri.parse(Constants.reportBugLink)),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: Text(context.loc.contact),
          subtitle: const Text(ProjectInfoConstants.contactEmail),
          onTap:
              () => launchUrl(
                Uri(scheme: 'mailto', path: ProjectInfoConstants.contactEmail),
              ),
        ),
        ListTile(
          title: Text(context.loc.license),
          leading: const Icon(Icons.info),
          subtitle: const Text(Constants.licenseDisplayName),
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }
}
