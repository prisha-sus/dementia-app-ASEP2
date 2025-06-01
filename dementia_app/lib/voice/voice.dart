import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'package:permission_handler/permission_handler.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with WidgetsBindingObserver {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _response = '';
  String _detectedLanguage = 'en';
  String _statusMessage = 'Initializing...';
  List<String> _conversationHistory = [];
  
  // Confidence threshold for speech recognition
  double _confidenceThreshold = 0.5;
  
  // Auto-restart listening timer
  Timer? _restartTimer;

  // Enhanced keywords with variations and fuzzy matching
  Map<String, Map<String, List<String>>> keywordResponses = {
    'en': {
      'help': ['help', 'emergency', 'save me', 'danger', 'scared', 'afraid'],
      'who': ['who is there', 'who', 'someone there', 'anybody there', 'is someone here'],
      'where': ['where am i', 'where', 'location', 'lost'],
      'pain': ['pain', 'hurt', 'hurting', 'ache', 'sore'],
      'call': ['call someone', 'call help', 'phone', 'contact'],
    },
    'hi': {
      'बचाओ': ['बचाओ', 'बचाइए', 'मदद', 'खतरा', 'डर'],
      'कौन': ['कौन है', 'कौन', 'कोई है', 'कोई वहाँ है'],
      'कहाँ': ['कहाँ हूँ', 'कहाँ', 'स्थान', 'गुम'],
      'दर्द': ['दर्द', 'पीड़ा', 'तकलीफ', 'चोट'],
      'फोन': ['फोन करो', 'कॉल करो', 'मदद बुलाओ'],
    },
    'mr': {
      'वाचवा': ['वाचवा', 'वाचव', 'मदत', 'धोका', 'घाबरणे'],
      'कोण': ['कोण आहे', 'कोण', 'कुणी आहे', 'कुणी तिथे आहे'],
      'कुठे': ['कुठे आहे', 'कुठे', 'स्थान', 'हरवले'],
      'दुखत': ['दुखत आहे', 'दुखते', 'वेदना', 'दुखतात'],
      'फोन': ['फोन करा', 'कॉल करा', 'मदत बोलवा'],
    },
  };

  // Enhanced responses with more reassuring and helpful content
  Map<String, Map<String, String>> responses = {
    'en': {
      'help': 'I understand you need help. Take a deep breath. You are safe right now. If this is an emergency, say "call emergency" and I will guide you.',
      'who': 'Let me help you feel safe. Look around slowly and describe what you see. I am here with you.',
      'where': 'You are in a safe place. Try to look for any familiar landmarks or signs around you. I can help you figure out your location.',
      'pain': 'I hear that you are in pain. Try to sit or lie down comfortably. If the pain is severe, say "call emergency" for immediate help.',
      'call': 'I can help you with that. In an emergency, dial your local emergency number. For non-emergencies, contact a trusted friend or family member.',
    },
    'hi': {
      'बचाओ': 'मैं समझ रहा हूँ कि आपको मदद चाहिए। गहरी सांस लें। आप अभी सुरक्षित हैं। यदि यह आपातकाल है तो "आपातकाल कॉल करें" कहें।',
      'कौन': 'मैं आपको सुरक्षित महसूस कराने में मदद करूंगा। धीरे-धीरे चारों ओर देखें और बताएं कि आपको क्या दिख रहा है।',
      'कहाँ': 'आप एक सुरक्षित जगह पर हैं। अपने आसपास कोई पहचान के निशान देखने की कोशिश करें।',
      'दर्द': 'मैं समझ रहा हूँ कि आपको दर्द हो रहा है। आराम से बैठने या लेटने की कोशिश करें। यदि दर्द गंभीर है तो तुरंत मदद के लिए कहें।',
      'फोन': 'मैं इसमें आपकी मदद कर सकता हूँ। आपातकाल में अपना स्थानीय आपातकालीन नंबर डायल करें।',
    },
    'mr': {
      'वाचवा': 'मला समजतंय की तुम्हाला मदतीची गरज आहे। दीर्घ श्वास घ्या। तुम्ही आता सुरक्षित आहात। जर ही आपत्काल असेल तर "आपत्काल कॉल करा" म्हणा।',
      'कोण': 'मी तुम्हाला सुरक्षित वाटण्यास मदत करेन। हळू हळू भोवती पहा आणि काय दिसतंय ते सांगा।',
      'कुठे': 'तुम्ही सुरक्षित ठिकाणी आहात. तुमच्या भोवती ओळखीची चिन्हे शोधून पहा।',
      'दुखत': 'मला समजतंय की तुम्हाला त्रास होत आहे। आरामात बसायचा किंवा झोपायचा प्रयत्न करा।',
      'फोन': 'मी यात तुमची मदत करू शकतो. आपत्काळात तुमचा स्थानिक आपत्काळ नंबर डायल करा।',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flutterTts = FlutterTts();
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restartTimer?.cancel();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopListening();
    } else if (state == AppLifecycleState.resumed && _isInitialized) {
      _startListening();
    }
  }

  Future<void> _initializeApp() async {
    setState(() => _statusMessage = 'Checking permissions...');
    
    // Request microphone permission
    await _requestMicrophonePermission();
    
    setState(() => _statusMessage = 'Initializing language detection...');
    await langdetect.initLangDetect();
    
    setState(() => _statusMessage = 'Initializing speech recognition...');
    await _initializeSpeechRecognition();
    
    setState(() => _statusMessage = 'Configuring text-to-speech...');
    await _configureTts();
    
    setState(() {
      _statusMessage = 'Ready to listen!';
      _isInitialized = true;
    });
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() => _statusMessage = 'Microphone permission required');
      throw Exception('Microphone permission denied');
    }
  }

  Future<void> _configureTts() async {
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    
    // Set completion handler
    _flutterTts.setCompletionHandler(() {
      if (!_isListening && _speechAvailable) {
        _startListening();
      }
    });
  }

  Future<void> _initializeSpeechRecognition() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: _statusListener,
      onError: _errorListener,
      debugLogging: true,
    );
    
    if (_speechAvailable) {
      _startListening();
    } else {
      setState(() => _statusMessage = 'Speech recognition not available');
      throw Exception('Speech recognition initialization failed');
    }
  }

  void _statusListener(String status) {
    print('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        setState(() => _isListening = false);
        
        // Restart listening after a short delay
        _restartTimer?.cancel();
        _restartTimer = Timer(Duration(milliseconds: 1000), () {
          if (!_isListening && _speechAvailable && mounted) {
            _startListening();
          }
        });
      }
    }
  }

  void _errorListener(error) {
    print('Speech error: $error');
    setState(() {
      _isListening = false;
      _statusMessage = 'Speech error: ${error.errorMsg}';
    });
    
    // Try to restart after error
    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(seconds: 2), () {
      if (!_isListening && _speechAvailable && mounted) {
        _startListening();
      }
    });
  }

  void _startListening() {
    if (_speechAvailable && !_isListening && mounted) {
      _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          onDevice: false,
          cancelOnError: false,
          autoPunctuation: true,
          enableHapticFeedback: true,
        ),
        localeId: _getLocaleForRecognition(_detectedLanguage),
      );
      setState(() {
        _isListening = true;
        _statusMessage = 'Listening...';
      });
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _statusMessage = 'Stopped listening';
      });
    }
  }

  String _getLocaleForRecognition(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'hi_IN';
      case 'mr':
        return 'mr_IN';
      default:
        return 'en_US';
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    final confidence = result.confidence;
    
    setState(() => _recognizedText = text);
    
    // Only process final results with good confidence
    if (result.finalResult && confidence >= _confidenceThreshold) {
      _addToHistory('User: $text');
      _processRecognizedText(text.toLowerCase());
    }
  }

  void _addToHistory(String message) {
    setState(() {
      _conversationHistory.add(message);
      if (_conversationHistory.length > 10) {
        _conversationHistory.removeAt(0);
      }
    });
  }

  Future<void> _processRecognizedText(String text) async {
    try {
      // Detect language
      final detected = langdetect.detect(text);
      setState(() => _detectedLanguage = detected);

      // Find matching keyword using fuzzy matching
      final langKeywords = keywordResponses[detected] ?? keywordResponses['en']!;
      final langResponses = responses[detected] ?? responses['en']!;
      
      String? matchedKey;
      for (var category in langKeywords.keys) {
        final keywords = langKeywords[category]!;
        for (var keyword in keywords) {
          if (_fuzzyMatch(text, keyword)) {
            matchedKey = category;
            break;
          }
        }
        if (matchedKey != null) break;
      }

      if (matchedKey != null) {
        final response = langResponses[matchedKey]!;
        setState(() => _response = response);
        _addToHistory('Assistant: $response');

        // Speak the response
        await _speakResponse(response, detected);
      } else {
        // Default response for unrecognized input
        final defaultResponse = detected == 'hi' 
            ? 'मैं आपकी बात सुन रहा हूँ। कृपया अपनी समस्या बताएं।'
            : detected == 'mr'
            ? 'मी तुमचं ऐकतोय. कृपया तुमची समस्या सांगा.'
            : 'I hear you. Please tell me how I can help.';
        
        setState(() => _response = defaultResponse);
        _addToHistory('Assistant: $defaultResponse');
        await _speakResponse(defaultResponse, detected);
      }
    } catch (e) {
      print('Error processing text: $e');
      setState(() => _response = 'Sorry, I had trouble understanding. Please try again.');
    }
  }

  bool _fuzzyMatch(String text, String keyword) {
    // Simple fuzzy matching - contains keyword or similar
    if (text.contains(keyword)) return true;
    
    // Check for word boundaries
    final words = text.split(' ');
    for (var word in words) {
      if (word == keyword || _calculateSimilarity(word, keyword) > 0.7) {
        return true;
      }
    }
    return false;
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    
    if (longer.isEmpty) return 1.0;
    
    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[a.length][b.length];
  }

  Future<void> _speakResponse(String response, String langCode) async {
    try {
      await _flutterTts.setLanguage(_getTtsLocale(langCode));
      await _flutterTts.speak(response);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  String _getTtsLocale(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Assistant"),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_off),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary,colorScheme.secondary.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: _isListening ? colorScheme.tertiary : colorScheme.onPrimary.withOpacity(0.6),
                          size: 32,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_detectedLanguage.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Language: ${_getLanguageName(_detectedLanguage)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Recognized Text
              if (_recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You said:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _recognizedText,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Response
              if (_response.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.surface.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _response,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

              // Conversation History
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Conversation History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _conversationHistory.length,
                          itemBuilder: (context, index) {
                            final message = _conversationHistory[index];
                            final isUser = message.startsWith('User:');
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? colorScheme.tertiary.withOpacity(0.2): colorScheme.surface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Control Buttons
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isListening ? _stopListening : _startListening,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      label: Text(_isListening ? 'Stop' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? colorScheme.tertiary: colorScheme.surface,
                        foregroundColor: _isListening ? colorScheme.background : colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _conversationHistory.clear();
                          _recognizedText = '';
                          _response = '';
                        });
                      },
                      icon: Icon(Icons.clear),
                      label: Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.background,
                        foregroundColor: colorScheme.tertiary,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'mr':
        return 'Marathi (मराठी)';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }
}