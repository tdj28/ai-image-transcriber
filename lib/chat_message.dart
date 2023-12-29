import 'package:flutter/material.dart';
import 'dart:typed_data';

class ChatMessage {
  final String? text;
  final Uint8List? imageData;
  final bool isImage;
  final bool isUserMessage; // New property to indicate if the message is from the user

  ChatMessage({this.text, this.imageData, this.isImage = false, this.isUserMessage = true});
}


// class ChatMessageWidget extends StatelessWidget {
//   final ChatMessage message;

//   ChatMessageWidget({required this.message});

//   @override
//   Widget build(BuildContext context) {
//     Color userMessageColor = Colors.blue.shade100; // Example color for user messages
//     Color aiMessageColor = Colors.green.shade100; // Example color for AI messages

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//       child: Align(
//         alignment: message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           padding: EdgeInsets.all(8.0),
//           decoration: BoxDecoration(
//             color: message.isUserMessage ? userMessageColor : aiMessageColor,
//             borderRadius: BorderRadius.circular(10.0),
//             border: Border.all(color: Colors.red), // Temporary border for debugging
//           ),
//           constraints: BoxConstraints(minHeight: 50), // Ensures a minimum height
//           child: message.isImage && message.imageData != null
//               ? Image.memory(message.imageData!)
//               : TextField(
//                   controller: TextEditingController(text: message.text),
//                   readOnly: true,
//                   maxLines: null,
//                   decoration: InputDecoration(border: InputBorder.none),
//                 ),
//         ),
//       ),
//     );
//   }
// }
