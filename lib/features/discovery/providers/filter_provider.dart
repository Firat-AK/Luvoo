import 'package:flutter_riverpod/flutter_riverpod.dart';

// Filter options constants
class FilterOptions {
  // Education levels
  static const List<String> educationLevels = [
    'High school',
    'Apprentice',
    'Studying',
    'Undergraduate degree',
    'Post Graduate Study',
    'Post Graduate Degree',
  ];

  // Political views
  static const List<String> politicalViews = [
    'Apolitical',
    'Moderate',
    'Left',
    'Right',
  ];

  // Exercise habits
  static const List<String> exerciseHabits = [
    'Active',
    'Sometimes',
    'Almost never',
  ];

  // Smoking habits
  static const List<String> smokingHabits = [
    'Yes, they smoke',
    'They smoke sometimes',
    'No, they don\'t smoke',
    'They\'re trying to quit',
  ];

  // Drinking habits
  static const List<String> drinkingHabits = [
    'Yes, they drink',
    'They drink sometimes',
    'They rarely drink',
    'No, they don\'t drink',
    'They\'re sober',
  ];

  // Star signs
  static const List<String> starSigns = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  // Religions
  static const List<String> religions = [
    'Agnostic',
    'Atheist',
    'Buddhist',
    'Catholic',
    'Christian',
    'Hindu',
    'Jain',
    'Jewish',
    'Mormon',
    'Latter-day Saint',
    'Muslim',
    'Zoroastrian',
  ];

  // Family plans
  static const List<String> familyPlans = [
    'Want children',
    'Don\'t want children',
    'Have children and want more',
    'Have children and don\'t want more',
    'Not sure yet',
  ];

  // Has kids
  static const List<String> hasKids = [
    'Have kids',
    'Don\'t have kids',
  ];

  // Looking for
  static const List<String> lookingFor = [
    'A long-term relationship',
    'Fun, casual dates',
    'Marriage',
    'Intimacy, without commitment',
    'A life partner',
    'Ethical non-monogamy',
  ];
}

// Filter state class
class FilterState {
  final List<int> ageRange;
  final int maxDistance;
  final List<int> heightRange;
  final String interestedIn;
  final List<String> selectedEducation;
  final List<String> selectedPoliticalViews;
  final List<String> selectedExercise;
  final List<String> selectedSmoking;
  final List<String> selectedDrinking;
  final List<String> selectedStarSigns;
  final List<String> selectedReligions;
  final List<String> selectedFamilyPlans;
  final List<String> selectedHasKids;
  final List<String> selectedLookingFor;
  final Map<String, bool> showOthersIfRunOut;

  const FilterState({
    this.ageRange = const [18, 100],
    this.maxDistance = 50,
    this.heightRange = const [150, 200],
    this.interestedIn = 'all',
    this.selectedEducation = const [],
    this.selectedPoliticalViews = const [],
    this.selectedExercise = const [],
    this.selectedSmoking = const [],
    this.selectedDrinking = const [],
    this.selectedStarSigns = const [],
    this.selectedReligions = const [],
    this.selectedFamilyPlans = const [],
    this.selectedHasKids = const [],
    this.selectedLookingFor = const [],
    this.showOthersIfRunOut = const {},
  });

  FilterState copyWith({
    List<int>? ageRange,
    int? maxDistance,
    List<int>? heightRange,
    String? interestedIn,
    List<String>? selectedEducation,
    List<String>? selectedPoliticalViews,
    List<String>? selectedExercise,
    List<String>? selectedSmoking,
    List<String>? selectedDrinking,
    List<String>? selectedStarSigns,
    List<String>? selectedReligions,
    List<String>? selectedFamilyPlans,
    List<String>? selectedHasKids,
    List<String>? selectedLookingFor,
    Map<String, bool>? showOthersIfRunOut,
  }) {
    return FilterState(
      ageRange: ageRange ?? this.ageRange,
      maxDistance: maxDistance ?? this.maxDistance,
      heightRange: heightRange ?? this.heightRange,
      interestedIn: interestedIn ?? this.interestedIn,
      selectedEducation: selectedEducation ?? this.selectedEducation,
      selectedPoliticalViews: selectedPoliticalViews ?? this.selectedPoliticalViews,
      selectedExercise: selectedExercise ?? this.selectedExercise,
      selectedSmoking: selectedSmoking ?? this.selectedSmoking,
      selectedDrinking: selectedDrinking ?? this.selectedDrinking,
      selectedStarSigns: selectedStarSigns ?? this.selectedStarSigns,
      selectedReligions: selectedReligions ?? this.selectedReligions,
      selectedFamilyPlans: selectedFamilyPlans ?? this.selectedFamilyPlans,
      selectedHasKids: selectedHasKids ?? this.selectedHasKids,
      selectedLookingFor: selectedLookingFor ?? this.selectedLookingFor,
      showOthersIfRunOut: showOthersIfRunOut ?? this.showOthersIfRunOut,
    );
  }
}

// Filter provider
class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void updateAgeRange(List<int> ageRange) {
    state = state.copyWith(ageRange: ageRange);
  }

  void updateMaxDistance(int maxDistance) {
    state = state.copyWith(maxDistance: maxDistance);
  }

  void updateHeightRange(List<int> heightRange) {
    state = state.copyWith(heightRange: heightRange);
  }

  void updateInterestedIn(String interestedIn) {
    state = state.copyWith(interestedIn: interestedIn);
  }

  void updateEducation(List<String> education) {
    state = state.copyWith(selectedEducation: education);
  }

  void updatePoliticalViews(List<String> politicalViews) {
    state = state.copyWith(selectedPoliticalViews: politicalViews);
  }

  void updateExercise(List<String> exercise) {
    state = state.copyWith(selectedExercise: exercise);
  }

  void updateSmoking(List<String> smoking) {
    state = state.copyWith(selectedSmoking: smoking);
  }

  void updateDrinking(List<String> drinking) {
    state = state.copyWith(selectedDrinking: drinking);
  }

  void updateStarSigns(List<String> starSigns) {
    state = state.copyWith(selectedStarSigns: starSigns);
  }

  void updateReligions(List<String> religions) {
    state = state.copyWith(selectedReligions: religions);
  }

  void updateFamilyPlans(List<String> familyPlans) {
    state = state.copyWith(selectedFamilyPlans: familyPlans);
  }

  void updateHasKids(List<String> hasKids) {
    state = state.copyWith(selectedHasKids: hasKids);
  }

  void updateLookingFor(List<String> lookingFor) {
    state = state.copyWith(selectedLookingFor: lookingFor);
  }

  void updateShowOthersIfRunOut(String filterType, bool value) {
    final newMap = Map<String, bool>.from(state.showOthersIfRunOut);
    newMap[filterType] = value;
    state = state.copyWith(showOthersIfRunOut: newMap);
  }

  void resetFilters() {
    state = const FilterState();
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
}); 