import 'package:flutter/widgets.dart';

import '../models/app_module.dart';
import 'app_localizations.dart';

/// Languages the app ships, each named in its own language.
const languageNames = {'en': 'english', 'fr': 'français'};

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Display text for built-in values. Stored data always keeps the canonical
/// English strings (e.g. '😊 Happy'); these helpers only translate on display.
extension L10nDisplay on AppLocalizations {
  /// Translated label for a built-in option string; anything else (options the
  /// user typed) is returned unchanged.
  String option(String raw) => switch (raw) {
        // emotions
        '😊 Happy' => optHappy,
        '😢 Sad' => optSad,
        '😤 Angry' => optAngry,
        '😰 Anxious' => optAnxious,
        '😴 Tired' => optTired,
        '⚡ Energized' => optEnergized,
        // work
        '🌿 Day off' => optDayOff,
        '🌗 Half day' => optHalfDay,
        '💼 Full day' => optFullDay,
        // sports
        '🏋️ Weight lifting' => optWeightLifting,
        '🏃 Intense cardio' => optIntenseCardio,
        '🚴 Endurance' => optEndurance,
        '💃 Dance' => optDance,
        '🧗 Climbing' => optClimbing,
        // leisure
        '📖 Reading' => optReading,
        '🌱 Gardening' => optGardening,
        '🎲 Board games' => optBoardGames,
        '🎮 Gaming' => optGaming,
        '🎵 Music (practice)' => optMusicPractice,
        '🎶 Music (group)' => optMusicGroup,
        // food
        '🌾 Gluten' => optGluten,
        '🥛 Lactose' => optLactose,
        '🍬 Sugars' => optSugars,
        '🍗 Chicken' => optChicken,
        '🥩 Red meat' => optRedMeat,
        '🍖 Other meat' => optOtherMeat,
        '🐟 Fish' => optFish,
        // substances
        '🍷 Alcohol' => optAlcohol,
        '☕ Caffeine' => optCaffeine,
        '🚬 Nicotine' => optNicotine,
        '🌿 Cannabis' => optCannabis,
        '💊 Medication' => optMedication,
        // menstrual symptoms
        'cramps' => optCramps,
        'bloating' => optBloating,
        'headache' => optHeadache,
        'fatigue' => optFatigue,
        'mood swings' => optMoodSwings,
        'breast tenderness' => optBreastTenderness,
        'back pain' => optBackPain,
        'acne' => optAcne,
        // chronic symptoms (onboarding preset)
        '⚡ Pain' => optPain,
        '🦴 Joint pain' => optJointPain,
        '🤕 Headache / migraine' => optHeadacheMigraine,
        '🌫️ Brain fog' => optBrainFog,
        '💫 Dizziness' => optDizziness,
        '😵 Insomnia' => optInsomnia,
        // health
        'Healthy' => optHealthy,
        'Sick' => optSick,
        '🤧 Cold' => optCold,
        '🤒 Flu' => optFlu,
        '🤢 Nausea' => optNausea,
        '🤕 Headache' => optHeadacheSick,
        '🔥 Fever' => optFever,
        '🫄 Digestive issues' => optDigestive,
        '😮‍💨 Fatigue' => optFatigueSick,
        // sex
        'Yes' => optYes,
        'No' => optNo,
        _ => raw,
      };

  String moduleLabel(AppModule m) => switch (m.key) {
        'happiness' => modHappiness,
        'emotions' => modEmotions,
        'sleep' => modSleep,
        'stress' => modStress,
        'weather' => modWeather,
        'health' => modHealth,
        'work' => modWork,
        'sports' => modSports,
        'leisure' => modLeisure,
        'food' => modFood,
        'substances' => modSubstances,
        'symptoms' => modSymptoms,
        'libido' => modLibido,
        'sex' => modSex,
        'water' => modWater,
        'notes' => modNotes,
        _ => m.label,
      };

  /// Default question / description shown for a built-in module.
  String moduleDescription(AppModule m) => switch (m.key) {
        'happiness' => modHappinessDesc,
        'emotions' => modEmotionsDesc,
        'sleep' => modSleepDesc,
        'stress' => modStressDesc,
        'weather' => modWeatherDesc,
        'health' => modHealthDesc,
        'work' => modWorkDesc,
        'sports' => modSportsDesc,
        'leisure' => modLeisureDesc,
        'food' => modFoodDesc,
        'substances' => modSubstancesDesc,
        'symptoms' => modSymptomsDesc,
        'libido' => modLibidoDesc,
        'sex' => modSexDesc,
        'water' => modWaterDesc,
        'notes' => modNotesDesc,
        _ => m.description,
      };

  /// Translated text for a built-in conditional follow-up question.
  String conditionalQuestion(String raw) =>
      raw == AppModule.health.conditionalQuestion ? healthFollowupQuestion : raw;

  String cyclePhase(String? value) => switch (value) {
        null => '—',
        'menstruation' => phaseMenstruation,
        'follicular' => phaseFollicular,
        'high_fertility' => phaseHighFertility,
        'ovulation' => phaseOvulation,
        'luteal' => phaseLuteal,
        _ => value,
      };
}
