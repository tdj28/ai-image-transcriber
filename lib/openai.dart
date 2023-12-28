import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> getResponseFromOpenAI(String base64Image) async {
  try {
    var response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'), // Replace with the correct OpenAI endpoint
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${dotenv.env['OPENAI_KEY']}',
      },
      body: jsonEncode({
        "model": "gpt-4-vision-preview", // Specify the model (if needed)
        "max_tokens": 4096,
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": "Here is an image, can you transcribe it? Please correct obvious spelling errors and grammar erros. Please only provide the transcript, unless you aren't sure about something in which case add some notes about that uncertainity and separate it from the transcript with ================================="},
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
            ]
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
  } catch (e, stackTrace) {
    print('An error occurred: $e');
    print('Stack trace:\n$stackTrace');
    return "An error occurred: $e";
  }
}
