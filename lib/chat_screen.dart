import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector_macos/file_selector_macos.dart';
import 'chat_message.dart';
import 'openai.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path; // Add this import for path manipulation

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  void pickAndProcessImage() async {
    try {
      String? downloadsPath;
      if (Platform.isWindows) {
        downloadsPath = 'C:/Users/${Platform.environment['USERNAME']}/Downloads/';
      } else if (Platform.isMacOS) {
        downloadsPath = '/Users/${Platform.environment['USER']}/Downloads/';
      } else if (Platform.isLinux) {
        downloadsPath = '/home/${Platform.environment['USER']}/Downloads/';
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        initialDirectory: downloadsPath,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'tif', 'heic',
          'JPG', 'JPEG', 'PNG', 'GIF', 'BMP', 'TIFF', 'TIF', 'HEIC',
        ],
      );

      if (result == null) {
        print("File picker result is null - no file selected.");
        return;
      }

      // This gives you the path as a String, and it's nullable
      final String? selectedFilePath = result.files.single.path;

      // Check if the path is not null
      if (selectedFilePath == null) {
        print("File path is null - file might be invalid.");
        return;
      }

      // The path is now definitely a non-null String
      // Create a File object from the path
      File file = File(selectedFilePath);
      Uint8List fileBytes;

      // final filepath = result.files.single.path; // This should give you the path as a String
      // // final PlatformFile pickedFile = result.files.first;
      // // String? filePath = pickedFile.path;
      
      // if (filePath == null) {
      //   print("File path is null - file might be invalid.");
      //   return;
      // }

      // // Directly use the path of the selected file to create a dart:io File
      // File file = File(filePath);
      // Uint8List fileBytes;
      // // File file = File(filePath);
      // // Uint8List fileBytes;

      // Check if the file is a HEIC image and convert it if necessary
      if (selectedFilePath.toLowerCase().endsWith('.heic')) {
        setState(() {
          _messages.insert(0, ChatMessage(text: "Converting from HEIC to JPG...", isImage: false));
        });

        final tempDir = await getTemporaryDirectory();
        final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Attempt to compress and get the File
        XFile? convertedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          format: CompressFormat.jpeg,
          quality: 90,
        );

        if (convertedFile == null) {
          print("Error: HEIC to JPEG conversion failed.");
          return;
        }

        // Read bytes from the converted file
        fileBytes = await convertedFile.readAsBytes();
      } else {
        // If it's not HEIC, read bytes from the original file
        fileBytes = await file.readAsBytes();
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
    } catch (e, stackTrace) {
      print("Error during file pick or processing: $e");
      print("Stack trace: $stackTrace");
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
            child: SelectionArea(
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) => _buildMessageItem(_messages[index]),
                itemCount: _messages.length,
              ),
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
