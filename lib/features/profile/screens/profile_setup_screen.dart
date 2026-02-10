import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luvoo/core/theme/app_theme.dart';
import 'package:luvoo/core/theme/theme_provider.dart';
import 'package:luvoo/core/widgets/app_button.dart';
import 'package:luvoo/core/widgets/app_text_field.dart';
import 'package:luvoo/core/widgets/liquid_glass.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/models/user_model.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/core/services/location_service.dart';
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
  static const int _maxPhotos = 6;
  List<File> _photoFiles = []; // Newly picked, not yet uploaded
  List<String> _photoUrls = []; // Existing URLs from Firestore
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
      _photoUrls = List<String>.from(user.photoUrls);
      if (_photoUrls.isEmpty && user.photoUrl != null && user.photoUrl!.isNotEmpty) {
        _photoUrls = [user.photoUrl!];
      }
      
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
    final totalCount = _photoUrls.length + _photoFiles.length;
    if (totalCount >= _maxPhotos) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximum $_maxPhotos photos allowed')),
        );
      }
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _photoFiles.add(File(pickedFile.path));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      if (index < _photoUrls.length) {
        _photoUrls.removeAt(index);
      } else {
        _photoFiles.removeAt(index - _photoUrls.length);
      }
    });
  }

  List<dynamic> get _allPhotos {
    return [..._photoUrls, ..._photoFiles];
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

      List<String> photoUrls = List.from(_photoUrls);
      if (_photoFiles.isNotEmpty) {
        final newUrls = await ref
            .read(firebaseServiceProvider)
            .uploadProfileImages(firebaseUser.uid, _photoFiles);
        photoUrls.addAll(newUrls);
        if (photoUrls.length > _maxPhotos) photoUrls = photoUrls.sublist(0, _maxPhotos);
      }

      // Get current location for distance filtering
      double? latitude;
      double? longitude;
      final position = await LocationService().getCurrentLocation();
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final currentUser = ref.read(authProvider).value;
      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: currentUser?.name ?? firebaseUser.displayName ?? '',
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        birthday: _selectedBirthday,
        photoUrl: photoUrls.isNotEmpty ? photoUrls.first : currentUser?.photoUrl,
        photoUrls: photoUrls,
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
        latitude: latitude ?? currentUser?.latitude,
        longitude: longitude ?? currentUser?.longitude,
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
        setState(() {
          _isEditing = false;
          _photoUrls = photoUrls;
          _photoFiles = [];
        });
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : colorScheme.surface,
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkBackground,
                    AppTheme.darkBackgroundSecondary,
                    AppTheme.darkBackground,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              )
            : null,
        child: SafeArea(
          child: _buildBody(context, theme, colorScheme, user),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 24),
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(Icons.edit, color: colorScheme.onBackground),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: colorScheme.onBackground),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onBackground),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ColorScheme colorScheme, UserModel? user) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Column(
            children: [
              // Profile Header - Glass
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Photos (gallery, max 6)
                      SizedBox(
                        height: 120,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _allPhotos.length + (_isEditing && _allPhotos.length < _maxPhotos ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _allPhotos.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          width: 100,
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: colorScheme.outline, width: 2),
                                          ),
                                          child: Icon(Icons.add_a_photo, size: 40, color: colorScheme.onSurface),
                                        ),
                                      ),
                                    );
                                  }
                                  final photo = _allPhotos[index];
                                  final isUrl = photo is String;
                                  return Padding(
                                    padding: EdgeInsets.only(right: index == _allPhotos.length - 1 ? 0 : 12),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: isUrl
                                              ? Image.network(photo as String, width: 100, height: 100, fit: BoxFit.cover)
                                              : Image.file(photo as File, width: 100, height: 100, fit: BoxFit.cover),
                                        ),
                                        if (_isEditing)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removePhoto(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User Info
                      Text(
                        user?.name ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_calculateAge(_selectedBirthday)} years old • ${_selectedGender.capitalize()}',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onBackground.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Content
              if (_isEditing) ...[
                // Edit Mode
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEditField(context,
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
                        _buildEditField(context,
                          label: 'Gender',
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: [
                              DropdownMenuItem(value: 'male', child: Text('Male', style: TextStyle(color: colorScheme.onSurface))),
                              DropdownMenuItem(value: 'female', child: Text('Female', style: TextStyle(color: colorScheme.onSurface))),
                              DropdownMenuItem(value: 'other', child: Text('Other', style: TextStyle(color: colorScheme.onSurface))),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedGender = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Birthday',
                          child: Builder(
                            builder: (ctx) {
                              final cs = Theme.of(ctx).colorScheme;
                              return InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    border: Border.all(color: cs.outline),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_selectedBirthday),
                                        style: TextStyle(fontSize: 16, color: cs.onSurface),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.calendar_today, color: cs.onSurface),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Interests',
                          child: Builder(
                            builder: (ctx) {
                              final cs = Theme.of(ctx).colorScheme;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select your interests (optional)',
                                    style: TextStyle(fontSize: 14, color: cs.outline),
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
                                            color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected ? cs.primary : cs.outline,
                                            ),
                                          ),
                                          child: Text(
                                            interest,
                                            style: TextStyle(
                                              color: isSelected ? cs.onPrimary : cs.onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Education',
                          child: DropdownButtonFormField<String>(
                            value: _selectedEducation,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _educationOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedEducation = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Political Views',
                          child: DropdownButtonFormField<String>(
                            value: _selectedPoliticalViews,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _politicalViewsOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPoliticalViews = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Exercise',
                          child: DropdownButtonFormField<String>(
                            value: _selectedExercise,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _exerciseOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedExercise = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Smoking',
                          child: DropdownButtonFormField<String>(
                            value: _selectedSmoking,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _smokingOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSmoking = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Drinking',
                          child: DropdownButtonFormField<String>(
                            value: _selectedDrinking,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _drinkingOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedDrinking = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Star Sign',
                          child: DropdownButtonFormField<String>(
                            value: _selectedStarSign,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _starSignOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStarSign = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Religion',
                          child: DropdownButtonFormField<String>(
                            value: _selectedReligion,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _religionOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedReligion = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Family Plans',
                          child: DropdownButtonFormField<String>(
                            value: _selectedFamilyPlans,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _familyPlansOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFamilyPlans = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Has Kids',
                          child: DropdownButtonFormField<String>(
                            value: _selectedHasKids,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _hasKidsOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedHasKids = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
                          label: 'Looking For',
                          child: DropdownButtonFormField<String>(
                            value: _selectedLookingFor,
                            decoration: InputDecoration(
                              fillColor: colorScheme.surface,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                            ),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onSurface),
                            items: _lookingForOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option, style: TextStyle(color: colorScheme.onSurface)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedLookingFor = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(context,
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
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GlassContainer(
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            user.bio!,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onBackground,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Interests Section
                      if (user?.interests.isNotEmpty == true) ...[
                        Text(
                          'Interests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
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
                                color: colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
                              ),
                              child: Text(
                                interest,
                                style: TextStyle(
                                  color: colorScheme.onBackground,
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
                        Text(
                          'About Me',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassContainer(
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (user?.education != null) _buildProfileInfo(context, 'Education', user!.education!),
                              if (user?.politicalViews != null) _buildProfileInfo(context, 'Political Views', user!.politicalViews!),
                              if (user?.exercise != null) _buildProfileInfo(context, 'Exercise', user!.exercise!),
                              if (user?.smoking != null) _buildProfileInfo(context, 'Smoking', user!.smoking!),
                              if (user?.drinking != null) _buildProfileInfo(context, 'Drinking', user!.drinking!),
                              if (user?.starSign != null) _buildProfileInfo(context, 'Star Sign', user!.starSign!),
                              if (user?.religion != null) _buildProfileInfo(context, 'Religion', user!.religion!),
                              if (user?.familyPlans != null) _buildProfileInfo(context, 'Family Plans', user!.familyPlans!),
                              if (user?.hasKids != null) _buildProfileInfo(context, 'Has Kids', user!.hasKids!),
                              if (user?.lookingFor != null) _buildProfileInfo(context, 'Looking For', user!.lookingFor!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Stats Section
                      GlassContainer(
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(context, 'Age', '${_calculateAge(_selectedBirthday)}'),
                            _buildStat(context, 'Gender', _selectedGender.capitalize()),
                            _buildStat(context, 'Member Since', DateFormat('MMM yyyy').format(user?.createdAt ?? DateTime.now())),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Theme (Light / Dark / System)
                      GlassContainer(
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ref.watch(themeModeProvider).when(
                              data: (mode) => SegmentedButton<ThemeMode>(
                                segments: const [
                                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                                ],
                                selected: {mode},
                                onSelectionChanged: (Set<ThemeMode> selected) {
                                  ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
                                },
                              ),
                              loading: () => const SizedBox(height: 40),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Pause / Incognito
                      GlassContainer(
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(
                                'Pause account',
                                style: TextStyle(color: colorScheme.onBackground, fontSize: 16),
                              ),
                              subtitle: Text(
                                'Hide your profile from discovery',
                                style: TextStyle(color: colorScheme.onBackground.withOpacity(0.7), fontSize: 12),
                              ),
                              value: user?.isPaused ?? false,
                              onChanged: user != null
                                  ? (value) => _setPausedOrIncognito(isPaused: value)
                                  : null,
                              activeColor: colorScheme.primary,
                            ),
                            Divider(color: colorScheme.outline, height: 1),
                            SwitchListTile(
                              title: Text(
                                'Incognito',
                                style: TextStyle(color: colorScheme.onBackground, fontSize: 16),
                              ),
                              subtitle: Text(
                                'Browse without being seen in discovery',
                                style: TextStyle(color: colorScheme.onBackground.withOpacity(0.7), fontSize: 12),
                              ),
                              value: user?.isIncognito ?? false,
                              onChanged: user != null
                                  ? (value) => _setPausedOrIncognito(isIncognito: value)
                                  : null,
                              activeColor: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Delete Account
                      TextButton.icon(
                        onPressed: () => _showDeleteAccountDialog(user?.id),
                        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                        label: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
            ],
          ),
        );
  }

  Widget _buildEditField(BuildContext context, {required String label, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onBackground.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
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
                color: colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setPausedOrIncognito({bool? isPaused, bool? isIncognito}) async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    final updated = user.copyWith(
      isPaused: isPaused ?? user.isPaused,
      isIncognito: isIncognito ?? user.isIncognito,
    );
    try {
      await ref.read(authProvider.notifier).updateProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPaused != null
                ? (isPaused ? 'Account paused' : 'Account resumed')
                : (isIncognito == true ? 'Incognito on' : 'Incognito off')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteAccountDialog(String? userId) {
    if (userId == null) return;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final needsPassword = firebaseUser?.providerData.any((p) => p.providerId == 'password') ?? false;
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete your account and all your data. This cannot be undone.',
              style: TextStyle(fontSize: 14),
            ),
            if (needsPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password to confirm',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final password = needsPassword ? passwordController.text.trim() : null;
              if (needsPassword && (password == null || password.isEmpty)) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ref.read(authProvider.notifier).deleteAccount(password: password);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted'), backgroundColor: Colors.green),
                  );
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
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
    if (_allPhotos.isNotEmpty) {
      final first = _allPhotos.first;
      if (first is File) return FileImage(first);
      if (first is String) return NetworkImage(first);
    }
    return null;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 