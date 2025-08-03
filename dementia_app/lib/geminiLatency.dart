import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String geminiApiUrl =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";

Future<int> getGeminiResponse(String userInput, String apiKey) async {
  final stopwatch = Stopwatch()..start();
  
  final contents = [
    {
      'role': 'user',
      'parts': [
        {'text': userInput}
      ]
    }
  ];
  
  final requestBody = {
    'contents': contents,
    'generationConfig': {
      'temperature': 0.4,
      'topK': 32,
      'topP': 0.95,
      'maxOutputTokens': 150,
    }
  };
  
  final uri = Uri.parse('$geminiApiUrl?key=$apiKey');
  
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    
    stopwatch.stop();
    final latency = stopwatch.elapsedMilliseconds;
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = '';
      
      // More robust response parsing
      try {
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          text = data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        }
      } catch (parseError) {
        print('Error parsing response: $parseError');
        print('Raw response: ${response.body}');
      }
      
      print('Response (latency: ${latency}ms): ${text.length > 100 ? text.substring(0, 100) + "..." : text}');
      return latency;
    } else {
      print('API error ${response.statusCode}: ${response.body}');
      return latency;
    }
  } catch (e) {
    stopwatch.stop();
    print('Network/Request error: $e');
    return stopwatch.elapsedMilliseconds;
  }
}

Future<void> main(List<String> arguments) async {
  try {
    // Load environment variables
    await dotenv.load();
    
    // Get API key and validate
    final String geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (geminiApiKey.isEmpty) {
      print('Error: GEMINI_API_KEY not found in .env file');
      exit(1);
    }
    
    final int iterations =
        arguments.isNotEmpty ? int.tryParse(arguments[0]) ?? 10 : 10;
    
    if (iterations <= 0) {
      print('Error: Number of iterations must be positive');
      exit(1);
    }
    
    List<int> latencies = [];
    List<int> failedRequests = [];
    
    print('Sending $iterations requests to Gemini API...');
    
    for (int i = 0; i < iterations; i++) {
      print('\nRequest ${i + 1}:');
      try {
        final latency = await getGeminiResponse('Hello, how are you?', geminiApiKey);
        latencies.add(latency);
      } catch (e) {
        print('Request ${i + 1} failed: $e');
        failedRequests.add(i + 1);
      }
      
      // Add delay between requests to avoid rate limiting
      if (i < iterations - 1) {
        await Future.delayed(Duration(seconds: 1));
      }
    }
    
    // Calculate and display statistics
    if (latencies.isNotEmpty) {
      final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      final minLatency = latencies.reduce((a, b) => a < b ? a : b);
      final maxLatency = latencies.reduce((a, b) => a > b ? a : b);
      
      print('\n--- Gemini API Latency Stats ---');
      print('Total requests sent: $iterations');
      print('Successful requests: ${latencies.length}');
      print('Failed requests: ${failedRequests.length}');
      if (failedRequests.isNotEmpty) {
        print('Failed request numbers: $failedRequests');
      }
      print('Average latency: ${avgLatency.toStringAsFixed(2)} ms');
      print('Minimum latency: $minLatency ms');
      print('Maximum latency: $maxLatency ms');
    } else {
      print('\nNo successful requests completed. Check your API key and network connection.');
    }
    
  } catch (e) {
    print('Fatal error: $e');
    exit(1);
  }
}