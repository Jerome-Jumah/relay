import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class CallMoreSheet {
  static void show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('RTC Lab'),
              subtitle: const Text('See the mock connection details'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/rtc-lab');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Call settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    ),
  );
}
