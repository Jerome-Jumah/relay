enum RequestedCallMode {
  audio,
  video;

  bool get isAudio => this == RequestedCallMode.audio;
  bool get isVideo => this == RequestedCallMode.video;
}
