// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:get/get.dart';
// import 'package:webrtc_app/Controller/call_controller.dart';
//
// class CallScreen extends StatelessWidget {
//   final CallController callController = Get.find();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Call')),
//       body: Obx(() => Column(
//         children: [
//           Expanded(
//             child: RTCVideoView(
//               callController.localRenderer.value,
//               mirror: true,
//             ),
//           ),
//           Expanded(
//             child: RTCVideoView(
//               callController.remoteRenderer.value,
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: Icon(callController.isMuted.value ? Icons.mic_off : Icons.mic),
//                 onPressed: callController.toggleMute,
//               ),
//               IconButton(
//                 icon: Icon(Icons.call_end),
//                 onPressed: () {
//                   callController.endCall();
//                   Get.back();
//                 },
//               ),
//               IconButton(
//                 icon: Icon(callController.isVideoEnabled.value ? Icons.videocam : Icons.videocam_off),
//                 onPressed: callController.toggleVideo,
//               ),
//             ],
//           ),
//         ],
//       )),
//     );
//   }
// }
//
