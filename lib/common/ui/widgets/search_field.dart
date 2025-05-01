import 'package:flutter/material.dart';

import '../utils/build_context_ext.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.onSubmitted,
    required this.onChanged,
  });

  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SearchBar(
    onSubmitted: onSubmitted,
    hintText: context.loc.search,
    leading: const Icon(Icons.search),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 16),
    ),
    textInputAction: TextInputAction.search,
    onChanged: onChanged,
  );
}
