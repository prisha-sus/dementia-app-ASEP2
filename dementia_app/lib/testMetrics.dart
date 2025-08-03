import 'dart:convert';
import 'package:http/http.dart' as http;

final chatbotEndpoint = Uri.parse('BACKEND_URL/chatbot');

final List<Map<String, dynamic>> testQueries = [
  {"input": "Hello", "expected": "greeting"},
  {"input": "I'm feeling sad today", "expected": "emotional"},
  {"input": "Call my daughter", "expected": "emergency"},
  {"input": "Play a memory game", "expected": "start_game"},
  {"input": "What time is it?", "expected": "time_query"},
];

Future<void> main() async {
  int correct = 0;
  int distressTP = 0;
  int distressFN = 0;
  double totalLatency = 0;

  for (var query in testQueries) {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final response = await http.post(chatbotEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": query["input"]}));

    final endTime = DateTime.now().millisecondsSinceEpoch;
    final latency = endTime - startTime;
    totalLatency += latency;

    final data = jsonDecode(response.body);
    final actualIntent = data['intent'];
    final distressScore = data['distress_score'] ?? 0.0;

    final isCorrect = query['expected'] == actualIntent;
    if (isCorrect) correct++;

    if (query['expected'] == 'emotional') {
      if (distressScore > 0.6) {
        distressTP++;
      } else {
        distressFN++;
      }
    }

    print(
        'Input: "${query['input']}" → Intent: $actualIntent | Latency: ${latency}ms | Distress: $distressScore');
  }

  final accuracy = (correct / testQueries.length) * 100;
  final avgLatency = totalLatency / testQueries.length;
  final sensitivity = distressTP / (distressTP + distressFN + 1e-6);

  print('\n--- Results ---');
  print('Chatbot Accuracy: ${accuracy.toStringAsFixed(2)}%');
  print('Average Latency: ${avgLatency.toStringAsFixed(2)} ms');
  print('Distress Detection Sensitivity: ${sensitivity.toStringAsFixed(2)}');
}
