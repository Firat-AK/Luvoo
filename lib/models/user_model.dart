import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

DateTime _dateTimeFromTimestamp(Timestamp timestamp) => timestamp.toDate();
Timestamp _dateTimeToTimestamp(DateTime dateTime) => Timestamp.fromDate(dateTime);

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    String? bio,
    required String gender,
    required DateTime birthday,
    String? photoUrl,
    @Default(false) bool isProfileComplete,
    @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
    required DateTime createdAt,
    // User preferences for filtering
    @Default('all') String interestedIn, // 'male', 'female', 'all'
    @Default([18, 100]) List<int> ageRange, // [minAge, maxAge]
    @Default(50) int maxDistance, // in kilometers
    @Default([]) List<String> interests, // user interests for matching
    
    // Advanced profile fields
    String? education, // 'High school', 'Apprentice', 'Studying', 'Undergraduate degree', 'Post Graduate Study', 'Post Graduate Degree'
    String? politicalViews, // 'Apolitical', 'Moderate', 'Left', 'Right'
    String? exercise, // 'Active', 'Sometimes', 'Almost never'
    String? smoking, // 'Yes, they smoke', 'They smoke sometimes', 'No, they don\'t smoke', 'They\'re trying to quit'
    String? drinking, // 'Yes, they drink', 'They drink sometimes', 'They rarely drink', 'No, they don\'t drink', 'They\'re sober'
    String? starSign, // 'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
    String? religion, // 'Agnostic', 'Atheist', 'Buddhist', 'Catholic', 'Christian', 'Hindu', 'Jain', 'Jewish', 'Mormon', 'Latter-day Saint', 'Muslim', 'Zoroastrian'
    String? familyPlans, // 'Want children', 'Don\'t want children', 'Have children and want more', 'Have children and don\'t want more', 'Not sure yet'
    String? hasKids, // 'Have kids', 'Don\'t have kids'
    String? lookingFor, // 'A long-term relationship', 'Fun, casual dates', 'Marriage', 'Intimacy, without commitment', 'A life partner', 'Ethical non-monogamy'
    List<int>? heightRange, // [minHeight, maxHeight] in cm
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

// Extension methods for UserModel
extension UserModelX on UserModel {
  int get age {
    final today = DateTime.now();
    var age = today.year - birthday.year;
    final monthDiff = today.month - birthday.month;
    if (monthDiff < 0 || (monthDiff == 0 && today.day < birthday.day)) {
      age--;
    }
    return age;
  }
} 