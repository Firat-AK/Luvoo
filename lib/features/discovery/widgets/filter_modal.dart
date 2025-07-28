import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luvoo/features/discovery/providers/filter_provider.dart';

// Base modal widget
class BaseFilterModal extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSave;

  const BaseFilterModal({
    super.key,
    required this.title,
    required this.child,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onSave != null)
                  TextButton(
                    onPressed: onSave,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

// Age Range Modal
class AgeRangeModal extends ConsumerStatefulWidget {
  const AgeRangeModal({super.key});

  @override
  ConsumerState<AgeRangeModal> createState() => _AgeRangeModalState();
}

class _AgeRangeModalState extends ConsumerState<AgeRangeModal> {
  late RangeValues _ageRange;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _ageRange = RangeValues(
      filterState.ageRange[0].toDouble(),
      filterState.ageRange[1].toDouble(),
    );
    _showOthersIfRunOut = filterState.showOthersIfRunOut['ageRange'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'How old are they?',
      onSave: () {
        ref.read(filterProvider.notifier).updateAgeRange([
          _ageRange.start.round(),
          _ageRange.end.round(),
        ]);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('ageRange', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_ageRange.start.round()} - ${_ageRange.end.round()} years old',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 100,
              divisions: 82,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              onChanged: (values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),
            const Spacer(),
            Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Distance Modal
class DistanceModal extends ConsumerStatefulWidget {
  const DistanceModal({super.key});

  @override
  ConsumerState<DistanceModal> createState() => _DistanceModalState();
}

class _DistanceModalState extends ConsumerState<DistanceModal> {
  late double _distance;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _distance = filterState.maxDistance.toDouble();
    _showOthersIfRunOut = filterState.showOthersIfRunOut['distance'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'How far away?',
      onSave: () {
        ref.read(filterProvider.notifier).updateMaxDistance(_distance.round());
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('distance', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Within ${_distance.round()} km',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Slider(
              value: _distance,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${_distance.round()} km',
              onChanged: (value) {
                setState(() {
                  _distance = value;
                });
              },
            ),
            const Spacer(),
            Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Height Modal
class HeightModal extends ConsumerStatefulWidget {
  const HeightModal({super.key});

  @override
  ConsumerState<HeightModal> createState() => _HeightModalState();
}

class _HeightModalState extends ConsumerState<HeightModal> {
  late RangeValues _heightRange;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _heightRange = RangeValues(
      filterState.heightRange[0].toDouble(),
      filterState.heightRange[1].toDouble(),
    );
    _showOthersIfRunOut = filterState.showOthersIfRunOut['height'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'How tall are they?',
      onSave: () {
        ref.read(filterProvider.notifier).updateHeightRange([
          _heightRange.start.round(),
          _heightRange.end.round(),
        ]);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('height', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_heightRange.start.round()} - ${_heightRange.end.round()} cm',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            RangeSlider(
              values: _heightRange,
              min: 140,
              max: 220,
              divisions: 80,
              labels: RangeLabels(
                '${_heightRange.start.round()} cm',
                '${_heightRange.end.round()} cm',
              ),
              onChanged: (values) {
                setState(() {
                  _heightRange = values;
                });
              },
            ),
            const Spacer(),
            Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Looking For Modal
class LookingForModal extends ConsumerStatefulWidget {
  const LookingForModal({super.key});

  @override
  ConsumerState<LookingForModal> createState() => _LookingForModalState();
}

class _LookingForModalState extends ConsumerState<LookingForModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedLookingFor);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['lookingFor'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'What are they looking for?',
      onSave: () {
        ref.read(filterProvider.notifier).updateLookingFor(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('lookingFor', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.lookingFor.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.lookingFor[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Education Modal
class EducationModal extends ConsumerStatefulWidget {
  const EducationModal({super.key});

  @override
  ConsumerState<EducationModal> createState() => _EducationModalState();
}

class _EducationModalState extends ConsumerState<EducationModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedEducation);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['education'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'What\'s their education level?',
      onSave: () {
        ref.read(filterProvider.notifier).updateEducation(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('education', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.educationLevels.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.educationLevels[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Political Views Modal
class PoliticalViewsModal extends ConsumerStatefulWidget {
  const PoliticalViewsModal({super.key});

  @override
  ConsumerState<PoliticalViewsModal> createState() => _PoliticalViewsModalState();
}

class _PoliticalViewsModalState extends ConsumerState<PoliticalViewsModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedPoliticalViews);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['politicalViews'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'What are their political views?',
      onSave: () {
        ref.read(filterProvider.notifier).updatePoliticalViews(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('politicalViews', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.politicalViews.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.politicalViews[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Exercise Modal
class ExerciseModal extends ConsumerStatefulWidget {
  const ExerciseModal({super.key});

  @override
  ConsumerState<ExerciseModal> createState() => _ExerciseModalState();
}

class _ExerciseModalState extends ConsumerState<ExerciseModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedExercise);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['exercise'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'Do they exercise?',
      onSave: () {
        ref.read(filterProvider.notifier).updateExercise(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('exercise', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.exerciseHabits.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.exerciseHabits[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Smoking Modal
class SmokingModal extends ConsumerStatefulWidget {
  const SmokingModal({super.key});

  @override
  ConsumerState<SmokingModal> createState() => _SmokingModalState();
}

class _SmokingModalState extends ConsumerState<SmokingModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedSmoking);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['smoking'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'Do they smoke?',
      onSave: () {
        ref.read(filterProvider.notifier).updateSmoking(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('smoking', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.smokingHabits.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.smokingHabits[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Drinking Modal
class DrinkingModal extends ConsumerStatefulWidget {
  const DrinkingModal({super.key});

  @override
  ConsumerState<DrinkingModal> createState() => _DrinkingModalState();
}

class _DrinkingModalState extends ConsumerState<DrinkingModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedDrinking);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['drinking'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'Do they drink?',
      onSave: () {
        ref.read(filterProvider.notifier).updateDrinking(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('drinking', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.drinkingHabits.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.drinkingHabits[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Star Sign Modal
class StarSignModal extends ConsumerStatefulWidget {
  const StarSignModal({super.key});

  @override
  ConsumerState<StarSignModal> createState() => _StarSignModalState();
}

class _StarSignModalState extends ConsumerState<StarSignModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedStarSigns);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['starSigns'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'What\'s their star sign?',
      onSave: () {
        ref.read(filterProvider.notifier).updateStarSigns(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('starSigns', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.starSigns.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.starSigns[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Religion Modal
class ReligionModal extends ConsumerStatefulWidget {
  const ReligionModal({super.key});

  @override
  ConsumerState<ReligionModal> createState() => _ReligionModalState();
}

class _ReligionModalState extends ConsumerState<ReligionModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedReligions);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['religions'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'What\'s their religion?',
      onSave: () {
        ref.read(filterProvider.notifier).updateReligions(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('religions', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.religions.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.religions[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Family Plans Modal
class FamilyPlansModal extends ConsumerStatefulWidget {
  const FamilyPlansModal({super.key});

  @override
  ConsumerState<FamilyPlansModal> createState() => _FamilyPlansModalState();
}

class _FamilyPlansModalState extends ConsumerState<FamilyPlansModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedFamilyPlans);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['familyPlans'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'What are their family plans?',
      onSave: () {
        ref.read(filterProvider.notifier).updateFamilyPlans(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('familyPlans', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.familyPlans.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.familyPlans[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Has Kids Modal
class HasKidsModal extends ConsumerStatefulWidget {
  const HasKidsModal({super.key});

  @override
  ConsumerState<HasKidsModal> createState() => _HasKidsModalState();
}

class _HasKidsModalState extends ConsumerState<HasKidsModal> {
  late List<String> _selectedOptions;
  bool _showOthersIfRunOut = false;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    _selectedOptions = List.from(filterState.selectedHasKids);
    _showOthersIfRunOut = filterState.showOthersIfRunOut['hasKids'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseFilterModal(
      title: 'Do they have kids?',
      onSave: () {
        ref.read(filterProvider.notifier).updateHasKids(_selectedOptions);
        ref.read(filterProvider.notifier).updateShowOthersIfRunOut('hasKids', _showOthersIfRunOut);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: FilterOptions.hasKids.length,
              itemBuilder: (context, index) {
                final option = FilterOptions.hasKids[index];
                final isSelected = _selectedOptions.contains(option);
                
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show other people if I run out',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showOthersIfRunOut,
                  onChanged: (value) {
                    setState(() {
                      _showOthersIfRunOut = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 