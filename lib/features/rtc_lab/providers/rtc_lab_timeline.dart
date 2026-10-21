import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_event.dart';

class RtcLabTimelineNotifier extends Notifier<List<RtcLabEvent>> {
  static const int maxEvents = 100;

  @override
  List<RtcLabEvent> build() => const [];

  void record({
    required RtcLabEventCategory category,
    required String title,
    String? detail,
  }) {
    final event = RtcLabEvent(
      timestamp: DateTime.now(),
      category: category,
      title: title,
      detail: detail,
    );
    state = [event, ...state].take(maxEvents).toList(growable: false);
  }

  void clear() {
    state = const [];
  }
}

final rtcLabTimelineProvider =
    NotifierProvider<RtcLabTimelineNotifier, List<RtcLabEvent>>(RtcLabTimelineNotifier.new);
