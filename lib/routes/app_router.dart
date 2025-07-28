import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/firebase_service.dart';
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
      final user = firebaseService.auth.currentUser;
      final isAuthRoute = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/register';

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      final userModel = await firebaseService.getUser(user.uid);
      
      if (userModel == null || !userModel.isProfileComplete) {
        return state.matchedLocation == '/profile-setup' ? null : '/profile-setup';
      }
      
      if (isAuthRoute || state.matchedLocation == '/') {
        return '/main';
      }

      return null;
    },
    routes: [
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