import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'chat_message.dart';
import 'openai.dart';
import 'dart:io';


class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  void pickAndProcessImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        // allowedExtensions: [
        //   'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'tif', 'heic', // lowercase
        //   'JPG', 'JPEG', 'PNG', 'GIF', 'BMP', 'TIFF', 'TIF', 'HEIC', // uppercase
        //   // Add any other image formats you need to support
        // ],
      );

      if (result == null) {
        print("File picker result is null - no file selected.");
        return;
      }

      Uint8List fileBytes;
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // On desktop platforms, manually read the file
        String? filePath = result.files.single.path;
        if (filePath == null) {
          print("File path is null - file might be invalid.");
          return;
        }
        fileBytes = await File(filePath).readAsBytes();
      } else {
        // On other platforms, use the bytes directly
        fileBytes = result.files.single.bytes!;
      }

      String base64Image = base64.encode(fileBytes);

      setState(() {
        _messages.insert(0, ChatMessage(imageData: fileBytes, isImage: true));
        _messages.insert(0, ChatMessage(text: "Processing via Artificial Intelligence...please wait", isImage: false));
      });

      getResponseFromOpenAI(base64Image).then((responseText) {
        setState(() {
          _messages.insert(0, ChatMessage(text: responseText, isImage: false));
        });
      });
    } catch (e) {
      print("Error during file pick or processing: $e");
    }
  }



  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration.collapsed(hintText: "Send a message"),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: () => pickAndProcessImage(), // Call the image picker here
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isImage: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _buildMessageItem(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    if (message.isImage) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: message.imageData != null
            ? Image.memory(message.imageData!, fit: BoxFit.contain)
            : Placeholder(),
      );
    } else {
      return ListTile(
        title: Text(message.text ?? ''),
      );
    }
  }
}
