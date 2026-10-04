import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class MockCodeEditor extends StatelessWidget {
  const MockCodeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.md + 2, vertical: RelaySpacing.sm + 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, color: colors.primary, size: 20),
                const SizedBox(width: RelaySpacing.sm + 4),
                Expanded(
                  child: Text(
                    'call_screen.dart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurface, fontSize: 14),
                  ),
                ),
                Icon(Icons.close_rounded, color: colors.onSurfaceVariant, size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(RelaySpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('lib  ›  features  ›  call', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RelaySpacing.sm + 4,
                    RelaySpacing.sm,
                    RelaySpacing.lg,
                    RelaySpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _lines.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: colors.outline),
                                ),
                              ),
                              Text(
                                _lines[i],
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: _lines[i].startsWith('import')
                                      ? colors.secondary
                                      : _lines[i].contains('class') || _lines[i].contains('@override')
                                      ? colors.primary
                                      : colors.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(RelaySpacing.sm + 4),
            color: colors.surfaceContainer,
            child: Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('main', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
                const Spacer(),
                Flexible(
                  child: Text(
                    'Ln 24, Col 34    UTF-8    Dart',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _lines = [
  "import 'package:material_ui/material_ui.dart';",
  '',
  'class CallScreen extends StatelessWidget {',
  '  const CallScreen({super.key});',
  '',
  '  @override',
  '  Widget build(BuildContext context) {',
  '    return Scaffold(',
  '      body: SafeArea(',
  '        child: Column(',
  '          children: [',
  "            Text('1002'),",
  "            Text('04:38'),",
  '            CallControls(),',
  '          ],',
  '        ),',
  '      ),',
  '    );',
  '  }',
  '}',
];
