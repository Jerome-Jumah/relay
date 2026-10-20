import 'dart:io';

import 'package:flutter/services.dart';

class RelayScreenShareService {
  static const MethodChannel _channel = MethodChannel('com.code4flare.relay/screen_share');
  static void Function()? onStopScreenShareRequested;

  static void initialize({void Function()? onStopRequested}) {
    onStopScreenShareRequested = onStopRequested;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onStopScreenShareRequested') {
        onStopScreenShareRequested?.call();
      }
    });
  }

  static Future<void> startPlatformService({String? peer}) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('startService', {'peer': peer});
      } catch (_) {}
    }
  }

  static Future<void> stopPlatformService() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('stopService');
      } catch (_) {}
    }
  }
}
