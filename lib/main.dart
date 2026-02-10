import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luvoo/core/services/notification_service.dart';
import 'package:luvoo/core/theme/app_theme.dart';
import 'package:luvoo/core/theme/theme_provider.dart';
import 'package:luvoo/firebase_options.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/routes/app_router.dart';

/// Background message handler (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await notificationService.initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
    rethrow;
  }
  runApp(const ProviderScope(child: MyApp()));
}

final notificationService = NotificationService();
final notificationServiceProvider = Provider<NotificationService>((ref) => notificationService);

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<RemoteMessage>? _tapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupNotifications());
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  void _setupNotifications() {
    final service = ref.read(notificationServiceProvider);
    final router = ref.read(routerProvider);
    _tapSub = service.onNotificationTap.listen((RemoteMessage msg) {
      final d = msg.data;
      if (d['chatId'] != null) {
        router.go('/chat/${d['chatId']}');
      } else if (d['matchId'] != null || d['type'] == 'match') {
        router.go('/main');
      } else if (d['userId'] != null && d['type'] == 'like') {
        router.go('/profile/${d['userId']}');
      }
    });
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      service.saveTokenForUser(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      next.whenData((u) async {
        if (u != null) {
          await ref.read(notificationServiceProvider).saveTokenForUser(u.id);
        }
      });
    });
    final router = ref.watch(routerProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Luvoo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
