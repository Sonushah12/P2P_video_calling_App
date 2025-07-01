import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_app/Controller/call_controller.dart';

class CallScreen extends StatefulWidget {
  final bool isCreator;
  final String? roomId;

  const CallScreen({super.key, required this.isCreator, this.roomId});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallController controller = Get.find<CallController>();
  bool isLocalFullScreen = true;
  Offset overlayPosition = const Offset(20, 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (controller.isInitialized) {
        if (widget.isCreator) {
          await controller.createRoom();
        } else if (widget.roomId != null && widget.roomId!.isNotEmpty) {
          await controller.joinRoom(widget.roomId!);
        } else {
          Get.back();
          Get.snackbar('Error', 'Invalid Room ID');
        }
      } else {
        Get.snackbar('Error', 'Waiting for initialization');
      }
    });
  }

  Widget _buildVideoView(RTCVideoRenderer renderer, {bool mirror = true}) {
    return RTCVideoView(
      renderer,
      mirror: mirror,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallController>(
      builder: (controller) {
        final hasRemote = controller.remoteRenderers.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(
              'Room: ${controller.roomId.isEmpty ? "Connecting..." : controller.roomId}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () {
                  if (controller.roomId.isNotEmpty) {
                    Get.snackbar('Copied', 'Room ID copied to clipboard');
                    Clipboard.setData(ClipboardData(text: controller.roomId));
                  }
                },
              ),
              if (widget.isCreator)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await controller.hangUp();
                    Get.snackbar('Info', 'Room ended');
                  },
                ),
            ],
          ),
          body: Stack(
            children: [
              // Fullscreen video
              Positioned.fill(
                child: (controller.localRenderer.srcObject == null && controller.remoteRenderers.isEmpty)
                    ? const Center(
                  child: Text('Waiting for streams...', style: TextStyle(color: Colors.white)),
                )
                    : isLocalFullScreen || !hasRemote
                    ? _buildVideoView(controller.localRenderer)
                    : _buildVideoView(controller.remoteRenderers.first),
              ),

              // Small overlay video
              if (hasRemote)
                Positioned(
                  left: overlayPosition.dx,
                  top: overlayPosition.dy,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isLocalFullScreen = !isLocalFullScreen;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        overlayPosition += details.delta;
                      });
                    },
                    child: Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isLocalFullScreen
                            ? _buildVideoView(controller.remoteRenderers.first)
                            : _buildVideoView(controller.localRenderer),
                      ),
                    ),
                  ),
                ),

              // Bottom control buttons
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        controller.isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: controller.toggleMute,
                    ),
                    IconButton(
                      icon: Icon(
                        controller.isVideoOn ? Icons.videocam : Icons.videocam_off,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: controller.toggleVideo,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.call_end,
                        color: Colors.red,
                        size: 36,
                      ),
                      onPressed: () async {
                        await controller.hangUp();
                        Get.back();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
