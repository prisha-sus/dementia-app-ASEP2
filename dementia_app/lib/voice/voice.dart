import 'package:flutter/material.dart';
//import 'package:mytestapp/shared/bottom_nav.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;  
  bool _speechAvailable = false;
  String _recognizedText = '';  
  String _response = '';
  String _detectedLanguage = '';

  // Keywords for English, Hindi, and Marathi
  Map<String, Map<String, String>> keywordResponses = {
    'en': {
      'help': 'I am here with you. You are safe.',
      'who': 'Let us go look together, just to make sure everything is okay.',
    },
    'hi': {
      'बचाओ': 'मैं आपके साथ हूँ। डरने की ज़रूरत नहीं है।',
      'कौन': 'आपको क्या दिख रहा है? मुझे बताइए।',
    },
    'mr': {
      'वाचवा': 'मी तुम्च्या सोबत आहे. घाबरू नका.',
      'कोण': 'तुम्हाला काय दिसतंय? मला सांगा.',
    },
  };

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeSpeechRecognition();
    await langdetect.initLangDetect();
  }

  Future<void> _initializeSpeechRecognition() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: _statusListener,
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );
    if (_speechAvailable) {
      _startListening();
    } else {
      print('Speech recognition not available');
    }
  }

  //Speech status listener
  void _statusListener(String status) {
    if (status == 'done' || status == 'notListening') {
        _startListening(); // restart listening when done or not listening
  }
  }

  //Start listening for speech input
  void _startListening() {
    if(_speechAvailable && !_isListening) {
      _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: false,
          //pauseFor: Duration(seconds: 3),
      ),
      );
      setState(() => _isListening = true);
    }
  }

  //Process the recognized text
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      setState(() => _recognizedText = result.recognizedWords);
      _processRecognizedText(_recognizedText.toLowerCase());
    }
  }

  //Check recognized text for keywords and speak response
  Future<void> _processRecognizedText(String text) async {
    final detected = langdetect.detect(text); // en, hi, mr
    setState(() => _detectedLanguage = detected);

    final langMap = keywordResponses[detected] ?? {};
    for (var keyword in langMap.keys) {
      if (text.contains(keyword)) {
        final response = langMap[keyword]!;
        setState(() => _response = response);

        await _flutterTts.setLanguage(_getTtsLocale(detected)); // Set correct TTS language
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.9);
        await _flutterTts.speak(response);
        return;
      }

    }

    setState(() => _response = ' ');
  }

  //Return the correct locale for TTS
   String _getTtsLocale(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'hi-IN'; // Hindi TTS
      case 'mr':
        return 'mr-IN'; // Marathi TTS
      default:
        return 'en-US'; // Default to English
    }
  }

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Voice Recognition"),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}*/

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Multilingual Voice Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Listening...", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text("Heard: $_recognizedText", style: TextStyle(fontSize: 16)),
            Text("Detected Language: $_detectedLanguage"),
            if (_response.isNotEmpty) ...[
              SizedBox(height: 20),
              Text("Response: $_response", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}