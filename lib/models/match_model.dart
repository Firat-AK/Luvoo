import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

DateTime _dateTimeFromTimestamp(Timestamp timestamp) => timestamp.toDate();
Timestamp _dateTimeToTimestamp(DateTime dateTime) => Timestamp.fromDate(dateTime);

@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    required String userA,
    required String userB,
    @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
    required DateTime createdAt,
    @Default(false) bool isActive,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
}

// Extension methods for MatchModel
extension MatchModelX on MatchModel {
  String get otherUserId => 
    userA == currentUserId ? userB : userA;
  
  static String? currentUserId; // Set this when user logs in
} 