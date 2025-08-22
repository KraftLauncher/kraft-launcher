import 'package:flutter/material.dart';

import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.tiles, super.key});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: textScaler.scale(24),
            bottom: textScaler.scale(10),
            start: 24,
            end: 24,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: context.theme.brightness == Brightness.dark
                  ? const Color(0xffd3e3fd)
                  : const Color(0xff0b57d0),
            ),
            child: Text(title),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: tiles.length,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => tiles[index],
        ),
      ],
    );
  }
}
