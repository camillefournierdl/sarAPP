import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'system default'**
  String get languageSystem;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'daily reminder'**
  String get reminderChannelName;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'time to log your day'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'how are you feeling today?'**
  String get reminderBody;

  /// No description provided for @onboardingQuestion.
  ///
  /// In en, this message translates to:
  /// **'what do you want to track in sarapp?'**
  String get onboardingQuestion;

  /// No description provided for @onboardingHint.
  ///
  /// In en, this message translates to:
  /// **'these are just starting points. you can turn modules on or off, edit each option and question, or create your own modules at any time in settings.'**
  String get onboardingHint;

  /// No description provided for @onboardingMenstrualTitle.
  ///
  /// In en, this message translates to:
  /// **'menstrual tracking'**
  String get onboardingMenstrualTitle;

  /// No description provided for @onboardingMenstrualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'cycle phases, period symptoms, mood & libido'**
  String get onboardingMenstrualSubtitle;

  /// No description provided for @onboardingChronicTitle.
  ///
  /// In en, this message translates to:
  /// **'chronic symptoms'**
  String get onboardingChronicTitle;

  /// No description provided for @onboardingChronicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'symptoms, pain, sleep, stress & possible triggers'**
  String get onboardingChronicSubtitle;

  /// No description provided for @onboardingMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'mood & habit tracking'**
  String get onboardingMoodTitle;

  /// No description provided for @onboardingMoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'emotions, stress, sleep, activities & substances'**
  String get onboardingMoodSubtitle;

  /// No description provided for @onboardingScratchTitle.
  ///
  /// In en, this message translates to:
  /// **'start from scratch'**
  String get onboardingScratchTitle;

  /// No description provided for @onboardingScratchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'a blank slate: add only what you need in settings'**
  String get onboardingScratchSubtitle;

  /// No description provided for @optHappy.
  ///
  /// In en, this message translates to:
  /// **'😊 happy'**
  String get optHappy;

  /// No description provided for @optSad.
  ///
  /// In en, this message translates to:
  /// **'😢 sad'**
  String get optSad;

  /// No description provided for @optAngry.
  ///
  /// In en, this message translates to:
  /// **'😤 angry'**
  String get optAngry;

  /// No description provided for @optAnxious.
  ///
  /// In en, this message translates to:
  /// **'😰 anxious'**
  String get optAnxious;

  /// No description provided for @optTired.
  ///
  /// In en, this message translates to:
  /// **'😴 tired'**
  String get optTired;

  /// No description provided for @optEnergized.
  ///
  /// In en, this message translates to:
  /// **'⚡ energized'**
  String get optEnergized;

  /// No description provided for @optDayOff.
  ///
  /// In en, this message translates to:
  /// **'🌿 day off'**
  String get optDayOff;

  /// No description provided for @optHalfDay.
  ///
  /// In en, this message translates to:
  /// **'🌗 half day'**
  String get optHalfDay;

  /// No description provided for @optFullDay.
  ///
  /// In en, this message translates to:
  /// **'💼 full day'**
  String get optFullDay;

  /// No description provided for @optWeightLifting.
  ///
  /// In en, this message translates to:
  /// **'🏋️ weight lifting'**
  String get optWeightLifting;

  /// No description provided for @optIntenseCardio.
  ///
  /// In en, this message translates to:
  /// **'🏃 intense cardio'**
  String get optIntenseCardio;

  /// No description provided for @optEndurance.
  ///
  /// In en, this message translates to:
  /// **'🚴 endurance'**
  String get optEndurance;

  /// No description provided for @optDance.
  ///
  /// In en, this message translates to:
  /// **'💃 dance'**
  String get optDance;

  /// No description provided for @optClimbing.
  ///
  /// In en, this message translates to:
  /// **'🧗 climbing'**
  String get optClimbing;

  /// No description provided for @optReading.
  ///
  /// In en, this message translates to:
  /// **'📖 reading'**
  String get optReading;

  /// No description provided for @optGardening.
  ///
  /// In en, this message translates to:
  /// **'🌱 gardening'**
  String get optGardening;

  /// No description provided for @optBoardGames.
  ///
  /// In en, this message translates to:
  /// **'🎲 board games'**
  String get optBoardGames;

  /// No description provided for @optGaming.
  ///
  /// In en, this message translates to:
  /// **'🎮 gaming'**
  String get optGaming;

  /// No description provided for @optMusicPractice.
  ///
  /// In en, this message translates to:
  /// **'🎵 music (practice)'**
  String get optMusicPractice;

  /// No description provided for @optMusicGroup.
  ///
  /// In en, this message translates to:
  /// **'🎶 music (group)'**
  String get optMusicGroup;

  /// No description provided for @optGluten.
  ///
  /// In en, this message translates to:
  /// **'🌾 gluten'**
  String get optGluten;

  /// No description provided for @optLactose.
  ///
  /// In en, this message translates to:
  /// **'🥛 lactose'**
  String get optLactose;

  /// No description provided for @optSugars.
  ///
  /// In en, this message translates to:
  /// **'🍬 sugars'**
  String get optSugars;

  /// No description provided for @optChicken.
  ///
  /// In en, this message translates to:
  /// **'🍗 chicken'**
  String get optChicken;

  /// No description provided for @optRedMeat.
  ///
  /// In en, this message translates to:
  /// **'🥩 red meat'**
  String get optRedMeat;

  /// No description provided for @optOtherMeat.
  ///
  /// In en, this message translates to:
  /// **'🍖 other meat'**
  String get optOtherMeat;

  /// No description provided for @optFish.
  ///
  /// In en, this message translates to:
  /// **'🐟 fish'**
  String get optFish;

  /// No description provided for @optAlcohol.
  ///
  /// In en, this message translates to:
  /// **'🍷 alcohol'**
  String get optAlcohol;

  /// No description provided for @optCaffeine.
  ///
  /// In en, this message translates to:
  /// **'☕ caffeine'**
  String get optCaffeine;

  /// No description provided for @optNicotine.
  ///
  /// In en, this message translates to:
  /// **'🚬 nicotine'**
  String get optNicotine;

  /// No description provided for @optCannabis.
  ///
  /// In en, this message translates to:
  /// **'🌿 cannabis'**
  String get optCannabis;

  /// No description provided for @optMedication.
  ///
  /// In en, this message translates to:
  /// **'💊 medication'**
  String get optMedication;

  /// No description provided for @optCramps.
  ///
  /// In en, this message translates to:
  /// **'cramps'**
  String get optCramps;

  /// No description provided for @optBloating.
  ///
  /// In en, this message translates to:
  /// **'bloating'**
  String get optBloating;

  /// No description provided for @optHeadache.
  ///
  /// In en, this message translates to:
  /// **'headache'**
  String get optHeadache;

  /// No description provided for @optFatigue.
  ///
  /// In en, this message translates to:
  /// **'fatigue'**
  String get optFatigue;

  /// No description provided for @optMoodSwings.
  ///
  /// In en, this message translates to:
  /// **'mood swings'**
  String get optMoodSwings;

  /// No description provided for @optBreastTenderness.
  ///
  /// In en, this message translates to:
  /// **'breast tenderness'**
  String get optBreastTenderness;

  /// No description provided for @optBackPain.
  ///
  /// In en, this message translates to:
  /// **'back pain'**
  String get optBackPain;

  /// No description provided for @optAcne.
  ///
  /// In en, this message translates to:
  /// **'acne'**
  String get optAcne;

  /// No description provided for @optPain.
  ///
  /// In en, this message translates to:
  /// **'⚡ pain'**
  String get optPain;

  /// No description provided for @optJointPain.
  ///
  /// In en, this message translates to:
  /// **'🦴 joint pain'**
  String get optJointPain;

  /// No description provided for @optHeadacheMigraine.
  ///
  /// In en, this message translates to:
  /// **'🤕 headache / migraine'**
  String get optHeadacheMigraine;

  /// No description provided for @optBrainFog.
  ///
  /// In en, this message translates to:
  /// **'🌫️ brain fog'**
  String get optBrainFog;

  /// No description provided for @optDizziness.
  ///
  /// In en, this message translates to:
  /// **'💫 dizziness'**
  String get optDizziness;

  /// No description provided for @optInsomnia.
  ///
  /// In en, this message translates to:
  /// **'😵 insomnia'**
  String get optInsomnia;

  /// No description provided for @optHealthy.
  ///
  /// In en, this message translates to:
  /// **'healthy'**
  String get optHealthy;

  /// No description provided for @optSick.
  ///
  /// In en, this message translates to:
  /// **'sick'**
  String get optSick;

  /// No description provided for @optCold.
  ///
  /// In en, this message translates to:
  /// **'🤧 cold'**
  String get optCold;

  /// No description provided for @optFlu.
  ///
  /// In en, this message translates to:
  /// **'🤒 flu'**
  String get optFlu;

  /// No description provided for @optNausea.
  ///
  /// In en, this message translates to:
  /// **'🤢 nausea'**
  String get optNausea;

  /// No description provided for @optHeadacheSick.
  ///
  /// In en, this message translates to:
  /// **'🤕 headache'**
  String get optHeadacheSick;

  /// No description provided for @optFever.
  ///
  /// In en, this message translates to:
  /// **'🔥 fever'**
  String get optFever;

  /// No description provided for @optDigestive.
  ///
  /// In en, this message translates to:
  /// **'🫄 digestive issues'**
  String get optDigestive;

  /// No description provided for @optFatigueSick.
  ///
  /// In en, this message translates to:
  /// **'😮‍💨 fatigue'**
  String get optFatigueSick;

  /// No description provided for @optYes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get optYes;

  /// No description provided for @optNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get optNo;

  /// No description provided for @modHappiness.
  ///
  /// In en, this message translates to:
  /// **'happiness'**
  String get modHappiness;

  /// No description provided for @modEmotions.
  ///
  /// In en, this message translates to:
  /// **'emotions'**
  String get modEmotions;

  /// No description provided for @modSleep.
  ///
  /// In en, this message translates to:
  /// **'sleep'**
  String get modSleep;

  /// No description provided for @modStress.
  ///
  /// In en, this message translates to:
  /// **'stress'**
  String get modStress;

  /// No description provided for @modWeather.
  ///
  /// In en, this message translates to:
  /// **'weather'**
  String get modWeather;

  /// No description provided for @modHealth.
  ///
  /// In en, this message translates to:
  /// **'health'**
  String get modHealth;

  /// No description provided for @modWork.
  ///
  /// In en, this message translates to:
  /// **'work'**
  String get modWork;

  /// No description provided for @modSports.
  ///
  /// In en, this message translates to:
  /// **'sports'**
  String get modSports;

  /// No description provided for @modLeisure.
  ///
  /// In en, this message translates to:
  /// **'leisure activities'**
  String get modLeisure;

  /// No description provided for @modFood.
  ///
  /// In en, this message translates to:
  /// **'food'**
  String get modFood;

  /// No description provided for @modSubstances.
  ///
  /// In en, this message translates to:
  /// **'substances'**
  String get modSubstances;

  /// No description provided for @modSymptoms.
  ///
  /// In en, this message translates to:
  /// **'symptoms'**
  String get modSymptoms;

  /// No description provided for @modLibido.
  ///
  /// In en, this message translates to:
  /// **'libido'**
  String get modLibido;

  /// No description provided for @modSex.
  ///
  /// In en, this message translates to:
  /// **'sex'**
  String get modSex;

  /// No description provided for @modWater.
  ///
  /// In en, this message translates to:
  /// **'water intake'**
  String get modWater;

  /// No description provided for @modNotes.
  ///
  /// In en, this message translates to:
  /// **'notes'**
  String get modNotes;

  /// No description provided for @modHappinessDesc.
  ///
  /// In en, this message translates to:
  /// **'daily happiness scale (0 – 10)'**
  String get modHappinessDesc;

  /// No description provided for @modEmotionsDesc.
  ///
  /// In en, this message translates to:
  /// **'how did you feel today?'**
  String get modEmotionsDesc;

  /// No description provided for @modSleepDesc.
  ///
  /// In en, this message translates to:
  /// **'sleep quality scale (0 – 10)'**
  String get modSleepDesc;

  /// No description provided for @modStressDesc.
  ///
  /// In en, this message translates to:
  /// **'stress level (0 – 10)'**
  String get modStressDesc;

  /// No description provided for @modWeatherDesc.
  ///
  /// In en, this message translates to:
  /// **'weather rating scale (0 – 10)'**
  String get modWeatherDesc;

  /// No description provided for @modHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'how did you feel physically today?'**
  String get modHealthDesc;

  /// No description provided for @modWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'work day type'**
  String get modWorkDesc;

  /// No description provided for @modSportsDesc.
  ///
  /// In en, this message translates to:
  /// **'physical sport tracking'**
  String get modSportsDesc;

  /// No description provided for @modLeisureDesc.
  ///
  /// In en, this message translates to:
  /// **'other activity tracking'**
  String get modLeisureDesc;

  /// No description provided for @modFoodDesc.
  ///
  /// In en, this message translates to:
  /// **'food category selection'**
  String get modFoodDesc;

  /// No description provided for @modSubstancesDesc.
  ///
  /// In en, this message translates to:
  /// **'alcohol, caffeine, nicotine & more'**
  String get modSubstancesDesc;

  /// No description provided for @modSymptomsDesc.
  ///
  /// In en, this message translates to:
  /// **'chronic symptom tracking'**
  String get modSymptomsDesc;

  /// No description provided for @modLibidoDesc.
  ///
  /// In en, this message translates to:
  /// **'libido level (0 – 10)'**
  String get modLibidoDesc;

  /// No description provided for @modSexDesc.
  ///
  /// In en, this message translates to:
  /// **'had sex today?'**
  String get modSexDesc;

  /// No description provided for @modWaterDesc.
  ///
  /// In en, this message translates to:
  /// **'glasses of water today (0 – 10)'**
  String get modWaterDesc;

  /// No description provided for @modNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'free-text notes'**
  String get modNotesDesc;

  /// No description provided for @healthFollowupQuestion.
  ///
  /// In en, this message translates to:
  /// **'what was wrong? (optional)'**
  String get healthFollowupQuestion;

  /// No description provided for @phaseMenstruation.
  ///
  /// In en, this message translates to:
  /// **'menstruation'**
  String get phaseMenstruation;

  /// No description provided for @phaseFollicular.
  ///
  /// In en, this message translates to:
  /// **'follicular'**
  String get phaseFollicular;

  /// No description provided for @phaseHighFertility.
  ///
  /// In en, this message translates to:
  /// **'higher fertility'**
  String get phaseHighFertility;

  /// No description provided for @phaseOvulation.
  ///
  /// In en, this message translates to:
  /// **'ovulation'**
  String get phaseOvulation;

  /// No description provided for @phaseLuteal.
  ///
  /// In en, this message translates to:
  /// **'luteal'**
  String get phaseLuteal;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get cancel;

  /// No description provided for @noEntriesToExport.
  ///
  /// In en, this message translates to:
  /// **'no entries to export yet.'**
  String get noEntriesToExport;

  /// No description provided for @backupReadError.
  ///
  /// In en, this message translates to:
  /// **'could not read this backup file.'**
  String get backupReadError;

  /// No description provided for @importBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'import backup?'**
  String get importBackupTitle;

  /// No description provided for @importBackupBody.
  ///
  /// In en, this message translates to:
  /// **'this will import {count, plural, =1{1 entry} other{{count} entries}} and restore your modules, options, and preferences from the backup.\n\nentries already logged on the same dates will be overwritten. this cannot be undone.'**
  String importBackupBody(int count);

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'import'**
  String get importAction;

  /// No description provided for @importedEntries.
  ///
  /// In en, this message translates to:
  /// **'imported {count, plural, =1{1 entry} other{{count} entries}}.'**
  String importedEntries(int count);

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'monday'**
  String get monday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'sunday'**
  String get sunday;

  /// No description provided for @weekStartsOn.
  ///
  /// In en, this message translates to:
  /// **'week starts on'**
  String get weekStartsOn;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'notifications are blocked. allow them in system settings to get reminders.'**
  String get notificationsBlocked;

  /// No description provided for @pickReminderTime.
  ///
  /// In en, this message translates to:
  /// **'pick reminder time'**
  String get pickReminderTime;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'reset all data?'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'this will permanently delete all your logged entries and clear your cycle baseline. your tracking mode will be kept.\n\nthis cannot be undone.'**
  String get resetBody;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'delete everything'**
  String get deleteEverything;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'all data deleted.'**
  String get allDataDeleted;

  /// No description provided for @sectionModules.
  ///
  /// In en, this message translates to:
  /// **'questionnaire modules'**
  String get sectionModules;

  /// No description provided for @modulesActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String modulesActive(int count);

  /// No description provided for @customizeModules.
  ///
  /// In en, this message translates to:
  /// **'customize modules'**
  String get customizeModules;

  /// No description provided for @customizeModulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'edit question, options, or delete'**
  String get customizeModulesSubtitle;

  /// No description provided for @sectionTracking.
  ///
  /// In en, this message translates to:
  /// **'tracking'**
  String get sectionTracking;

  /// No description provided for @menstruationTracking.
  ///
  /// In en, this message translates to:
  /// **'menstruation tracking'**
  String get menstruationTracking;

  /// No description provided for @menstruationTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'enable cycle phases, period dates & symptoms'**
  String get menstruationTrackingSubtitle;

  /// No description provided for @sectionCycle.
  ///
  /// In en, this message translates to:
  /// **'cycle'**
  String get sectionCycle;

  /// No description provided for @showFertility.
  ///
  /// In en, this message translates to:
  /// **'show higher-fertility window'**
  String get showFertility;

  /// No description provided for @showFertilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'highlights the ~5 days of elevated fertility around ovulation'**
  String get showFertilitySubtitle;

  /// No description provided for @showIntimacy.
  ///
  /// In en, this message translates to:
  /// **'show intimacy'**
  String get showIntimacy;

  /// No description provided for @showIntimacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'a pink dot indicates tracked activity in the calendar'**
  String get showIntimacySubtitle;

  /// No description provided for @sectionReminder.
  ///
  /// In en, this message translates to:
  /// **'reminder'**
  String get sectionReminder;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'daily reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'get a nudge to log your day'**
  String get dailyReminderSubtitle;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'reminder time'**
  String get reminderTime;

  /// No description provided for @sectionData.
  ///
  /// In en, this message translates to:
  /// **'data'**
  String get sectionData;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'export to CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'share or save your data'**
  String get exportCsvSubtitle;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'reset all data'**
  String get resetAllData;

  /// No description provided for @resetAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'delete all entries and cycle baseline'**
  String get resetAllDataSubtitle;

  /// No description provided for @sectionAnalytics.
  ///
  /// In en, this message translates to:
  /// **'analytics'**
  String get sectionAnalytics;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'insights & correlations'**
  String get insightsTitle;

  /// No description provided for @insightsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'coming in a future version: see how your mood, sleep and symptoms relate to each other.'**
  String get insightsComingSoon;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'about'**
  String get sectionAbout;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'about sarapp'**
  String get aboutApp;

  /// No description provided for @aboutAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'what this app is and how it works'**
  String get aboutAppSubtitle;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'advanced'**
  String get advanced;

  /// No description provided for @advancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'backup & restore'**
  String get advancedSubtitle;

  /// No description provided for @advancedSubtitleNerd.
  ///
  /// In en, this message translates to:
  /// **'nerd mode, developer tools & backup'**
  String get advancedSubtitleNerd;

  /// No description provided for @backupJson.
  ///
  /// In en, this message translates to:
  /// **'backup data (JSON)'**
  String get backupJson;

  /// No description provided for @backupJsonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'full backup — use to move to a new install'**
  String get backupJsonSubtitle;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'import backup'**
  String get importBackup;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'restore entries and settings from a JSON backup'**
  String get importBackupSubtitle;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @daysDefault.
  ///
  /// In en, this message translates to:
  /// **'{count} days (default)'**
  String daysDefault(int count);

  /// No description provided for @cycleNoteDefault.
  ///
  /// In en, this message translates to:
  /// **'log at least 2 period starts to personalise'**
  String get cycleNoteDefault;

  /// No description provided for @cycleNoteBased.
  ///
  /// In en, this message translates to:
  /// **'based on {count, plural, =1{1 cycle} other{{count} cycles}}'**
  String cycleNoteBased(int count);

  /// No description provided for @periodNoteDefault.
  ///
  /// In en, this message translates to:
  /// **'log a period start + end to personalise'**
  String get periodNoteDefault;

  /// No description provided for @periodNoteBased.
  ///
  /// In en, this message translates to:
  /// **'based on {count, plural, =1{1 period} other{{count} periods}}'**
  String periodNoteBased(int count);

  /// No description provided for @cycleStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'your cycle statistics'**
  String get cycleStatsTitle;

  /// No description provided for @cycleLength.
  ///
  /// In en, this message translates to:
  /// **'cycle length'**
  String get cycleLength;

  /// No description provided for @periodLength.
  ///
  /// In en, this message translates to:
  /// **'period length'**
  String get periodLength;

  /// No description provided for @estimatedPhases.
  ///
  /// In en, this message translates to:
  /// **'estimated phases'**
  String get estimatedPhases;

  /// No description provided for @lutealFixedNote.
  ///
  /// In en, this message translates to:
  /// **'luteal phase is fixed at 14 days (scientifically constant).'**
  String get lutealFixedNote;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'v0.1 · free, open-source, and made with ❤️'**
  String get aboutTagline;

  /// No description provided for @aboutTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'track what you choose'**
  String get aboutTrackTitle;

  /// No description provided for @aboutTrackBody.
  ///
  /// In en, this message translates to:
  /// **'sarapp lets you track different dimensions of your day. everyone is different. you decide what dimensions matter to you. enable or disable any module at any time in settings. there is no required field.'**
  String get aboutTrackBody;

  /// No description provided for @aboutDataTitle.
  ///
  /// In en, this message translates to:
  /// **'your data, your device'**
  String get aboutDataTitle;

  /// No description provided for @aboutDataBody.
  ///
  /// In en, this message translates to:
  /// **'everything you log stays on your phone. no account, no cloud sync. your data is stored locally in a private database and can be exported to a CSV whenever you want.'**
  String get aboutDataBody;

  /// No description provided for @aboutOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'free and open-source'**
  String get aboutOpenTitle;

  /// No description provided for @aboutOpenBody.
  ///
  /// In en, this message translates to:
  /// **'sarapp is free to use and its source code is open. you can inspect exactly what it does, contribute improvements, or adapt it for your own needs.'**
  String get aboutOpenBody;

  /// No description provided for @aboutMedicalTitle.
  ///
  /// In en, this message translates to:
  /// **'built on science and community but...'**
  String get aboutMedicalTitle;

  /// No description provided for @aboutMedicalBody.
  ///
  /// In en, this message translates to:
  /// **'cycle phases and fertile days shown in sarapp are estimates based on science and what you log. they are not reliable enough to use as contraception or to plan a pregnancy, and sarapp is not a medical device. talk to a healthcare professional about any health concerns.'**
  String get aboutMedicalBody;

  /// No description provided for @aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'data always stays on your device.'**
  String get aboutFooter;

  /// No description provided for @modulesReorderHint.
  ///
  /// In en, this message translates to:
  /// **'drag (press long) to reorder. tap ✏️ to customise.'**
  String get modulesReorderHint;

  /// No description provided for @editModule.
  ///
  /// In en, this message translates to:
  /// **'edit module'**
  String get editModule;

  /// No description provided for @removeModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'remove \"{name}\"?'**
  String removeModuleTitle(String name);

  /// No description provided for @removeModuleBody.
  ///
  /// In en, this message translates to:
  /// **'this module will be removed from your questionnaire. past responses are kept silently in your data.'**
  String get removeModuleBody;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'remove'**
  String get remove;

  /// No description provided for @newModule.
  ///
  /// In en, this message translates to:
  /// **'new module'**
  String get newModule;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'discard changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'you have unsaved edits. discard them?'**
  String get discardBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'discard'**
  String get discard;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'save'**
  String get save;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'icon'**
  String get iconLabel;

  /// No description provided for @moduleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'module name *'**
  String get moduleNameLabel;

  /// No description provided for @questionLabel.
  ///
  /// In en, this message translates to:
  /// **'question'**
  String get questionLabel;

  /// No description provided for @clearToRestoreDefault.
  ///
  /// In en, this message translates to:
  /// **'clear to restore default'**
  String get clearToRestoreDefault;

  /// No description provided for @responseType.
  ///
  /// In en, this message translates to:
  /// **'response type'**
  String get responseType;

  /// No description provided for @rtScale.
  ///
  /// In en, this message translates to:
  /// **'0–10 scale'**
  String get rtScale;

  /// No description provided for @rtMultiSelect.
  ///
  /// In en, this message translates to:
  /// **'multi-select'**
  String get rtMultiSelect;

  /// No description provided for @rtSingleSelect.
  ///
  /// In en, this message translates to:
  /// **'single-select'**
  String get rtSingleSelect;

  /// No description provided for @rtText.
  ///
  /// In en, this message translates to:
  /// **'free text'**
  String get rtText;

  /// No description provided for @rtConditional.
  ///
  /// In en, this message translates to:
  /// **'conditional'**
  String get rtConditional;

  /// No description provided for @lowLabel.
  ///
  /// In en, this message translates to:
  /// **'low label'**
  String get lowLabel;

  /// No description provided for @highLabel.
  ///
  /// In en, this message translates to:
  /// **'high label'**
  String get highLabel;

  /// No description provided for @lowLabelHelper.
  ///
  /// In en, this message translates to:
  /// **'emoji or text for the low end'**
  String get lowLabelHelper;

  /// No description provided for @highLabelHelper.
  ///
  /// In en, this message translates to:
  /// **'emoji or text for the high end'**
  String get highLabelHelper;

  /// No description provided for @primaryOptions.
  ///
  /// In en, this message translates to:
  /// **'primary options'**
  String get primaryOptions;

  /// No description provided for @answerOptions.
  ///
  /// In en, this message translates to:
  /// **'answer options'**
  String get answerOptions;

  /// No description provided for @optionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 😊 happy'**
  String get optionHint;

  /// No description provided for @triggerOption.
  ///
  /// In en, this message translates to:
  /// **'trigger option'**
  String get triggerOption;

  /// No description provided for @triggerOptionHint.
  ///
  /// In en, this message translates to:
  /// **'which option reveals the follow-up?'**
  String get triggerOptionHint;

  /// No description provided for @followupQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'follow-up question (optional)'**
  String get followupQuestionLabel;

  /// No description provided for @followupOptions.
  ///
  /// In en, this message translates to:
  /// **'follow-up options'**
  String get followupOptions;

  /// No description provided for @followupOptionHint.
  ///
  /// In en, this message translates to:
  /// **'add a follow-up option'**
  String get followupOptionHint;

  /// No description provided for @removeModule.
  ///
  /// In en, this message translates to:
  /// **'remove module'**
  String get removeModule;

  /// No description provided for @pastResponsesKept.
  ///
  /// In en, this message translates to:
  /// **'past responses are kept in your data'**
  String get pastResponsesKept;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get add;

  /// No description provided for @logToday.
  ///
  /// In en, this message translates to:
  /// **'log today'**
  String get logToday;

  /// No description provided for @editToday.
  ///
  /// In en, this message translates to:
  /// **'edit today'**
  String get editToday;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'follow-up'**
  String get followUp;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'anything else on your mind…'**
  String get notesHint;

  /// No description provided for @noModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'no modules enabled'**
  String get noModulesTitle;

  /// No description provided for @noModulesBody.
  ///
  /// In en, this message translates to:
  /// **'enable at least one module in settings to start logging.'**
  String get noModulesBody;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'go to settings'**
  String get goToSettings;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get next;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get tabHome;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'history'**
  String get tabHistory;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'calendar'**
  String get tabCalendar;

  /// No description provided for @tabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'analytics'**
  String get tabAnalytics;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get tabSettings;

  /// No description provided for @notLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'you haven\'t logged today yet.'**
  String get notLoggedToday;

  /// No description provided for @todaysLog.
  ///
  /// In en, this message translates to:
  /// **'today\'s log'**
  String get todaysLog;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get edit;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'recent'**
  String get recent;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'good morning 🌅'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'good afternoon ☀️'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'good evening 🌙'**
  String get goodEvening;

  /// No description provided for @cycleDay.
  ///
  /// In en, this message translates to:
  /// **'day {day} — {phase}'**
  String cycleDay(int day, String phase);

  /// No description provided for @nextPeriodTomorrow.
  ///
  /// In en, this message translates to:
  /// **'next period predicted tomorrow'**
  String get nextPeriodTomorrow;

  /// No description provided for @nextPeriodIn.
  ///
  /// In en, this message translates to:
  /// **'next period in {count, plural, =1{1 day} other{{count} days}}'**
  String nextPeriodIn(int count);

  /// No description provided for @catchUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'no log for {day} — want to catch up?'**
  String catchUpPrompt(String day);

  /// No description provided for @logIt.
  ///
  /// In en, this message translates to:
  /// **'log it'**
  String get logIt;

  /// No description provided for @noPastEntries.
  ///
  /// In en, this message translates to:
  /// **'no past entries yet.'**
  String get noPastEntries;

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'no entries yet. start logging!'**
  String get noEntriesYet;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'delete entry?'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryBody.
  ///
  /// In en, this message translates to:
  /// **'remove the log for {date}?'**
  String deleteEntryBody(String date);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get delete;

  /// No description provided for @swipeToDelete.
  ///
  /// In en, this message translates to:
  /// **'swipe a log left to delete it.'**
  String get swipeToDelete;

  /// No description provided for @goToToday.
  ///
  /// In en, this message translates to:
  /// **'go to today'**
  String get goToToday;

  /// No description provided for @tabCycle.
  ///
  /// In en, this message translates to:
  /// **'cycle'**
  String get tabCycle;

  /// No description provided for @tabMood.
  ///
  /// In en, this message translates to:
  /// **'mood'**
  String get tabMood;

  /// No description provided for @aboutCyclePhases.
  ///
  /// In en, this message translates to:
  /// **'about cycle phases'**
  String get aboutCyclePhases;

  /// No description provided for @cycleCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'tap a past day on the calendar to mark your period start and end.'**
  String get cycleCalendarHint;

  /// No description provided for @moodCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'tap a past day on the calendar to edit the log for that day.'**
  String get moodCalendarHint;

  /// No description provided for @intimacy.
  ///
  /// In en, this message translates to:
  /// **'intimacy'**
  String get intimacy;

  /// No description provided for @periodStartedToday.
  ///
  /// In en, this message translates to:
  /// **'period started on this day'**
  String get periodStartedToday;

  /// No description provided for @periodEndedToday.
  ///
  /// In en, this message translates to:
  /// **'period ended on this day'**
  String get periodEndedToday;

  /// No description provided for @cycleInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'the menstrual cycle'**
  String get cycleInfoTitle;

  /// No description provided for @cycleInfoIntro.
  ///
  /// In en, this message translates to:
  /// **'a cycle starts on the first day of your period and ends the day before the next one. on average it lasts about 28 days, but anywhere between 21 and 35 days is common.'**
  String get cycleInfoIntro;

  /// No description provided for @phaseInfoMenstruationTitle.
  ///
  /// In en, this message translates to:
  /// **'menstruation'**
  String get phaseInfoMenstruationTitle;

  /// No description provided for @phaseInfoMenstruationDuration.
  ///
  /// In en, this message translates to:
  /// **'about 3–7 days'**
  String get phaseInfoMenstruationDuration;

  /// No description provided for @phaseInfoMenstruationBody.
  ///
  /// In en, this message translates to:
  /// **'your period: the lining of the uterus is shed. energy can be lower and cramps are common.'**
  String get phaseInfoMenstruationBody;

  /// No description provided for @phaseInfoFollicularTitle.
  ///
  /// In en, this message translates to:
  /// **'follicular phase'**
  String get phaseInfoFollicularTitle;

  /// No description provided for @phaseInfoFollicularDuration.
  ///
  /// In en, this message translates to:
  /// **'about 7–14 days after your period'**
  String get phaseInfoFollicularDuration;

  /// No description provided for @phaseInfoFollicularBody.
  ///
  /// In en, this message translates to:
  /// **'hormone levels (oestrogen) rise as the body prepares to release an egg. many people feel more energetic. this is the phase whose length varies the most, which is why cycle lengths differ.'**
  String get phaseInfoFollicularBody;

  /// No description provided for @phaseInfoFertilityTitle.
  ///
  /// In en, this message translates to:
  /// **'higher fertility window'**
  String get phaseInfoFertilityTitle;

  /// No description provided for @phaseInfoFertilityDuration.
  ///
  /// In en, this message translates to:
  /// **'about 5 days, ending on ovulation'**
  String get phaseInfoFertilityDuration;

  /// No description provided for @phaseInfoFertilityBody.
  ///
  /// In en, this message translates to:
  /// **'the days when pregnancy is most likely (but pregnancy is also possible outside of this phase!). to show it on the calendar, turn on \"show higher-fertility window\" in settings.'**
  String get phaseInfoFertilityBody;

  /// No description provided for @phaseInfoOvulationTitle.
  ///
  /// In en, this message translates to:
  /// **'ovulation'**
  String get phaseInfoOvulationTitle;

  /// No description provided for @phaseInfoOvulationDuration.
  ///
  /// In en, this message translates to:
  /// **'about 1 day'**
  String get phaseInfoOvulationDuration;

  /// No description provided for @phaseInfoOvulationBody.
  ///
  /// In en, this message translates to:
  /// **'an egg is released, usually around 14 days before the next period (day 14 of a 28-day cycle).'**
  String get phaseInfoOvulationBody;

  /// No description provided for @phaseInfoLutealTitle.
  ///
  /// In en, this message translates to:
  /// **'luteal phase'**
  String get phaseInfoLutealTitle;

  /// No description provided for @phaseInfoLutealDuration.
  ///
  /// In en, this message translates to:
  /// **'about 12–14 days'**
  String get phaseInfoLutealDuration;

  /// No description provided for @phaseInfoLutealBody.
  ///
  /// In en, this message translates to:
  /// **'progesterone rises after ovulation. towards the end, some people notice PMS symptoms such as bloating, mood changes or breast tenderness. this phase is fairly stable in length.'**
  String get phaseInfoLutealBody;

  /// No description provided for @everyBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'every body is different'**
  String get everyBodyTitle;

  /// No description provided for @everyBodyBody.
  ///
  /// In en, this message translates to:
  /// **'these are averages. your own cycle may be shorter, longer or irregular, and it can change over time with age, stress, illness, travel, contraception, pregnancy or menopause.'**
  String get everyBodyBody;

  /// No description provided for @knowYourCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'getting to know your cycle'**
  String get knowYourCycleTitle;

  /// No description provided for @knowYourCycleBody.
  ///
  /// In en, this message translates to:
  /// **'mark the start and end of each period on the calendar. sarapp uses your own history, not just the averages above, to estimate your phases. after a few cycles, you will have a better idea of when each phase is likely to happen for you, and how your mood, sleep and symptoms change across your cycle.'**
  String get knowYourCycleBody;

  /// No description provided for @phasesEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'phases shown in sarapp are estimates. they are not reliable enough to use as contraception or to plan a pregnancy.'**
  String get phasesEstimateNote;

  /// No description provided for @chartsEmpty.
  ///
  /// In en, this message translates to:
  /// **'log some entries to see charts.'**
  String get chartsEmpty;

  /// No description provided for @chartsEmotionsTitle.
  ///
  /// In en, this message translates to:
  /// **'emotions — last 30 days'**
  String get chartsEmotionsTitle;

  /// No description provided for @chartsNoEmotions.
  ///
  /// In en, this message translates to:
  /// **'no emotion data yet.'**
  String get chartsNoEmotions;

  /// No description provided for @chartsPhasesTitle.
  ///
  /// In en, this message translates to:
  /// **'cycle phases — last 30 days'**
  String get chartsPhasesTitle;

  /// No description provided for @chartsNoPhases.
  ///
  /// In en, this message translates to:
  /// **'no cycle phase data yet.'**
  String get chartsNoPhases;

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String daysShort(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
