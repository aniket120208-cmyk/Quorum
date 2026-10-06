import 'package:camera/camera.dart';

enum CallStatus { connecting, connected, ended }

class VideoCallState {
  final CallStatus status;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final CameraLensDirection currentLens;
  final int callDurationSeconds;
  final bool isMockRemoteConnected;
  final CameraController? cameraController;
  final bool isInitialized;
  final String? errorMessage;

  const VideoCallState({
    this.status = CallStatus.connecting,
    this.isMicMuted = false,
    this.isCameraOff = false,
    this.isSpeakerOn = true,
    this.currentLens = CameraLensDirection.front,
    this.callDurationSeconds = 0,
    this.isMockRemoteConnected = false,
    this.cameraController,
    this.isInitialized = false,
    this.errorMessage,
  });

  VideoCallState copyWith({
    CallStatus? status,
    bool? isMicMuted,
    bool? isCameraOff,
    bool? isSpeakerOn,
    CameraLensDirection? currentLens,
    int? callDurationSeconds,
    bool? isMockRemoteConnected,
    CameraController? cameraController,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return VideoCallState(
      status: status ?? this.status,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      currentLens: currentLens ?? this.currentLens,
      callDurationSeconds: callDurationSeconds ?? this.callDurationSeconds,
      isMockRemoteConnected: isMockRemoteConnected ?? this.isMockRemoteConnected,
      cameraController: cameraController ?? this.cameraController,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
    );
  }
}