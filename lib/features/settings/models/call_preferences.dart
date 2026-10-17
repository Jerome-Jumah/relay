class CallPreferences {
  const CallPreferences({
    this.audioRoute = defaultAudioRoute,
    this.mirrorSelfView = defaultMirrorSelfView,
    this.videoQuality = defaultVideoQuality,
  });

  static const defaultAudioRoute = 'Automatic';
  static const defaultMirrorSelfView = true;
  static const defaultVideoQuality = 'Auto';

  static const supportedAudioRoutes = ['Automatic', 'Speaker', 'Earpiece'];
  static const supportedVideoQualities = ['Auto', '720p', '1080p'];

  final String audioRoute;
  final bool mirrorSelfView;
  final String videoQuality;

  CallPreferences copyWith({String? audioRoute, bool? mirrorSelfView, String? videoQuality}) => CallPreferences(
    audioRoute: audioRoute ?? this.audioRoute,
    mirrorSelfView: mirrorSelfView ?? this.mirrorSelfView,
    videoQuality: videoQuality ?? this.videoQuality,
  );
}
