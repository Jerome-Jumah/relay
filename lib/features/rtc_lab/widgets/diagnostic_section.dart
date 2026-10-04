import 'package:flutter/material.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/shared/widgets/relay_section.dart';

class DiagnosticSection extends StatelessWidget {
  const DiagnosticSection({
    super.key,
    required this.title,
    required this.values,
  });

  final String title;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) => RelaySection(
    title: title,
    children: [
      for (final entry in values.entries)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RelaySpacing.md + 2,
            vertical: RelaySpacing.sm + 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: RelaySpacing.md),
              Flexible(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
