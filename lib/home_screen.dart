// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:webrtc_app/controller/call_controller.dart';
// import 'call_screen.dart';
//
// class HomeScreen extends StatelessWidget {
//   final CallController callController = Get.find<CallController>();
//   final TextEditingController roomIdController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     print('Building HomeScreen');
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(title: Text('WebRTC Chat')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.red), // Debug border
//           ),
//           child: Column(
//             children: [
//               Text('Test Widget', style: TextStyle(fontSize: 24, color: Colors.black)),
//               TextField(
//                 controller: roomIdController,
//                 decoration: InputDecoration(labelText: 'Room ID'),
//               ),
//               TextField(
//                 controller: passwordController,
//                 decoration: InputDecoration(labelText: 'Password'),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   await callController.createOrJoinRoom(
//                     roomIdController.text,
//                     passwordController.text,
//                   );
//                   if (callController.roomId.value.isNotEmpty) {
//                     Get.to(() => CallScreen());
//                   } else {
//                     Get.snackbar('Error', 'Failed to join room');
//                   }
//                 },
//                 child: Text('Create/Join Room'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }