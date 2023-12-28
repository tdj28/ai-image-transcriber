import 'dart:typed_data';

class ChatMessage {
  final String? text;
  final Uint8List? imageData;
  final bool isImage;

  ChatMessage({this.text, this.imageData, this.isImage = false});
}
