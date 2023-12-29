import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> getResponseFromOpenAI({String? base64Image, String? textInput}) async {
  try {
    List<Map<String, dynamic>> contentList = [];

    // Add text input to the content list if provided
    if (textInput != null) {
      contentList.add({"type": "text", "text": textInput});
    }

    // If an image is provided, add the specific prompt for the image
    if (base64Image != null) {
      // contentList.add({
      //   "type": "text",
      //   "text": "Here is an image, can you transcribe it? Please correct obvious spelling errors and grammar errors. Please only provide the transcript, unless you aren't sure about something in which case add some notes about that uncertainty and separate it from the transcript with ================================="
      // });
      contentList.add({"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}});
    }

    var response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${dotenv.env['OPENAI_KEY']}',
      },
      body: jsonEncode({
        "model": "gpt-4-vision-preview",
        "max_tokens": 4096,
        "messages": [
          {
            "role": "user",
            "content": contentList
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody['choices'][0]['message']['content'];
    } else {
      print('Request failed with status: ${response.statusCode}.');
      print('Response body: ${response.body}');
      return "Sorry, I couldn't process that. Status Code: ${response.statusCode}";
    }
  } catch (e) {
    print('An error occurred: $e');
    return "An error occurred: $e";
  }
}
