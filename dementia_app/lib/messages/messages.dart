import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  TextEditingController _messageController = TextEditingController();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  String _userType = ""; // User role (patient, caregiver, etc.)
  bool _hasSentFirstMessage = false;
  String _roleGreeting = "loading...";
  bool _isTyping = false; // Track if the AI is "typing"

  // Gemini API configuration
 final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String _geminiApiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";

  // Fallback settings for handling API issues
  bool _useLocalFallback =
      false; // Set to true to use local responses when API fails
  int _errorCount = 0; // Track consecutive API errors

  // Chat history for context
  List<Map<String, dynamic>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _fetchUserRole();
  }

  // Fetch user role from Firestore
  Future<void> _fetchUserRole() async {
    
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          var userRole = userDoc['role'];
          if (userRole != null) {
            setState(() {
              final local = Localizations.of(context, AppLocalizations);
              _userType = userRole;
              _roleGreeting = '${local.hey} $userRole, ${local.howCanIHelp}';
            });
            print("User role: $_userType");
          } else {
            print("User role not found in Firestore.");
          }
        } else {
          print("User document not found.");
        }
      } catch (e) {
        print('Error fetching user role: $e');
      }
    } else {
      print("User not authenticated.");
    }
  }

  // Generate a fallback response locally when API is unavailable
  String _getFallbackResponse(String userMessage) {
    // Simple keyword matching for basic responses
    final String messageLower = userMessage.toLowerCase();

    if (messageLower.contains('hello') || messageLower.contains('hi')) {
      return 'Hello! How are you feeling today?';
    } else if (messageLower.contains('how are you')) {
      return "I'm here to help you with your healthcare needs. What can I assist you with today?";
    } else if (messageLower.contains('thank')) {
      return "You're welcome! Is there anything else I can help with?";
    } else if (messageLower.contains('pain') || messageLower.contains('hurt')) {
      return "I understand you're experiencing discomfort. It's important to discuss your symptoms with your healthcare provider. Would you like me to help you log your symptoms?";
    } else if (messageLower.contains('medication') ||
        messageLower.contains('medicine')) {
      return "Medication questions are important. For specific advice about your medications, please consult your healthcare provider or pharmacist directly.";
    } else {
      return "I'm currently operating in offline mode due to connection issues. For urgent matters, please contact your healthcare provider directly. For non-urgent inquiries, please try again later when our connection is restored.";
    }
  }

  // Function to send a message and get AI response
  Future<void> sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    // Update state to hide greeting if first message
    if (!_hasSentFirstMessage) {
      setState(() {
        _hasSentFirstMessage = true;
      });
    }

    // Add user message to Firestore
    try {
      await _firestore.collection('messages').add({
        'sender': _userType,
        'message': userMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'isAI': false,
      });

      // Add message to chat history for context
      _chatHistory.add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ]
      });

      // Set typing state to show AI is responding
      setState(() {
        _isTyping = true;
      });

      String aiResponse;

      // Check if we should use local fallback due to API issues
      if (_useLocalFallback) {
        // Use local response generator instead of API
        aiResponse = _getFallbackResponse(userMessage);
        await Future.delayed(Duration(seconds: 1)); // Simulate processing time
      } else {
        // Try to get response from Gemini API
        try {
          aiResponse = await _getGeminiResponse(userMessage);
          _errorCount = 0; // Reset error count on success
        } catch (apiError) {
          print("API Error: $apiError");
          _errorCount++;

          // If we've had multiple consecutive errors, switch to fallback mode
          if (_errorCount >= 3) {
            setState(() {
              _useLocalFallback = true;
            });
            aiResponse =
                "I'm having trouble connecting to my knowledge base. I'll switch to offline mode for now. ${_getFallbackResponse(userMessage)}";
          } else {
            aiResponse =
                "I'm sorry, I encountered a technical issue. Please try again.";
          }
        }
      }

      // Add AI response to Firestore
      await _firestore.collection('messages').add({
        'sender': _useLocalFallback ? 'AI Assistant (Offline)' : 'Gemini AI',
        'message': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
        'isAI': true,
      });

      // Add AI response to chat history
      _chatHistory.add({
        'role': 'model',
        'parts': [
          {'text': aiResponse}
        ]
      });

      // Update UI to show AI is done typing
      setState(() {
        _isTyping = false;
      });
    } catch (e) {
      print("Error in message flow: $e");
      setState(() {
        _isTyping = false;
      });

      // Show error message in chat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message. Please check your connection.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

Future<String> _getGeminiResponse(String userInput) async {
  final stopwatch = Stopwatch()..start();

  try {
    // --- Build conversation context ---
    List<Map<String, dynamic>> contents = [];

    if (_chatHistory.isEmpty || _chatHistory[0]['role'] != 'system') {
      contents.add({
        'role': 'user',
        'parts': [
          {
            'text':
                'You are a concise healthcare assistant providing brief responses. Please keep your answers focused, informative, and to the point. Your role is to provide healthcare information while being clear that you are not a substitute for professional medical advice. Use human language and empathetic answers only. Don’t end every message with it not being a medical advice — it’s okay.'
          }
        ]
      });

      contents.add({
        'role': 'model',
        'parts': [
          {
            'text':
                "I understand. I'll act as a concise healthcare assistant, providing brief, focused responses while making it clear I'm not a substitute for professional medical advice."
          }
        ]
      });
    }

    int historyStartIndex =
        _chatHistory.length > 5 ? _chatHistory.length - 5 : 0;
    contents.addAll(_chatHistory.sublist(historyStartIndex));

    final Map<String, dynamic> requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.4,
        'topK': 32,
        'topP': 0.95,
        'maxOutputTokens': 150,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    };

    final uri = Uri.parse('$_geminiApiUrl?key=$_geminiApiKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    stopwatch.stop();
    final latency = stopwatch.elapsedMilliseconds;

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      String text = '';

      if (responseData.containsKey('candidates') &&
          responseData['candidates'].isNotEmpty &&
          responseData['candidates'][0].containsKey('content') &&
          responseData['candidates'][0]['content'].containsKey('parts') &&
          responseData['candidates'][0]['content']['parts'].isNotEmpty) {
        text = responseData['candidates'][0]['content']['parts'][0]['text'];
      }

      if (text.isEmpty) text = "I'm sorry, I don't have a response for that.";

      // === METRIC BENCHMARKING ===
      _logPerformanceMetrics(
        input: userInput,
        response: text,
        latency: latency,
      );

      return text;
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      return "I'm sorry, I'm having trouble connecting to my knowledge base. Please try again later.";
    }
  } catch (e) {
    print('Gemini API Error: $e');
    return "I'm sorry, I encountered an error. Please try again.";
  }
}
void _logPerformanceMetrics({
  required String input,
  required String response,
  required int latency,
}) {
  // Heuristic distress detection
  final inputLower = input.toLowerCase();
  final responseLower = response.toLowerCase();
  final isDistressInput = inputLower.contains("sad") ||
      inputLower.contains("depressed") ||
      inputLower.contains("help") ||
      inputLower.contains("panic");
  final detectedDistress = responseLower.contains("call") ||
      responseLower.contains("emergency") ||
      responseLower.contains("contact");

  final isTP = isDistressInput && detectedDistress;
  final isFN = isDistressInput && !detectedDistress;

  print("🧪 Benchmark:");
  print("💬 Input: $input");
  print("🤖 Response: $response");
  print("⏱️ Latency: ${latency} ms");
  if (isTP) print("✅ Distress correctly detected (TP)");
  if (isFN) print("❌ Distress missed (FN)");

  // OPTIONAL: Save to Firestore
  // _firestore.collection('chat_metrics').add({
  //   'uid': _auth.currentUser?.uid ?? "anon",
  //   'input': input,
  //   'response': response,
  //   'latency_ms': latency,
  //   'is_distress': isDistressInput,
  //   'detected_distress': detectedDistress,
  //   'timestamp': FieldValue.serverTimestamp(),
  // });
}


  @override
  Widget build(BuildContext context) {
    final local = Localizations.of(context, AppLocalizations);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(local.healthcareChatBot),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          // Show API status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _useLocalFallback ? Colors.orange : Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _useLocalFallback ? local.offline : local.online,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Display greeting if no messages have been sent yet
          if (!_hasSentFirstMessage)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _roleGreeting,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

          // Show "typing" indicator when AI is responding
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(local.geminiTyping,
                      style: TextStyle(fontStyle: FontStyle.italic)),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;
                    var message = messageData['message'] ?? '';
                    var sender = messageData['sender'] ?? '';
                    var timestamp = messageData['timestamp'];
                    var isAI = messageData['isAI'] ?? false;

                    // Determine message alignment based on who sent it
                    bool isSentByUser = !isAI;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: isSentByUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Sender name
                          Text(
                            sender,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:colorScheme.onPrimary),
                          ),

                          // Message bubble
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isSentByUser
                                  ? colorScheme.tertiary.withOpacity(0.5)
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.onPrimary.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            child: Text(
                              message,
                              style: TextStyle(fontSize: 16, color: colorScheme.onPrimary),
                            ),
                          ),

                          // Timestamp
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              timestamp != null
                                  ? _formatTimestamp(timestamp.toDate())
                                  : '',
                              style:
                                  TextStyle(fontSize: 10, color: colorScheme.onPrimary.withOpacity(0.6),)
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: colorScheme.onPrimary), // Change input text color here
          decoration: InputDecoration(
            hintText: 'Type your message...',
            hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.6)), // Change hint text color here
                      enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(color: colorScheme.tertiary), // Border color when not focused
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(color: colorScheme.tertiary, width: 2.0), // Border when focused
            ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: theme.scaffoldBackgroundColor),
                    onPressed: _isTyping ? null : sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to format timestamp
  String _formatTimestamp(DateTime dateTime) {
    // Format: Today at 2:30 PM or Apr 28 at 2:30 PM
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
final local = Localizations.of(context, AppLocalizations);
    if (date == today) {
      return '${local.todayAt} ${_formatTimeOfDay(dateTime)}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${local.at} ${_formatTimeOfDay(dateTime)}';
    }
  }

  String _formatTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
