import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'dart:developer' as developer;

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String text = "Name an animal that starts with the letter B";
  List<String> correctAnswers = ["Bear", "Baboon", "Bat"];
  String listeningStatus = "Tap the microphone to start";

   Future<void> startListening() async {
    try {
      developer.log('Checking microphone permission');
      var status = await Permission.microphone.status;

      if (status.isDenied) {
        developer.log('Requesting microphone permission');
        status = await Permission.microphone.request();
      }

      if (status.isGranted) {
        developer.log('Attempting to start speech recognition');
        bool available = await speech.initialize();

        if (available) {
          setState(() {
            isListening = true;
            listeningStatus = "Listening...";
          });
          developer.log('Speech recognition started');

          try {
            await speech.listen(
              onResult: (result) {
                if (result.recognizedWords.isNotEmpty) {
                  setState(() {
                    text = result.recognizedWords;
                    developer
                        .log('Recognized words: ${result.recognizedWords}');

                    if (correctAnswers.any((answer) => result.recognizedWords
                        .toLowerCase()
                        .contains(answer.toLowerCase()))) {
                      text = "Correct answer!";
                      developer.log('Correct answer detected');
                    } else {
                      text = "Try again!";
                      developer.log('Incorrect answer detected');
                    }
                  });
                }
              },
              listenFor: const Duration(seconds: 30),
              listenMode: stt.ListenMode.confirmation,
              onSoundLevelChange: (level) {
                if (mounted) {
                  developer.log('Sound level: $level');
                  if (!isListening) {
                    setState(() {
                      listeningStatus = "Tap the microphone to start";
                    });
                  }
                }
              },
            );
          } catch (e) {
            developer.log('Error during speech recognition: $e');
            if (mounted) {
              setState(() {
                listeningStatus = "Error during speech recognition";
                isListening = false;
              });
            }
          }
        } else {
          developer.log('Speech recognition not available');
          setState(() {
            listeningStatus = "Speech recognition not available";
          });
        }
      } else {
        developer.log('Microphone permission denied');
        setState(() {
          listeningStatus = "Microphone permission required";
        });
      }
    } catch (e) {
      developer.log('Error in startListening: $e');
      if (mounted) {
        setState(() {
          listeningStatus = "Error initializing speech recognition";
          isListening = false;
        });
      }
    }
  }

  Future<void> stopListening() async {
    try {
      await speech.stop();
      if (mounted) {
        setState(() {
          isListening = false;
          listeningStatus = "Tap the microphone to start";
        });
      }
      developer.log('Speech recognition stopped');
    } catch (e) {
      developer.log('Error stopping speech recognition: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.5),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'Memory Games',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    listeningStatus,
                    style: TextStyle(
                      fontSize: 16,
                      color: isListening ? Colors.greenAccent : Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isListening)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: isListening ? stopListening : startListening,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          backgroundColor:
                              isListening ? Colors.red : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: Icon(isListening ? Icons.mic_off : Icons.mic),
                        label: Text(isListening ? 'Stop' : 'Start Speaking'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
