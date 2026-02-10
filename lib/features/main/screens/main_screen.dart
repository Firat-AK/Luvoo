import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luvoo/core/theme/app_theme.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/features/discovery/screens/discovery_feed_screen.dart';
import 'package:luvoo/features/discovery/screens/discover_screen.dart';
import 'package:luvoo/features/chat/screens/chat_list_screen.dart';
import 'package:luvoo/features/profile/screens/profile_setup_screen.dart';
import 'package:luvoo/core/widgets/liquid_glass.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DiscoverScreen(),
    const DiscoveryFeedScreen(),
    const ChatListScreen(),
    const ProfileSetupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBackground : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Text(
          'Luvoo',
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: colorScheme.onSurface,
            fontSize: 24,
          ),
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: Icon(Icons.tune, color: colorScheme.onSurface, size: 26),
              onPressed: () => context.push('/filter'),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/admin'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 1),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? AppTheme.darkBackground : colorScheme.surface,
      extendBody: true,
      body: Stack(
        children: [
          if (isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B1020),
                      Color(0xFF25133A),
                      Color(0xFF0B1020),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ],
      ),
      bottomNavigationBar: GlassBottomBar(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildNavItem(context, Icons.explore, 'Discover', 0),
          _buildNavItem(context, Icons.people, 'People', 1),
          _buildNavItem(context, Icons.chat, 'Chats', 2),
          _buildNavItem(context, Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white.withOpacity(0.14) : colorScheme.primary.withOpacity(0.15))
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: isDark ? Colors.white.withOpacity(0.18) : colorScheme.primary.withOpacity(0.4),
                      width: 1,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 