import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class RelayPermissions {
  const RelayPermissions();

  Future<PermissionStatus> microphoneStatus() => Permission.microphone.status;

  Future<bool> isMicrophoneGranted() async {
    final status = await microphoneStatus();
    return status.isGranted;
  }

  Future<PermissionStatus> requestMicrophone() => Permission.microphone.request();

  Future<PermissionStatus> cameraStatus() => Permission.camera.status;

  Future<bool> isCameraGranted() async {
    final status = await cameraStatus();
    return status.isGranted;
  }

  Future<PermissionStatus> requestCamera() => Permission.camera.request();

  Future<bool> openSettings() => openAppSettings();
}

final relayPermissionsProvider = Provider<RelayPermissions>((ref) => const RelayPermissions());
