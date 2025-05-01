import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../utils/build_context_ext.dart';

class InfoTextWithLottie extends StatelessWidget {
  const InfoTextWithLottie({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lottieAssetPath,
    required this.bellowSubtitle,
    this.spacingBetweenTitleAndSubtitle,
    this.spacingBetweenSubtitleAndBellowSubtitle,
  });

  final String title;
  final String subtitle;
  final String lottieAssetPath;
  final Widget bellowSubtitle;
  final double? spacingBetweenTitleAndSubtitle;
  final double? spacingBetweenSubtitleAndBellowSubtitle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacingBetweenTitleAndSubtitle ?? 16),
                Text(
                  subtitle,
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: context.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacingBetweenSubtitleAndBellowSubtitle ?? 32),
                bellowSubtitle,
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: () {
              final width = screenWidth * 0.4;

              return Lottie.asset(
                lottieAssetPath,
                fit: BoxFit.contain,
                width: width,
                height: width * 0.8,
              );
            }(),
          ),
        ),
      ],
    );
  }
}
