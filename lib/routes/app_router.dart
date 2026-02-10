import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/features/onboarding/screens/onboarding_screen.dart';
import 'package:luvoo/features/auth/screens/login_screen.dart';
import 'package:luvoo/features/auth/screens/register_screen.dart';
import 'package:luvoo/features/profile/screens/profile_setup_screen.dart';
import 'package:luvoo/features/discovery/screens/profile_detail_screen.dart';
import 'package:luvoo/features/chat/screens/chat_screen.dart';
import 'package:luvoo/features/main/screens/main_screen.dart';
import 'package:luvoo/features/discovery/screens/filter_screen.dart';
import 'package:luvoo/features/admin/screens/admin_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final location = state.matchedLocation;

      // 1. Onboarding: show first for new users
      final onboardingDone = await isOnboardingCompleted();
      if (!onboardingDone && location != '/onboarding') {
        return '/onboarding';
      }
      if (location == '/onboarding') return null;

      // 2. Auth
      final user = firebaseService.auth.currentUser;
      final isAuthRoute = location == '/login' || location == '/register';

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      final userModel = await firebaseService.getUser(user.uid);
      
      if (userModel == null || !userModel.isProfileComplete) {
        return location == '/profile-setup' ? null : '/profile-setup';
      }
      
      if (isAuthRoute || location == '/') {
        return '/main';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => ProfileDetailScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) => ChatScreen(
          chatId: state.pathParameters['chatId']!,
        ),
      ),
      GoRoute(
        path: '/filter',
        builder: (context, state) => const FilterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}); 