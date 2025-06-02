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
/// import 'gen_l10n/app_localizations.dart';
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

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @noRole.
  ///
  /// In en, this message translates to:
  /// **'No Role'**
  String get noRole;

  /// No description provided for @errorFetchingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while fetching user data.'**
  String get errorFetchingUserData;

  /// No description provided for @failedToLoadRole.
  ///
  /// In en, this message translates to:
  /// **'Failed to load role'**
  String get failedToLoadRole;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @gamesDescription.
  ///
  /// In en, this message translates to:
  /// **'Play brain games'**
  String get gamesDescription;

  /// No description provided for @medicineReminders.
  ///
  /// In en, this message translates to:
  /// **'Medicine Reminders'**
  String get medicineReminders;

  /// No description provided for @medicineRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **''**
  String get medicineRemindersDescription;

  /// No description provided for @memoryAid.
  ///
  /// In en, this message translates to:
  /// **'Memory Aid'**
  String get memoryAid;

  /// No description provided for @memoryAidDescription.
  ///
  /// In en, this message translates to:
  /// **'Remember important things'**
  String get memoryAidDescription;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @chatbotDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat with your friendly bot'**
  String get chatbotDescription;

  /// No description provided for @userDataMissing.
  ///
  /// In en, this message translates to:
  /// **'User data is missing.'**
  String get userDataMissing;

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No user found. Please login.'**
  String get noUserFound;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @medicationReminders.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get medicationReminders;

  /// No description provided for @noMedicationReminders.
  ///
  /// In en, this message translates to:
  /// **'No medication reminders'**
  String get noMedicationReminders;

  /// No description provided for @tapToAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add a reminder'**
  String get tapToAddReminder;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time:'**
  String get time;

  /// No description provided for @recurringReminder.
  ///
  /// In en, this message translates to:
  /// **'Recurring Reminder'**
  String get recurringReminder;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date;

  /// No description provided for @repeatOnDays.
  ///
  /// In en, this message translates to:
  /// **'Repeat on days:'**
  String get repeatOnDays;

  /// No description provided for @addMedicationReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Medication Reminder'**
  String get addMedicationReminder;

  /// No description provided for @editMedicationReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication Reminder'**
  String get editMedicationReminder;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get update;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get add;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @pleaseSelectAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one day'**
  String get pleaseSelectAtLeastOneDay;

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the reminder for'**
  String get deleteReminderContent;

  /// No description provided for @oneTimeAt.
  ///
  /// In en, this message translates to:
  /// **'One time at'**
  String get oneTimeAt;

  /// No description provided for @every.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get every;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @familyTree.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTree;

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addFamilyMember;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @relation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get relation;

  /// No description provided for @selectParentOptional.
  ///
  /// In en, this message translates to:
  /// **'Select Parent (Optional)'**
  String get selectParentOptional;

  /// No description provided for @selectParent.
  ///
  /// In en, this message translates to:
  /// **'Select Parent'**
  String get selectParent;

  /// No description provided for @noParent.
  ///
  /// In en, this message translates to:
  /// **'No Parent'**
  String get noParent;

  /// No description provided for @pleaseFillInAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillInAllFields;

  /// No description provided for @familyMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'Family member added successfully'**
  String get familyMemberAdded;

  /// No description provided for @failedToAddFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to add family member:'**
  String get failedToAddFamilyMember;

  /// No description provided for @failedToLoadFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load family members:'**
  String get failedToLoadFamilyMembers;

  /// No description provided for @noFamilyMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No family members yet. Tap + to add.'**
  String get noFamilyMembersYet;

  /// No description provided for @healthcareChatBot.
  ///
  /// In en, this message translates to:
  /// **'Healthcare ChatBot'**
  String get healthcareChatBot;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @geminiTyping.
  ///
  /// In en, this message translates to:
  /// **'Gemini AI is typing'**
  String get geminiTyping;

  /// No description provided for @errorSendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error sending message. Please check your connection.'**
  String get errorSendingMessage;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayAt;

  /// No description provided for @senderAI.
  ///
  /// In en, this message translates to:
  /// **'Gemini AI'**
  String get senderAI;

  /// No description provided for @senderOffline.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant (Offline)'**
  String get senderOffline;

  /// No description provided for @senderUser.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get senderUser;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'loading...'**
  String get loading;

  /// No description provided for @hey.
  ///
  /// In en, this message translates to:
  /// **'Hey'**
  String get hey;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'how can I help you today?'**
  String get howCanIHelp;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @caregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiver;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get gamesPlayed;

  /// No description provided for @memoryNotes.
  ///
  /// In en, this message translates to:
  /// **'Memory Notes'**
  String get memoryNotes;

  /// No description provided for @noPatientConnected.
  ///
  /// In en, this message translates to:
  /// **'No patient connected'**
  String get noPatientConnected;

  /// No description provided for @noLogsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No logs available.'**
  String get noLogsAvailable;

  /// No description provided for @noActivitiesLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'No activities logged yet'**
  String get noActivitiesLoggedYet;

  /// No description provided for @connectWithCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Connect with a Caregiver'**
  String get connectWithCaregiver;

  /// No description provided for @shareCodeWithCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Share a one-time code with your caregiver to establish a secure connection.'**
  String get shareCodeWithCaregiver;

  /// No description provided for @generateConnectionCode.
  ///
  /// In en, this message translates to:
  /// **'Generate Connection Code'**
  String get generateConnectionCode;

  /// No description provided for @yourCodeIs.
  ///
  /// In en, this message translates to:
  /// **'Your code is:'**
  String get yourCodeIs;

  /// No description provided for @shareThisCodeWithCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your caregiver'**
  String get shareThisCodeWithCaregiver;

  /// No description provided for @connectWithPatient.
  ///
  /// In en, this message translates to:
  /// **'Connect with a Patient'**
  String get connectWithPatient;

  /// No description provided for @enterCodeFromPatient.
  ///
  /// In en, this message translates to:
  /// **'Enter the one-time code provided by your patient to establish a secure connection.'**
  String get enterCodeFromPatient;

  /// No description provided for @enterPatientCode.
  ///
  /// In en, this message translates to:
  /// **'Enter patient code'**
  String get enterPatientCode;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @patientActivity.
  ///
  /// In en, this message translates to:
  /// **'Patient Activity'**
  String get patientActivity;

  /// No description provided for @otpSentToCaregiver.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to caregiver!'**
  String get otpSentToCaregiver;

  /// No description provided for @failedToSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP to caregiver'**
  String get failedToSendOtp;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCode;

  /// No description provided for @connectedToPatientSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected to '**
  String get connectedToPatientSuccess;

  /// No description provided for @successfully.
  ///
  /// In en, this message translates to:
  /// **'successfully!'**
  String get successfully;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get error;

  /// No description provided for @memoryGames.
  ///
  /// In en, this message translates to:
  /// **'Memory Games'**
  String get memoryGames;

  /// No description provided for @speechGame.
  ///
  /// In en, this message translates to:
  /// **'Speech Game'**
  String get speechGame;

  /// No description provided for @sequenceMemory.
  ///
  /// In en, this message translates to:
  /// **'Sequence Memory'**
  String get sequenceMemory;

  /// No description provided for @patternMemory.
  ///
  /// In en, this message translates to:
  /// **'Pattern Memory'**
  String get patternMemory;

  /// No description provided for @nameAnimalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Name an animal that starts with the letter '**
  String get nameAnimalPrompt;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct! You said: '**
  String get correctAnswer;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again! You said: '**
  String get tryAgain;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @tapMicToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to start'**
  String get tapMicToStart;

  /// No description provided for @speechRecognitionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechRecognitionNotAvailable;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get microphonePermissionRequired;

  /// No description provided for @errorDuringSpeechRecognition.
  ///
  /// In en, this message translates to:
  /// **'Error during speech recognition'**
  String get errorDuringSpeechRecognition;

  /// No description provided for @errorInitializingSpeechRecognition.
  ///
  /// In en, this message translates to:
  /// **'Error initializing speech recognition'**
  String get errorInitializingSpeechRecognition;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop Listening'**
  String get stopListening;

  /// No description provided for @startSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Start Speaking'**
  String get startSpeaking;

  /// No description provided for @newQuestion.
  ///
  /// In en, this message translates to:
  /// **'New Question'**
  String get newQuestion;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score:'**
  String get score;

  /// No description provided for @sequenceMemoryGame.
  ///
  /// In en, this message translates to:
  /// **'Sequence Memory Game'**
  String get sequenceMemoryGame;

  /// No description provided for @levelScore.
  ///
  /// In en, this message translates to:
  /// **'Level:'**
  String get levelScore;

  /// No description provided for @watchSequence.
  ///
  /// In en, this message translates to:
  /// **'Watch the sequence...'**
  String get watchSequence;

  /// No description provided for @repeatSequence.
  ///
  /// In en, this message translates to:
  /// **'Repeat the sequence!'**
  String get repeatSequence;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready...'**
  String get getReady;

  /// No description provided for @restartLevel.
  ///
  /// In en, this message translates to:
  /// **'Restart Level'**
  String get restartLevel;

  /// No description provided for @patternMemoryGame.
  ///
  /// In en, this message translates to:
  /// **'Pattern Memory Game'**
  String get patternMemoryGame;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid:'**
  String get grid;

  /// No description provided for @memorizePattern.
  ///
  /// In en, this message translates to:
  /// **'Memorize the pattern...'**
  String get memorizePattern;

  /// No description provided for @recreatePattern.
  ///
  /// In en, this message translates to:
  /// **'Recreate the pattern!'**
  String get recreatePattern;

  /// No description provided for @checkPattern.
  ///
  /// In en, this message translates to:
  /// **'Check Pattern'**
  String get checkPattern;

  /// No description provided for @newPattern.
  ///
  /// In en, this message translates to:
  /// **'New Pattern'**
  String get newPattern;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectYourRole;

  /// No description provided for @imAPatient.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Patient'**
  String get imAPatient;

  /// No description provided for @imACaregiver.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Caregiver'**
  String get imACaregiver;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @checkingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Checking permissions...'**
  String get checkingPermissions;

  /// No description provided for @initializingLanguageDetection.
  ///
  /// In en, this message translates to:
  /// **'Initializing language detection...'**
  String get initializingLanguageDetection;

  /// No description provided for @initializingSpeechRecognition.
  ///
  /// In en, this message translates to:
  /// **'Initializing speech recognition...'**
  String get initializingSpeechRecognition;

  /// No description provided for @configuringTextToSpeech.
  ///
  /// In en, this message translates to:
  /// **'Configuring text-to-speech...'**
  String get configuringTextToSpeech;

  /// No description provided for @readyToListen.
  ///
  /// In en, this message translates to:
  /// **'Ready to listen!'**
  String get readyToListen;

  /// No description provided for @stoppedListening.
  ///
  /// In en, this message translates to:
  /// **'Stopped listening'**
  String get stoppedListening;

  /// No description provided for @speechError.
  ///
  /// In en, this message translates to:
  /// **'Speech error:'**
  String get speechError;

  /// No description provided for @youSaid.
  ///
  /// In en, this message translates to:
  /// **'You said:'**
  String get youSaid;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response:'**
  String get response;

  /// No description provided for @conversationHistory.
  ///
  /// In en, this message translates to:
  /// **'Conversation History'**
  String get conversationHistory;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi (हिंदी)'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi (मराठी)'**
  String get marathi;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @iHearYou.
  ///
  /// In en, this message translates to:
  /// **'I hear you. Please tell me how I can help.'**
  String get iHearYou;

  /// No description provided for @sorryTroubleUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I had trouble understanding. Please try again.'**
  String get sorryTroubleUnderstanding;
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
