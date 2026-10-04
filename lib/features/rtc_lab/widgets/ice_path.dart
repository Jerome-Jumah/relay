import 'package:flutter/material.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class IcePath extends StatelessWidget {
  const IcePath({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label:
          'ICE path: Local, server reflexive selected, TURN, Peer. Direct connection.',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(RelaySpacing.md + 2),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(RelayRadius.lg - 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ICE path',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: RelaySpacing.md + 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: RelaySpacing.sm,
                children: [
                  for (final item in [
                    'Local',
                    '→',
                    'srflx',
                    '→',
                    'TURN',
                    '→',
                    'Peer',
                  ])
                    item == 'srflx'
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: RelaySpacing.sm + 4,
                              vertical: RelaySpacing.sm + 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(RelayRadius.sm + 2),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : Text(
                            item,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                ],
              ),
              const SizedBox(height: RelaySpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: colors.tertiary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Direct connection',
                    style: TextStyle(color: colors.tertiary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
