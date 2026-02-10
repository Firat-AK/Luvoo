import 'package:firebase_auth/firebase_auth.dart';

/// Thrown when user tries Google/Apple sign-in but an account with same email
/// already exists (created with Email/Password). User can link by entering password.
class AuthAccountExistsException implements Exception {
  final String email;
  final AuthCredential credential;
  final String providerName; // 'Google' or 'Apple'

  AuthAccountExistsException({
    required this.email,
    required this.credential,
    this.providerName = 'Google',
  });

  @override
  String toString() =>
      'AuthAccountExistsException: Account with $email exists. Link $providerName by entering password.';
}
