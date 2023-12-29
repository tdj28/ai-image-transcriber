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
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

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

      // Check if the file is a HEIC image and convert it if necessary
      if (selectedFilePath.toLowerCase().endsWith('.heic')) {
        setState(() {
          _messages.insert(0, ChatMessage(text: "Converting from HEIC to JPG...", isImage: false, isUserMessage: false));
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

      //Uint8List? fileBytes = await processImage(file);

      if (fileBytes != null) {

        String base64Image = base64.encode(fileBytes);

        setState(() {
          _messages.insert(0, ChatMessage(imageData: fileBytes, isImage: true, isUserMessage: true));
          _messages.insert(0, ChatMessage(text: "Processing via Artificial Intelligence...please wait", isImage: false, isUserMessage: false));
        });

        getResponseFromOpenAI(
          textInput: "Here is an image, can you transcribe it? Please correct obvious spelling errors and grammar errors. Please only provide the transcript, unless you aren't sure about something in which case add some notes about that uncertainty and separate it from the transcript with =================================",
          base64Image: base64Image).then((responseText) {
          setState(() {
            _messages.insert(0, ChatMessage(text: responseText, isImage: false, isUserMessage: false));
          });
        });
      }
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
      _messages.insert(0, ChatMessage(text: text, isImage: false, isUserMessage: true));
    });

// getResponseFromOpenAI(
//   textInput: "Here is some text I want to process with OpenAI.",
//   base64Image: "your_base64_encoded_image_string_here", // pass this only if you have an image
// );
    getResponseFromOpenAI(textInput: text).then((responseText) {
      setState(() {
        _messages.insert(0, ChatMessage(text: responseText, isImage: false, isUserMessage: false));
      });
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
            decoration: BoxDecoration(color: Colors.blue.shade100),
            //decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    // Define colors for user and AI messages
    Color userMessageColor = Colors.blue.shade100; // Example color for user messages
    Color aiMessageColor = Colors.green.shade100; // Example color for AI messages

    // Alignment based on the message sender
    AlignmentGeometry alignment = message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft;

    // Define a common container style
    BoxDecoration boxDecoration = BoxDecoration(
      color: message.isUserMessage ? userMessageColor : aiMessageColor,
      borderRadius: BorderRadius.circular(10),
    );

    Widget messageContent;
    if (message.isImage) {
      // For image messages
      messageContent = message.imageData != null
          ? Image.memory(message.imageData!, fit: BoxFit.contain)
          : Placeholder();
    } else {
      // For text messages
      messageContent = Text(
        message.text ?? '',
        style: TextStyle(
          // Your text style here
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        decoration: boxDecoration,
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(8.0),
        child: messageContent,
      ),
    );
  }



}
