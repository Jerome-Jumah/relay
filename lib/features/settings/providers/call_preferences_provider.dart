import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/features/settings/models/call_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallPreferencesNotifier extends Notifier<CallPreferences> {
  static const _keyAudioRoute = 'relay_pref_audio_route';
  static const _keyMirrorSelfView = 'relay_pref_mirror_self_view';
  static const _keyVideoQuality = 'relay_pref_video_quality';

  @override
  CallPreferences build() {
    _loadPreferences();
    return const CallPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = CallPreferences(
      audioRoute: prefs.getString(_keyAudioRoute) ?? CallPreferences.defaultAudioRoute,
      mirrorSelfView: prefs.getBool(_keyMirrorSelfView) ?? CallPreferences.defaultMirrorSelfView,
      videoQuality: prefs.getString(_keyVideoQuality) ?? CallPreferences.defaultVideoQuality,
    );
  }

  Future<void> setAudioRoute(String route) async {
    if (!CallPreferences.supportedAudioRoutes.contains(route)) return;
    state = state.copyWith(audioRoute: route);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAudioRoute, route);
  }

  Future<void> setMirrorSelfView(bool mirror) async {
    state = state.copyWith(mirrorSelfView: mirror);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMirrorSelfView, mirror);
  }

  Future<void> setVideoQuality(String quality) async {
    if (!CallPreferences.supportedVideoQualities.contains(quality)) return;
    state = state.copyWith(videoQuality: quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVideoQuality, quality);
  }
}

final callPreferencesProvider = NotifierProvider<CallPreferencesNotifier, CallPreferences>(CallPreferencesNotifier.new);
