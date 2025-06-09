import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:async';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with TickerProviderStateMixin {
  // Current game type
  GameType currentGame = GameType.speechGame;

  // Speech Game Variables
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String speechText = "Name an animal that starts with the letter B";
  List<String> correctAnswers = [
    "Bear",
    "Baboon",
    "Bat",
    "Bird",
    "Butterfly",
    "Bee",
    "Buffalo",
    "Badger"
  ];
  String listeningStatus = "Tap the microphone to start";
  int speechScore = 0;

  // Memory Sequence Game Variables
  List<int> sequence = [];
  List<int> userSequence = [];
  bool showingSequence = false;
  bool userTurn = false;
  int currentLevel = 1;
  int sequenceIndex = 0;
  int memoryScore = 0;
  Timer? sequenceTimer;

  // Pattern Memory Game Variables
  List<List<bool>> pattern = [];
  List<List<bool>> userPattern = [];
  bool showingPattern = false;
  bool userPatternTurn = false;
  int patternSize = 3;
  int patternScore = 0;
  Timer? patternTimer;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Initialize first sequence game
    generateSequence();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    sequenceTimer?.cancel();
    patternTimer?.cancel();
    speech.stop();
    super.dispose();
  }

  // Speech Game Methods
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
final local = Localizations .of(context, AppLocalizations);
          try {
            await speech.listen(
              onResult: (result) {
                if (result.recognizedWords.isNotEmpty) {
                  setState(() {
                    String recognizedWords = result.recognizedWords;
                    developer.log('Recognized words: $recognizedWords');

                    if (correctAnswers.any((answer) => recognizedWords
                        .toLowerCase()
                        .contains(answer.toLowerCase()))) {
                      speechText = "${local.correctAnswer} $recognizedWords";
                      speechScore++;
                      developer.log('Correct answer detected');
                      // Generate new question
                      Timer(const Duration(seconds: 2), () {
                        generateNewQuestion();
                      });
                    } else {
                      speechText = "${local.tryAgain} $recognizedWords";
                      developer.log('Incorrect answer detected');
                    }
                  });
                }
              },
              listenFor: const Duration(seconds: 10),
              listenMode: stt.ListenMode.confirmation,
              onSoundLevelChange: (level) {
                if (mounted && isListening) {
                  developer.log('Sound level: $level');
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
    final local = Localizations.of(context, AppLocalizations);
    try {
      await speech.stop();
      if (mounted) {
        setState(() {
          isListening = false;
          listeningStatus = local.tapMicToStart;
        });
      }
      developer.log('Speech recognition stopped');
    } catch (e) {
      developer.log('Error stopping speech recognition: $e');
    }
  }

  void generateNewQuestion() {
    List<String> letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    Map<String, List<String>> animalsByLetter = {
      'A': ['Ant', 'Alligator', 'Ape', 'Armadillo'],
      'B': [
        'Bear',
        'Baboon',
        'Bat',
        'Bird',
        'Butterfly',
        'Bee',
        'Buffalo',
        'Badger'
      ],
      'C': ['Cat', 'Cow', 'Chicken', 'Cheetah', 'Crab', 'Crocodile'],
      'D': ['Dog', 'Duck', 'Dolphin', 'Deer', 'Dragon'],
      'E': ['Elephant', 'Eagle', 'Eel', 'Emu'],
      'F': ['Fish', 'Frog', 'Fox', 'Flamingo'],
      'G': ['Giraffe', 'Goat', 'Gorilla', 'Goose'],
      'H': ['Horse', 'Hippo', 'Hamster', 'Hawk'],
    };
final local = Localizations.of(context, AppLocalizations);
    String randomLetter = letters[Random().nextInt(letters.length)];
    setState(() {
      speechText = "${local.nameAnimalPrompt} $randomLetter";
      correctAnswers = animalsByLetter[randomLetter] ?? [];
    });
  }

  // Memory Sequence Game Methods
  void generateSequence() {
    setState(() {
      sequence.clear();
      userSequence.clear();
      for (int i = 0; i < currentLevel + 2; i++) {
        sequence.add(Random().nextInt(4));
      }
      sequenceIndex = 0;
      showingSequence = true;
      userTurn = false;
    });
    playSequence();
  }

  void playSequence() {
    sequenceTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (sequenceIndex < sequence.length) {
        setState(() {
          sequenceIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          showingSequence = false;
          userTurn = true;
          sequenceIndex = 0;
        });
      }
    });
  }

  void onSequenceButtonPressed(int buttonIndex) {
    if (!userTurn) return;

    setState(() {
      userSequence.add(buttonIndex);
    });

    _pulseController.forward().then((_) => _pulseController.reverse());

    if (userSequence.length == sequence.length) {
      checkSequence();
    } else if (userSequence[userSequence.length - 1] !=
        sequence[userSequence.length - 1]) {
      // Wrong button pressed
      resetSequenceGame();
    }
  }

  void checkSequence() {
    bool correct = true;
    for (int i = 0; i < sequence.length; i++) {
      if (userSequence[i] != sequence[i]) {
        correct = false;
        break;
      }
    }

    if (correct) {
      setState(() {
        memoryScore++;
        currentLevel++;
        userTurn = false;
      });

      Timer(const Duration(seconds: 1), () {
        generateSequence();
      });
    } else {
      resetSequenceGame();
    }
  }

  void resetSequenceGame() {
    setState(() {
      currentLevel = 1;
      memoryScore = 0;
      userTurn = false;
    });
    Timer(const Duration(seconds: 1), () {
      generateSequence();
    });
  }

  // Pattern Memory Game Methods
  void generatePattern() {
    setState(() {
      pattern = List.generate(patternSize,
          (i) => List.generate(patternSize, (j) => Random().nextBool()));
      userPattern = List.generate(
          patternSize, (i) => List.generate(patternSize, (j) => false));
      showingPattern = true;
      userPatternTurn = false;
    });

    patternTimer = Timer(Duration(seconds: 2 + patternSize), () {
      setState(() {
        showingPattern = false;
        userPatternTurn = true;
      });
    });
  }

  void onPatternTilePressed(int row, int col) {
    if (!userPatternTurn) return;

    setState(() {
      userPattern[row][col] = !userPattern[row][col];
    });
  }

  void checkPattern() {
    bool correct = true;
    for (int i = 0; i < patternSize; i++) {
      for (int j = 0; j < patternSize; j++) {
        if (pattern[i][j] != userPattern[i][j]) {
          correct = false;
          break;
        }
      }
      if (!correct) break;
    }

    if (correct) {
      setState(() {
        patternScore++;
        if (patternScore % 3 == 0 && patternSize < 6) {
          patternSize++;
        }
      });
      Timer(const Duration(seconds: 1), () {
        generatePattern();
      });
    } else {
      setState(() {
        patternSize = 3;
        patternScore = 0;
      });
      Timer(const Duration(seconds: 1), () {
        generatePattern();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final local = Localizations.of(context, AppLocalizations);
  
    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title:  Text(
          local.memoryGames,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.8,
            fontFamily: GoogleFonts.nunito().fontFamily,
          ),
        ),
        centerTitle: true,
        actions: [
          Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: colorScheme.surface, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
          child: PopupMenuButton<GameType>(
            icon:  Icon(Icons.games, color:colorScheme.onSurface),
            onSelected: (GameType type) {
              setState(() {
                currentGame = type;
                if (type == GameType.sequenceGame && sequence.isEmpty) {
                  generateSequence();
                } else if (type == GameType.patternGame && pattern.isEmpty) {
                  generatePattern();
                }
              });
            },
            itemBuilder: (BuildContext context) => [
               PopupMenuItem(
                value: GameType.speechGame,
                child: Text(local.speechGame, 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontFamily: GoogleFonts.nunito().fontFamily) ,
                ),
              ),
              PopupMenuItem(
                value: GameType.sequenceGame,
                child: Text(local.sequenceMemory,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface,fontFamily: GoogleFonts.nunito().fontFamily),),
              ),
               PopupMenuItem(
                value: GameType.patternGame,
                child: Text(local.patternMemory,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontFamily: GoogleFonts.nunito().fontFamily),),
              ),
            ],
          ),
        ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          /*gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),*/
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildGameSelector(),
                  const SizedBox(height: 20),
                  _buildCurrentGame(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameSelector() {
    final local = Localizations.of(context, AppLocalizations);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 150,
      //padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.8),
        /*gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),*/
        borderRadius: BorderRadius.circular(20),
        //border: Border.all(color: colorScheme.primary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGameButton(
              local.speechGameTitle, GameType.speechGame, Icons.mic, speechScore),
          _buildGameButton(local.sequenceMemoryTitle, GameType.sequenceGame,
              Icons.psychology, memoryScore),
          _buildGameButton(local.patternMemoryTitle, GameType.patternGame,
              Icons.grid_3x3, patternScore),
        ],
      ),
    );
  }

  Widget _buildGameButton(

      String title, GameType type, IconData icon, int score) {
        final colorScheme = Theme.of(context).colorScheme;
    final local = Localizations.of(context, AppLocalizations);
    final textTheme = Theme.of(context).textTheme;
    bool isActive = currentGame == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentGame = type;
          if (type == GameType.sequenceGame && sequence.isEmpty) {
            generateSequence();
          } else if (type == GameType.patternGame && pattern.isEmpty) {
            generatePattern();
          }
        });
      },
      child: Container(
        height: 140,
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary.withOpacity(0.1) : colorScheme.tertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.tertiary,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isActive ?  colorScheme.primary : colorScheme.tertiary, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? colorScheme.primary : colorScheme.tertiary ,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${local.score} $score',
              style: TextStyle(
                color: isActive?  colorScheme.primary: colorScheme.tertiary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentGame() {
    switch (currentGame) {
      case GameType.speechGame:
        return _buildSpeechGame();
      case GameType.sequenceGame:
        return _buildSequenceGame();
      case GameType.patternGame:
        return _buildPatternGame();
    }
  }

  Widget _buildSpeechGame() {
    final local = Localizations.of(context, AppLocalizations);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
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
        children: [
          Text(
            speechText,
            style:  TextStyle(
              fontSize: 24,
              color: colorScheme.onSurface ,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            listeningStatus,
            style: TextStyle(
              fontSize: 16,
              color: isListening ? colorScheme.secondary : colorScheme.tertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${local.score} $speechScore',
            style:  TextStyle(
              fontSize: 18,
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              if (isListening)
                AnimatedContainer(
                  duration:  Duration(milliseconds: 300),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: isListening ? stopListening : startListening,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: isListening ?  colorScheme.primary : colorScheme.tertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: Icon(isListening ? Icons.mic_off : Icons.mic, size: 28, color: isListening? colorScheme.onPrimary:colorScheme.surface),
                label: Text(
                  isListening ? local.stopListening : local.startListening,
                  style:  TextStyle(fontSize: 16, color: isListening? colorScheme.onPrimary:colorScheme.surface , fontWeight: FontWeight.bold, fontFamily: GoogleFonts.nunito().fontFamily,)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: generateNewQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child:  Text(local.newQuestion),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceGame() {
    final local = Localizations.of(context, AppLocalizations);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
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
        children: [
          Text(
           local.sequenceMemoryGame,
            style:  TextStyle(
              fontSize: 22,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${local.level} $currentLevel |${local.score} $memoryScore',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            showingSequence
                ? local.watchSequence
                : userTurn
                    ? local.repeatSequence
                    : local.getReady,
            style:  TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 30),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              bool isHighlighted = showingSequence &&
                  sequenceIndex > 0 &&
                  sequenceIndex <= sequence.length &&
                  sequence[sequenceIndex - 1] == index;

              bool isUserPressed = userSequence.contains(index) &&
                  userSequence.last == index &&
                  userTurn;

              Color buttonColor = isHighlighted
                  ? _getSequenceColor(index).withOpacity(0.8)
                  : isUserPressed
                      ? _getSequenceColor(index).withOpacity(0.6)
                      : _getSequenceColor(index).withOpacity(0.3);

              return AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isUserPressed ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: () => onSequenceButtonPressed(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: buttonColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white24),
                          boxShadow: isHighlighted || isUserPressed
                              ? [
                                  BoxShadow(
                                    color: _getSequenceColor(index)
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              sequenceTimer?.cancel();
              generateSequence();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child:  Text(local.restartLevel, style: TextStyle(fontSize: 16, color: colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternGame() {
    final local = Localizations.of(context, AppLocalizations);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
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
        children: [
          Text(
            local.patternMemoryGame,
            style:  TextStyle(
              fontSize: 22,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${local.grid} ${patternSize}x$patternSize | ${local.score} $patternScore',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            showingPattern
                ? local.memorizePattern
                : userPatternTurn
                    ? local.recreatePattern
                    : local.getReady,
            style:  TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 30),
          if (pattern.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: patternSize,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 1,
              ),
              itemCount: patternSize * patternSize,
              itemBuilder: (context, index) {
                int row = index ~/ patternSize;
                int col = index % patternSize;

                bool shouldShow =
                    showingPattern ? pattern[row][col] : userPattern[row][col];

                return GestureDetector(
                  onTap: () => onPatternTilePressed(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      color: shouldShow ? colorScheme.tertiary : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: userPatternTurn ? checkPattern : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:  Text(local.checkPattern, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  patternTimer?.cancel();
                  generatePattern();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.tertiary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(local.newPattern, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.surface)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSequenceColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}

enum GameType {
  speechGame,
  sequenceGame,
  patternGame,
}
