import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

DateTime _dateTimeFromTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  } else if (timestamp is DateTime) {
    return timestamp;
  } else {
    throw Exception('Invalid timestamp type: \\${timestamp.runtimeType}');
  }
}
Timestamp _dateTimeToTimestamp(DateTime dateTime) => Timestamp.fromDate(dateTime);

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    String? matchId, // Eski sistem için (opsiyonel)
    String? chatId,  // Yeni chat sistemi için (opsiyonel)
    required String senderId,
    required String text,
    @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
    required DateTime timestamp,
    @Default(false) bool isRead,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

// Extension methods for MessageModel
extension MessageModelX on MessageModel {
  bool get isFromCurrentUser => senderId == currentUserId;
  
  static String? currentUserId; // Set this when user logs in
} 