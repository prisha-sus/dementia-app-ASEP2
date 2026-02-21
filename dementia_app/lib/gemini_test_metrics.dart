import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final model = GenerativeModel(
    model: 'models/gemini-1.5-flash',
    apiKey: 'AIzaSyAuemfQo-tQJbI70u7Y7PZ80C157xmtdxs', // Replace this with your real key
  );

  final prompts = [
    'What day is it today?',
    'Did I already eat lunch?',
    "Where am I right now?",
    "Who is the Prime Minister of India?",
    "How old am I?",
    "Who is my daughter?",
    "Show me my family tree.",
    "Was my husband’s name Rajesh?",
    "Do I have any grandchildren?",
    "Tell me about my wedding day.",
    "Am I supposed to take medicine now?",
    "What is this red pill for?",
    "When is my next doctor appointment?",
    "I feel dizzy. What should I do?",
    "Can you remind me to take my insulin later?",
    "Let’s play a memory game.",
    "Can you ask me a riddle?",
    "Tell me a fun fact about animals.",
    "Help me practice remembering things.",
    "What’s my favorite color?"
  ];

  final file = File('gemini_results.csv');
  final sink = file.openWrite();

  // Write CSV header
  sink.writeln('Prompt,Latency (ms),Status,Response');

  int successCount = 0;
  List<int> latencies = [];

  for (String prompt in prompts) {
    final start = DateTime.now();
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final end = DateTime.now();
      final latency = end.difference(start).inMilliseconds;
      latencies.add(latency);

      final reply = response.text?.replaceAll('\n', ' ').replaceAll(',', ';') ?? "EMPTY";

      sink.writeln('"$prompt",$latency,Success,"$reply"');
      print('✅ "$prompt" responded in ${latency}ms');
      successCount++;
    } catch (e) {
      sink.writeln('"$prompt",-,Error,"$e"');
      print('❌ "$prompt" failed: $e');
    }
  }

  sink.close();

  final avgLatency = latencies.isNotEmpty
      ? latencies.reduce((a, b) => a + b) / latencies.length
      : 0;
  final successRate = (successCount / prompts.length) * 100;

  print('\n📊 ----- Summary -----');
  print('Total Prompts: ${prompts.length}');
  print('Successful Responses: $successCount');
  print('Success Rate: ${successRate.toStringAsFixed(2)}%');
  print('Average Latency: ${avgLatency.toStringAsFixed(2)} ms');
  print('CSV file saved as: gemini_results.csv');
}
