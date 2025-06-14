import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// Default text shown when user identity cannot be determined
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// Text displayed when user has no assigned role in the system
  ///
  /// In en, this message translates to:
  /// **'No Role'**
  String get noRole;

  /// Error message shown when user data cannot be retrieved from server
  ///
  /// In en, this message translates to:
  /// **'Error occurred while fetching user data.'**
  String get errorFetchingUserData;

  /// Error message when user role information cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Failed to load role'**
  String get failedToLoadRole;

  /// Navigation menu item for main dashboard page
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Navigation menu item for analytics/statistics page
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Navigation menu item for notifications page
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Navigation menu item for user settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Navigation menu item for help and support section
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Button text for user logout action
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Greeting text displayed to users
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Section header for frequently used features
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// Label for games section or menu item
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// Brief description of the games feature
  ///
  /// In en, this message translates to:
  /// **'Play brain games'**
  String get gamesDescription;

  /// Label for medication reminder feature
  ///
  /// In en, this message translates to:
  /// **'Medicine Reminders'**
  String get medicineReminders;

  /// Brief description of the medicine reminders feature (currently empty)
  ///
  /// In en, this message translates to:
  /// **''**
  String get medicineRemindersDescription;

  /// Label for memory assistance feature
  ///
  /// In en, this message translates to:
  /// **'Memory Aid'**
  String get memoryAid;

  /// Brief description of the memory aid feature
  ///
  /// In en, this message translates to:
  /// **'Remember important things'**
  String get memoryAidDescription;

  /// Label for AI chatbot feature
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// Brief description of the chatbot feature
  ///
  /// In en, this message translates to:
  /// **'Chat with your friendly bot'**
  String get chatbotDescription;

  /// Error message when required user data is not available
  ///
  /// In en, this message translates to:
  /// **'User data is missing.'**
  String get userDataMissing;

  /// Message shown when no authenticated user is detected
  ///
  /// In en, this message translates to:
  /// **'No user found. Please login.'**
  String get noUserFound;

  /// Button text to proceed without authentication
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// Button text for Google authentication
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Button text for Apple authentication
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// Page title for medication reminder management
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get medicationReminders;

  /// Message shown when user has no medication reminders set
  ///
  /// In en, this message translates to:
  /// **'No medication reminders'**
  String get noMedicationReminders;

  /// Instructions for adding new medication reminders
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add a reminder'**
  String get tapToAddReminder;

  /// Label for medication dosage field
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// Label for time selection field
  ///
  /// In en, this message translates to:
  /// **'Time:'**
  String get time;

  /// Label for recurring reminder toggle/option
  ///
  /// In en, this message translates to:
  /// **'Recurring Reminder'**
  String get recurringReminder;

  /// Label for date selection field
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date;

  /// Label for selecting days of the week for recurring reminders
  ///
  /// In en, this message translates to:
  /// **'Repeat on days:'**
  String get repeatOnDays;

  /// Title for add medication reminder form/page
  ///
  /// In en, this message translates to:
  /// **'Add Medication Reminder'**
  String get addMedicationReminder;

  /// Title for edit medication reminder form/page
  ///
  /// In en, this message translates to:
  /// **'Edit Medication Reminder'**
  String get editMedicationReminder;

  /// Label for medication name input field
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// Button text to cancel current action
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// Button text to delete an item
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// Button text to save changes to an existing item
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get update;

  /// Button text to create a new item
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get add;

  /// Validation message when required form fields are empty
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// Validation message for recurring reminders without selected days
  ///
  /// In en, this message translates to:
  /// **'Please select at least one day'**
  String get pleaseSelectAtLeastOneDay;

  /// Title for delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminderTitle;

  /// Confirmation message for deleting medication reminders
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the reminder for'**
  String get deleteReminderContent;

  /// Prefix for displaying one-time reminder schedule
  ///
  /// In en, this message translates to:
  /// **'One time at'**
  String get oneTimeAt;

  /// Prefix for displaying recurring reminder frequency
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get every;

  /// Preposition used in schedule descriptions
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// Preposition used before time in schedule descriptions
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// Title for family tree feature/page
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTree;

  /// Button text or form title for adding family members
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addFamilyMember;

  /// Label for name input field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Label for family relationship selection field
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get relation;

  /// Label for optional parent selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Select Parent (Optional)'**
  String get selectParentOptional;

  /// Label for parent selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Select Parent'**
  String get selectParent;

  /// Option in parent selection for members with no parent
  ///
  /// In en, this message translates to:
  /// **'No Parent'**
  String get noParent;

  /// Validation message for incomplete family member form
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillInAllFields;

  /// Success message after adding a family member
  ///
  /// In en, this message translates to:
  /// **'Family member added successfully'**
  String get familyMemberAdded;

  /// Error message when family member creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add family member:'**
  String get failedToAddFamilyMember;

  /// Error message when family member data cannot be retrieved
  ///
  /// In en, this message translates to:
  /// **'Failed to load family members:'**
  String get failedToLoadFamilyMembers;

  /// Empty state message for family tree with instructions
  ///
  /// In en, this message translates to:
  /// **'No family members yet. Tap + to add.'**
  String get noFamilyMembersYet;

  /// Title for healthcare AI chatbot feature
  ///
  /// In en, this message translates to:
  /// **'Healthcare ChatBot'**
  String get healthcareChatBot;

  /// Status indicator showing chatbot is available
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Status indicator showing chatbot is unavailable
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Placeholder text for chat message input field
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// Status message showing AI is composing a response
  ///
  /// In en, this message translates to:
  /// **'Gemini AI is typing'**
  String get geminiTyping;

  /// Error message when chat message fails to send
  ///
  /// In en, this message translates to:
  /// **'Error sending message. Please check your connection.'**
  String get errorSendingMessage;

  /// Timestamp prefix for messages sent today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayAt;

  /// Display name for AI chatbot messages
  ///
  /// In en, this message translates to:
  /// **'Gemini AI'**
  String get senderAI;

  /// Display name for AI when offline
  ///
  /// In en, this message translates to:
  /// **'AI Assistant (Offline)'**
  String get senderOffline;

  /// Display name for user's own messages
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get senderUser;

  /// Generic loading state message
  ///
  /// In en, this message translates to:
  /// **'loading...'**
  String get loading;

  /// Casual greeting from AI chatbot
  ///
  /// In en, this message translates to:
  /// **'Hey'**
  String get hey;

  /// AI chatbot's offer to assist the user
  ///
  /// In en, this message translates to:
  /// **'how can I help you today?'**
  String get howCanIHelp;

  /// Title for user profile page
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// Label for patient user role
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// Label for caregiver user role
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiver;

  /// Profile statistic showing number of games completed
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get gamesPlayed;

  /// Profile section for user's memory aid notes
  ///
  /// In en, this message translates to:
  /// **'Memory Notes'**
  String get memoryNotes;

  /// Message for caregivers who haven't connected to a patient
  ///
  /// In en, this message translates to:
  /// **'No patient connected'**
  String get noPatientConnected;

  /// Message when no activity logs exist
  ///
  /// In en, this message translates to:
  /// **'No logs available.'**
  String get noLogsAvailable;

  /// Empty state message for activity history
  ///
  /// In en, this message translates to:
  /// **'No activities logged yet'**
  String get noActivitiesLoggedYet;

  /// Feature title for patient-caregiver connection
  ///
  /// In en, this message translates to:
  /// **'Connect with a Caregiver'**
  String get connectWithCaregiver;

  /// Instructions for patients to connect with caregivers
  ///
  /// In en, this message translates to:
  /// **'Share a one-time code with your caregiver to establish a secure connection.'**
  String get shareCodeWithCaregiver;

  /// Button text to create a connection code
  ///
  /// In en, this message translates to:
  /// **'Generate Connection Code'**
  String get generateConnectionCode;

  /// Prefix for displaying generated connection code
  ///
  /// In en, this message translates to:
  /// **'Your code is:'**
  String get yourCodeIs;

  /// Instructions for sharing the connection code
  ///
  /// In en, this message translates to:
  /// **'Share this code with your caregiver'**
  String get shareThisCodeWithCaregiver;

  /// Feature title for caregiver-patient connection
  ///
  /// In en, this message translates to:
  /// **'Connect with a Patient'**
  String get connectWithPatient;

  /// Instructions for caregivers to connect with patients
  ///
  /// In en, this message translates to:
  /// **'Enter the one-time code provided by your patient to establish a secure connection.'**
  String get enterCodeFromPatient;

  /// Label for patient code input field
  ///
  /// In en, this message translates to:
  /// **'Enter patient code'**
  String get enterPatientCode;

  /// Button text to validate connection code
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// Title for patient activity monitoring section
  ///
  /// In en, this message translates to:
  /// **'Patient Activity'**
  String get patientActivity;

  /// Success message when connection code is sent
  ///
  /// In en, this message translates to:
  /// **'OTP sent to caregiver!'**
  String get otpSentToCaregiver;

  /// Error message when connection code cannot be sent
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP to caregiver'**
  String get failedToSendOtp;

  /// Error message for incorrect connection codes
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCode;

  /// First part of success message for patient connection
  ///
  /// In en, this message translates to:
  /// **'Connected to '**
  String get connectedToPatientSuccess;

  /// Second part of success message for patient connection
  ///
  /// In en, this message translates to:
  /// **'successfully!'**
  String get successfully;

  /// Generic error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get error;

  /// Title for memory training games section
  ///
  /// In en, this message translates to:
  /// **'Memory Games'**
  String get memoryGames;

  /// Title for speech-based memory game
  ///
  /// In en, this message translates to:
  /// **'Speech Game'**
  String get speechGame;

  /// Title for the speech-based memory game
  ///
  /// In en, this message translates to:
  /// **'Speech Game'**
  String get speechGameTitle;

  /// Title for sequence memory training game
  ///
  /// In en, this message translates to:
  /// **'Sequence Memory'**
  String get sequenceMemory;

  /// Title for pattern memory training game
  ///
  /// In en, this message translates to:
  /// **'Pattern Memory'**
  String get patternMemory;

  /// Speech game prompt asking user to name an animal
  ///
  /// In en, this message translates to:
  /// **'Name an animal that starts with the letter '**
  String get nameAnimalPrompt;

  /// Positive feedback for correct speech game answers
  ///
  /// In en, this message translates to:
  /// **'Correct! You said: '**
  String get correctAnswer;

  /// Feedback for incorrect speech game answers
  ///
  /// In en, this message translates to:
  /// **'Try again! You said: '**
  String get tryAgain;

  /// Status message during speech recognition
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// Instructions to begin speech recognition
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to start'**
  String get tapMicToStart;

  /// Error message when speech recognition is not supported
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechRecognitionNotAvailable;

  /// Error message when microphone access is denied
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get microphonePermissionRequired;

  /// Generic error message for speech recognition failures
  ///
  /// In en, this message translates to:
  /// **'Error during speech recognition'**
  String get errorDuringSpeechRecognition;

  /// Error message when speech recognition cannot be started
  ///
  /// In en, this message translates to:
  /// **'Error initializing speech recognition'**
  String get errorInitializingSpeechRecognition;

  /// Button text to end speech recognition
  ///
  /// In en, this message translates to:
  /// **'Stop Listening'**
  String get stopListening;

  /// Button text to begin speech recognition
  ///
  /// In en, this message translates to:
  /// **'Start Speaking'**
  String get startSpeaking;

  /// Button text to generate a new game question
  ///
  /// In en, this message translates to:
  /// **'New Question'**
  String get newQuestion;

  /// Label for displaying user's game score
  ///
  /// In en, this message translates to:
  /// **'Score:'**
  String get score;

  /// Full title for sequence memory training game
  ///
  /// In en, this message translates to:
  /// **'Sequence Memory Game'**
  String get sequenceMemoryGame;

  /// Label for displaying current game level
  ///
  /// In en, this message translates to:
  /// **'Level:'**
  String get levelScore;

  /// Instruction to observe the sequence in memory game
  ///
  /// In en, this message translates to:
  /// **'Watch the sequence...'**
  String get watchSequence;

  /// Instruction to reproduce the sequence in memory game
  ///
  /// In en, this message translates to:
  /// **'Repeat the sequence!'**
  String get repeatSequence;

  /// Countdown message before game starts
  ///
  /// In en, this message translates to:
  /// **'Get ready...'**
  String get getReady;

  /// Button text to restart current game level
  ///
  /// In en, this message translates to:
  /// **'Restart Level'**
  String get restartLevel;

  /// Full title for pattern memory training game
  ///
  /// In en, this message translates to:
  /// **'Pattern Memory Game'**
  String get patternMemoryGame;

  /// Label for grid-based game interface
  ///
  /// In en, this message translates to:
  /// **'Grid:'**
  String get grid;

  /// Instruction to study the pattern in memory game
  ///
  /// In en, this message translates to:
  /// **'Memorize the pattern...'**
  String get memorizePattern;

  /// Instruction to reproduce the pattern in memory game
  ///
  /// In en, this message translates to:
  /// **'Recreate the pattern!'**
  String get recreatePattern;

  /// Button text to verify pattern recreation
  ///
  /// In en, this message translates to:
  /// **'Check Pattern'**
  String get checkPattern;

  /// Button text to generate a new pattern
  ///
  /// In en, this message translates to:
  /// **'New Pattern'**
  String get newPattern;

  /// Title for role selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectYourRole;

  /// Button text for selecting patient role
  ///
  /// In en, this message translates to:
  /// **'I\'m a Patient'**
  String get imAPatient;

  /// Button text for selecting caregiver role
  ///
  /// In en, this message translates to:
  /// **'I\'m a Caregiver'**
  String get imACaregiver;

  /// Navigation tab label for home/dashboard screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Navigation tab label for voice assistant feature
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// Navigation tab label for user profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Title for voice-activated AI assistant feature
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// Status message during voice assistant startup
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// Status message during permission verification
  ///
  /// In en, this message translates to:
  /// **'Checking permissions...'**
  String get checkingPermissions;

  /// Status message during language detection setup
  ///
  /// In en, this message translates to:
  /// **'Initializing language detection...'**
  String get initializingLanguageDetection;

  /// Status message during speech recognition setup
  ///
  /// In en, this message translates to:
  /// **'Initializing speech recognition...'**
  String get initializingSpeechRecognition;

  /// Status message during text-to-speech setup
  ///
  /// In en, this message translates to:
  /// **'Configuring text-to-speech...'**
  String get configuringTextToSpeech;

  /// Status message when voice assistant is ready
  ///
  /// In en, this message translates to:
  /// **'Ready to listen!'**
  String get readyToListen;

  /// Status message when voice recognition has ended
  ///
  /// In en, this message translates to:
  /// **'Stopped listening'**
  String get stoppedListening;

  /// Error message prefix for speech recognition failures
  ///
  /// In en, this message translates to:
  /// **'Speech error:'**
  String get speechError;

  /// Prefix for displaying recognized speech text
  ///
  /// In en, this message translates to:
  /// **'You said:'**
  String get youSaid;

  /// Prefix for displaying AI assistant responses
  ///
  /// In en, this message translates to:
  /// **'Response:'**
  String get response;

  /// Title for voice assistant conversation log
  ///
  /// In en, this message translates to:
  /// **'Conversation History'**
  String get conversationHistory;

  /// Button text to begin voice recognition
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Button text to end voice recognition
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Button text to clear conversation history
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Label for language selection setting
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hindi language option with native script
  ///
  /// In en, this message translates to:
  /// **'Hindi (हिंदी)'**
  String get hindi;

  /// Marathi language option with native script
  ///
  /// In en, this message translates to:
  /// **'Marathi (मराठी)'**
  String get marathi;

  /// Label for unidentified or unrecognized items
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Voice assistant acknowledgment and offer to help
  ///
  /// In en, this message translates to:
  /// **'I hear you. Please tell me how I can help.'**
  String get iHearYou;

  /// Voice assistant apology for speech recognition failure
  ///
  /// In en, this message translates to:
  /// **'Sorry, I had trouble understanding. Please try again.'**
  String get sorryTroubleUnderstanding;

  /// Button text or label for connecting to a patient
  ///
  /// In en, this message translates to:
  /// **'Connect to Patient'**
  String get connectedToPatient;

  /// Button text or label for connecting to a caregiver
  ///
  /// In en, this message translates to:
  /// **'Connect to Caregiver'**
  String get connectedToCaregiver;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
