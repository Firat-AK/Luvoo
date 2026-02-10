import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/models/user_model.dart';
import 'package:luvoo/core/widgets/liquid_glass.dart';
import 'package:luvoo/features/discovery/screens/discovery_feed_screen.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? null : colorScheme.surface,
      body: Stack(
        children: [
          if (isDark)
            Container(
              width: double.infinity,
              height: double.infinity,
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
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glass Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.help_outline,
                            color: colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            
            Expanded(
              child: ref.watch(discoveryUsersProvider).when(
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No one to discover yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later or adjust your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final similar = users.take(5).toList();
                  final goals = users.length > 5 ? users.skip(5).take(5).toList() : <UserModel>[];
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Similar interests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: similar.length,
                            itemBuilder: (context, index) {
                              final user = similar[index];
                              return _DiscoverCard(
                                user: user,
                                onTap: () => context.push('/profile/${user.id}'),
                                colorScheme: colorScheme,
                              );
                            },
                          ),
                        ),
                        if (goals.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(
                            'Same dating goals',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: goals.length,
                              itemBuilder: (context, index) {
                                final user = goals[index];
                                return _DiscoverCard(
                                  user: user,
                                  onTap: () => context.push('/profile/${user.id}'),
                                  colorScheme: colorScheme,
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$error',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final ColorScheme? colorScheme;

  const _DiscoverCard({
    required this.user,
    this.onTap,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme ?? Theme.of(context).colorScheme;
    final badges = user.interests.take(3).toList();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassContainer(
                borderRadius: BorderRadius.circular(22),
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: (user.primaryPhotoUrl ?? '').isNotEmpty
                            ? Image.network(
                                user.primaryPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _photoPlaceholder(context),
                              )
                            : _photoPlaceholder(context),
                      ),
                      if (badges.isNotEmpty)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: badges.map((badge) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.surface.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outline.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getBadgeIcon(badge),
                                      color: cs.onSurface,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      badge,
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cs.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.outline.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            color: cs.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${user.name}, ${user.age}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.favorite_border,
                  color: cs.onSurface.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(
        Icons.person,
        size: 80,
        color: cs.onSurface.withOpacity(0.5),
      ),
    );
  }

  IconData _getBadgeIcon(String badge) {
    switch (badge.toLowerCase()) {
      case 'coffee':
        return Icons.coffee;
      case 'travel':
        return Icons.flight;
      case 'music':
        return Icons.music_note;
      case 'art':
        return Icons.palette;
      case 'sports':
        return Icons.sports_soccer;
      case 'fitness':
        return Icons.fitness_center;
      case 'reading':
        return Icons.book;
      case 'movies':
        return Icons.movie;
      case 'life partner':
        return Icons.search;
      case 'open to kids':
        return Icons.child_care;
      case 'family':
        return Icons.family_restroom;
      case 'long-term':
        return Icons.timeline;
      case 'commitment':
        return Icons.favorite;
      case 'marriage':
        return Icons.favorite;
      case 'future':
        return Icons.trending_up;
      case 'serious':
        return Icons.psychology;
      case 'relationship':
        return Icons.people;
      default:
        return Icons.tag;
    }
  }
} 