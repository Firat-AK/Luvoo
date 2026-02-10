import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luvoo/models/user_model.dart';

class TestUsersGenerator {
  static final Random _random = Random();
  
  // Test data arrays
  static const List<String> _firstNames = [
    'Emma', 'Olivia', 'Ava', 'Isabella', 'Sophia', 'Charlotte', 'Mia', 'Amelia', 'Harper', 'Evelyn',
    'Abigail', 'Emily', 'Elizabeth', 'Mila', 'Ella', 'Avery', 'Sofia', 'Camila', 'Aria', 'Scarlett',
    'Victoria', 'Madison', 'Luna', 'Grace', 'Chloe', 'Penelope', 'Layla', 'Riley', 'Zoey', 'Nora',
    'Lily', 'Eleanor', 'Hannah', 'Lillian', 'Addison', 'Aubrey', 'Ellie', 'Stella', 'Natalie', 'Zoe',
    'Leah', 'Hazel', 'Violet', 'Aurora', 'Savannah', 'Audrey', 'Brooklyn', 'Bella', 'Claire', 'Skylar'
  ];

  static const List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
    'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
    'Walker', 'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
    'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell', 'Carter', 'Roberts'
  ];

  static const List<String> _educationOptions = [
    'High school', 'Apprentice', 'Studying', 'Undergraduate degree', 
    'Post Graduate Study', 'Post Graduate Degree'
  ];

  static const List<String> _politicalViewsOptions = [
    'Apolitical', 'Moderate', 'Left', 'Right'
  ];

  static const List<String> _exerciseOptions = [
    'Active', 'Sometimes', 'Almost never'
  ];

  static const List<String> _smokingOptions = [
    'Yes, they smoke', 'They smoke sometimes', 'No, they don\'t smoke', 
    'They\'re trying to quit'
  ];

  static const List<String> _drinkingOptions = [
    'Yes, they drink', 'They drink sometimes', 'They rarely drink', 
    'No, they don\'t drink', 'They\'re sober'
  ];

  static const List<String> _starSignOptions = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  static const List<String> _religionOptions = [
    'Agnostic', 'Atheist', 'Buddhist', 'Catholic', 'Christian', 'Hindu', 
    'Jain', 'Jewish', 'Mormon', 'Latter-day Saint', 'Muslim', 'Zoroastrian'
  ];

  static const List<String> _familyPlansOptions = [
    'Want children', 'Don\'t want children', 'Have children and want more', 
    'Have children and don\'t want more', 'Not sure yet'
  ];

  static const List<String> _hasKidsOptions = [
    'Have kids', 'Don\'t have kids'
  ];

  static const List<String> _lookingForOptions = [
    'A long-term relationship', 'Fun, casual dates', 'Marriage', 
    'Intimacy, without commitment', 'A life partner', 'Ethical non-monogamy'
  ];

  static const List<String> _interestsOptions = [
    'Coffee', 'Travel', 'Music', 'Art', 'Sports', 'Fitness',
    'Reading', 'Movies', 'Cooking', 'Photography', 'Dancing',
    'Hiking', 'Gaming', 'Yoga', 'Pets', 'Technology'
  ];

  static const List<String> _bioOptions = [
    'Love exploring new places and meeting interesting people! 🌍',
    'Passionate about music and always looking for new adventures 🎵',
    'Fitness enthusiast who enjoys good coffee and great conversations 💪',
    'Creative soul who loves art, travel, and meaningful connections 🎨',
    'Foodie who enjoys cooking, hiking, and spending time outdoors 🍳',
    'Tech lover with a passion for gaming and learning new things 💻',
    'Yoga instructor who believes in mindfulness and positive energy 🧘‍♀️',
    'Animal lover with a big heart and adventurous spirit 🐕',
    'Bookworm who enjoys deep conversations and quiet moments 📚',
    'Dance enthusiast who loves to move and groove to good music 💃',
    'Photography lover capturing life\'s beautiful moments 📸',
    'Coffee addict who enjoys good company and great stories ☕',
    'Fitness junkie who loves challenges and pushing limits 🏃‍♀️',
    'Travel blogger sharing stories from around the world ✈️',
    'Music producer who creates beats and loves live performances 🎤'
  ];

  static String _getRandomElement(List<String> list) {
    return list[_random.nextInt(list.length)];
  }

  static List<String> _getRandomInterests() {
    final count = _random.nextInt(4) + 2; // 2-5 interests
    final interests = <String>{};
    while (interests.length < count) {
      interests.add(_getRandomElement(_interestsOptions));
    }
    return interests.toList();
  }

  static DateTime _getRandomBirthday() {
    final now = DateTime.now();
    final minAge = 18;
    final maxAge = 45;
    final age = _random.nextInt(maxAge - minAge + 1) + minAge;
    final year = now.year - age;
    final month = _random.nextInt(12) + 1;
    final day = _random.nextInt(28) + 1; // Using 28 to avoid date issues
    return DateTime(year, month, day);
  }

  static String _generateEmail(String firstName, String lastName) {
    final domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
    final domain = _getRandomElement(domains);
    final numbers = _random.nextInt(999);
    return '${firstName.toLowerCase()}.${lastName.toLowerCase()}$numbers@$domain';
  }

  static UserModel _generateTestUser(int index) {
    final firstName = _getRandomElement(_firstNames);
    final lastName = _getRandomElement(_lastNames);
    final name = '$firstName $lastName';
    final email = _generateEmail(firstName, lastName);
    final birthday = _getRandomBirthday();
    final gender = _random.nextBool() ? 'female' : 'male';
    
    return UserModel(
      id: 'test_user_$index',
      email: email,
      name: name,
      bio: _getRandomElement(_bioOptions),
      gender: gender,
      birthday: birthday,
      photoUrl: 'assets/images/meganfox.jpg',
      photoUrls: ['assets/images/meganfox.jpg'], // Primary photo
      isProfileComplete: true,
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      interestedIn: _random.nextBool() ? 'all' : (gender == 'female' ? 'male' : 'female'),
      ageRange: [18, 50],
      maxDistance: _random.nextInt(30) + 20, // 20-50 km
      interests: _getRandomInterests(),
      heightRange: [150 + _random.nextInt(40), 160 + _random.nextInt(40)], // 150-200 cm
      education: _getRandomElement(_educationOptions),
      politicalViews: _getRandomElement(_politicalViewsOptions),
      exercise: _getRandomElement(_exerciseOptions),
      smoking: _getRandomElement(_smokingOptions),
      drinking: _getRandomElement(_drinkingOptions),
      starSign: _getRandomElement(_starSignOptions),
      religion: _getRandomElement(_religionOptions),
      familyPlans: _getRandomElement(_familyPlansOptions),
      hasKids: _getRandomElement(_hasKidsOptions),
      lookingFor: _getRandomElement(_lookingForOptions),
    );
  }

  static List<UserModel> generateTestUsers(int count) {
    final users = <UserModel>[];
    for (int i = 1; i <= count; i++) {
      users.add(_generateTestUser(i));
    }
    return users;
  }

  static Future<void> addTestUsersToFirebase(List<UserModel> users) async {
    final firestore = FirebaseFirestore.instance;
    
    print('[INFO] Starting to add ${users.length} test users to Firebase...');
    
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      try {
        await firestore.collection('users').doc(user.id).set(user.toJson());
        print('[SUCCESS] Added test user ${i + 1}/${users.length}: ${user.name}');
      } catch (e) {
        print('[ERROR] Failed to add user ${user.name}: $e');
      }
    }
    
    print('[INFO] Finished adding test users to Firebase!');
  }
} 