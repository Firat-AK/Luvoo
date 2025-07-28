import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luvoo/core/widgets/app_button.dart';
import 'package:luvoo/core/widgets/app_text_field.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/models/user_model.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _imageFile;
  String _selectedGender = 'male';
  DateTime _selectedBirthday = DateTime.now().subtract(const Duration(days: 365 * 18));
  bool _isLoading = false;
  bool _isEditing = false;
  List<String> _selectedInterests = [];

  // Advanced profile fields
  String? _selectedEducation;
  String? _selectedPoliticalViews;
  String? _selectedExercise;
  String? _selectedSmoking;
  String? _selectedDrinking;
  String? _selectedStarSign;
  String? _selectedReligion;
  String? _selectedFamilyPlans;
  String? _selectedHasKids;
  String? _selectedLookingFor;
  RangeValues _heightRange = const RangeValues(150, 200);

  final List<String> _availableInterests = [
    'Coffee', 'Travel', 'Music', 'Art', 'Sports', 'Fitness',
    'Reading', 'Movies', 'Cooking', 'Photography', 'Dancing',
    'Hiking', 'Gaming', 'Yoga', 'Pets', 'Technology'
  ];

  // Advanced options
  final List<String> _educationOptions = [
    'High school', 'Apprentice', 'Studying', 'Undergraduate degree', 
    'Post Graduate Study', 'Post Graduate Degree'
  ];

  final List<String> _politicalViewsOptions = [
    'Apolitical', 'Moderate', 'Left', 'Right'
  ];

  final List<String> _exerciseOptions = [
    'Active', 'Sometimes', 'Almost never'
  ];

  final List<String> _smokingOptions = [
    'Yes, they smoke', 'They smoke sometimes', 'No, they don\'t smoke', 
    'They\'re trying to quit'
  ];

  final List<String> _drinkingOptions = [
    'Yes, they drink', 'They drink sometimes', 'They rarely drink', 
    'No, they don\'t drink', 'They\'re sober'
  ];

  final List<String> _starSignOptions = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  final List<String> _religionOptions = [
    'Agnostic', 'Atheist', 'Buddhist', 'Catholic', 'Christian', 'Hindu', 
    'Jain', 'Jewish', 'Mormon', 'Latter-day Saint', 'Muslim', 'Zoroastrian'
  ];

  final List<String> _familyPlansOptions = [
    'Want children', 'Don\'t want children', 'Have children and want more', 
    'Have children and don\'t want more', 'Not sure yet'
  ];

  final List<String> _hasKidsOptions = [
    'Have kids', 'Don\'t have kids'
  ];

  final List<String> _lookingForOptions = [
    'A long-term relationship', 'Fun, casual dates', 'Marriage', 
    'Intimacy, without commitment', 'A life partner', 'Ethical non-monogamy'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      _bioController.text = user.bio ?? '';
      _selectedGender = user.gender ?? 'male';
      _selectedBirthday = user.birthday ?? DateTime.now().subtract(const Duration(days: 365 * 18));
      _selectedInterests = List<String>.from(user.interests);
      
      // Load advanced fields
      _selectedEducation = user.education;
      _selectedPoliticalViews = user.politicalViews;
      _selectedExercise = user.exercise;
      _selectedSmoking = user.smoking;
      _selectedDrinking = user.drinking;
      _selectedStarSign = user.starSign;
      _selectedReligion = user.religion;
      _selectedFamilyPlans = user.familyPlans;
      _selectedHasKids = user.hasKids;
      _selectedLookingFor = user.lookingFor;
      if (user.heightRange != null) {
        _heightRange = RangeValues(user.heightRange![0].toDouble(), user.heightRange![1].toDouble());
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('User not found');

      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await ref
            .read(firebaseServiceProvider)
            .uploadProfileImage(firebaseUser.uid, _imageFile!);
      }

      final currentUser = ref.read(authProvider).value;
      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: currentUser?.name ?? firebaseUser.displayName ?? '',
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        birthday: _selectedBirthday,
        photoUrl: photoUrl ?? currentUser?.photoUrl,
        isProfileComplete: true,
        createdAt: currentUser?.createdAt ?? DateTime.now(),
        interestedIn: currentUser?.interestedIn ?? 'all',
        ageRange: currentUser?.ageRange ?? [18, 100],
        maxDistance: currentUser?.maxDistance ?? 50,
        interests: _selectedInterests,
        heightRange: [_heightRange.start.round(), _heightRange.end.round()],
        education: _selectedEducation,
        politicalViews: _selectedPoliticalViews,
        exercise: _selectedExercise,
        smoking: _selectedSmoking,
        drinking: _selectedDrinking,
        starSign: _selectedStarSign,
        religion: _selectedReligion,
        familyPlans: _selectedFamilyPlans,
        hasKids: _selectedHasKids,
        lookingFor: _selectedLookingFor,
      );

      print('[DEBUG] Updating profile with new fields:');
      print('[DEBUG] Education: ${user.education}');
      print('[DEBUG] Political Views: ${user.politicalViews}');
      print('[DEBUG] Exercise: ${user.exercise}');
      print('[DEBUG] Smoking: ${user.smoking}');
      print('[DEBUG] Drinking: ${user.drinking}');
      print('[DEBUG] Star Sign: ${user.starSign}');
      print('[DEBUG] Religion: ${user.religion}');
      print('[DEBUG] Family Plans: ${user.familyPlans}');
      print('[DEBUG] Has Kids: ${user.hasKids}');
      print('[DEBUG] Looking For: ${user.lookingFor}');
      print('[DEBUG] Height Range: ${user.heightRange}');
      
      await ref.read(authProvider.notifier).updateProfile(user);
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () async {
                try {
                  await ref.read(authProvider.notifier).signOut();
                  if (mounted) context.go('/login');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ] else ...[
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Image
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getProfileImage(),
                            child: _getProfileImage() == null
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // User Info
                    Text(
                      user?.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_calculateAge(_selectedBirthday)} years old • ${_selectedGender.capitalize()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Content
              if (_isEditing) ...[
                // Edit Mode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEditField(
                          label: 'Bio',
                          child: TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText: 'Tell us about yourself...',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please write something about yourself';
                              }
                              if (value.length < 10) {
                                return 'Bio must be at least 10 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Gender',
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedGender = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Birthday',
                          child: InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedBirthday),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Interests',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select your interests (optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableInterests.map((interest) {
                                  final isSelected = _selectedInterests.contains(interest);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedInterests.remove(interest);
                                        } else {
                                          _selectedInterests.add(interest);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.purple : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? Colors.purple : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        interest,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Education',
                          child: DropdownButtonFormField<String>(
                            value: _selectedEducation,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _educationOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedEducation = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Political Views',
                          child: DropdownButtonFormField<String>(
                            value: _selectedPoliticalViews,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _politicalViewsOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPoliticalViews = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Exercise',
                          child: DropdownButtonFormField<String>(
                            value: _selectedExercise,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _exerciseOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedExercise = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Smoking',
                          child: DropdownButtonFormField<String>(
                            value: _selectedSmoking,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _smokingOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSmoking = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Drinking',
                          child: DropdownButtonFormField<String>(
                            value: _selectedDrinking,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _drinkingOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedDrinking = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Star Sign',
                          child: DropdownButtonFormField<String>(
                            value: _selectedStarSign,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _starSignOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStarSign = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Religion',
                          child: DropdownButtonFormField<String>(
                            value: _selectedReligion,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _religionOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedReligion = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Family Plans',
                          child: DropdownButtonFormField<String>(
                            value: _selectedFamilyPlans,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _familyPlansOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFamilyPlans = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Has Kids',
                          child: DropdownButtonFormField<String>(
                            value: _selectedHasKids,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _hasKidsOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedHasKids = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Looking For',
                          child: DropdownButtonFormField<String>(
                            value: _selectedLookingFor,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _lookingForOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedLookingFor = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: 'Height Range (cm)',
                          child: Column(
                            children: [
                              RangeSlider(
                                values: _heightRange,
                                min: 140.0,
                                max: 220.0,
                                divisions: 8,
                                labels: RangeLabels(
                                  '${_heightRange.start.round()}cm',
                                  '${_heightRange.end.round()}cm',
                                ),
                                onChanged: (values) {
                                  setState(() => _heightRange = values);
                                },
                              ),
                              Text(
                                '${_heightRange.start.round()}cm - ${_heightRange.end.round()}cm',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // View Mode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            user.bio!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Interests Section
                      if (user?.interests.isNotEmpty == true) ...[
                        const Text(
                          'Interests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user!.interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Advanced Profile Section
                      if (user?.education != null || user?.politicalViews != null || user?.exercise != null || 
                          user?.smoking != null || user?.drinking != null || user?.starSign != null || 
                          user?.religion != null || user?.familyPlans != null || user?.hasKids != null || 
                          user?.lookingFor != null) ...[
                        const Text(
                          'About Me',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              if (user?.education != null) _buildProfileInfo('Education', user!.education!),
                              if (user?.politicalViews != null) _buildProfileInfo('Political Views', user!.politicalViews!),
                              if (user?.exercise != null) _buildProfileInfo('Exercise', user!.exercise!),
                              if (user?.smoking != null) _buildProfileInfo('Smoking', user!.smoking!),
                              if (user?.drinking != null) _buildProfileInfo('Drinking', user!.drinking!),
                              if (user?.starSign != null) _buildProfileInfo('Star Sign', user!.starSign!),
                              if (user?.religion != null) _buildProfileInfo('Religion', user!.religion!),
                              if (user?.familyPlans != null) _buildProfileInfo('Family Plans', user!.familyPlans!),
                              if (user?.hasKids != null) _buildProfileInfo('Has Kids', user!.hasKids!),
                              if (user?.lookingFor != null) _buildProfileInfo('Looking For', user!.lookingFor!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Stats Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('Age', '${_calculateAge(_selectedBirthday)}'),
                            _buildStat('Gender', _selectedGender.capitalize()),
                            _buildStat('Member Since', DateFormat('MMM yyyy').format(user?.createdAt ?? DateTime.now())),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    final currentUser = ref.read(authProvider).value;
    if (currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty) {
      return NetworkImage(currentUser.photoUrl!);
    }
    return null;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 