import 'package:material_ui/material_ui.dart';

enum RtcLabEventCategory { sip, ice, media, call, share, system }

class RtcLabEvent {
  const RtcLabEvent({required this.timestamp, required this.category, required this.title, this.detail});

  final DateTime timestamp;
  final RtcLabEventCategory category;
  final String title;
  final String? detail;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get categoryLabel => switch (category) {
    RtcLabEventCategory.sip => 'SIP',
    RtcLabEventCategory.ice => 'ICE',
    RtcLabEventCategory.media => 'MEDIA',
    RtcLabEventCategory.call => 'CALL',
    RtcLabEventCategory.share => 'SHARE',
    RtcLabEventCategory.system => 'SYSTEM',
  };

  Color getCategoryColor(ColorScheme colors) => switch (category) {
    RtcLabEventCategory.sip => colors.primary,
    RtcLabEventCategory.ice => colors.tertiary,
    RtcLabEventCategory.media => colors.secondary,
    RtcLabEventCategory.call => colors.primary,
    RtcLabEventCategory.share => colors.error,
    RtcLabEventCategory.system => colors.outline,
  };
}
