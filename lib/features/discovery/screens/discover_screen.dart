import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luvoo/models/user_model.dart';
import 'dart:math';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  // Rastgele resim listesi
  final List<String> _imageAssets = [
    'assets/images/sinemunsal.jpg',
    'assets/images/meganfox.jpg',
    'assets/images/margotrobbie.jpg',
    'assets/images/images.jpeg',
  ];

  // Rastgele resim seçme fonksiyonu
  String _getRandomImage() {
    final random = Random();
    return _imageAssets[random.nextInt(_imageAssets.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Similar interests section
                    const Text(
                      'Similar interests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Horizontal scrollable cards
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return _DiscoverCard(
                            name: ['Sky', 'Larissa', 'Emma', 'Sophia', 'Olivia'][index],
                            age: [44, 43, 41, 39, 42][index],
                            photoUrl: _getRandomImage(), // Rastgele resim
                            badges: [
                              ['Coffee', '+3'],
                              ['Coffee', 'Travel'],
                              ['Music', 'Art'],
                              ['Sports', 'Fitness'],
                              ['Reading', 'Movies'],
                            ][index],
                            isVerified: index % 2 == 0,
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Same dating goals section
                    const Text(
                      'Same dating goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Second horizontal scrollable cards
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return _DiscoverCard(
                            name: ['Nicolette', 'Kat', 'Mia', 'Ava', 'Isabella'][index],
                            age: [42, 44, 38, 40, 43][index],
                            photoUrl: _getRandomImage(), // Rastgele resim
                            badges: [
                              ['Life partner', '+1'],
                              ['Open to kids', 'Family'],
                              ['Long-term', 'Commitment'],
                              ['Marriage', 'Future'],
                              ['Serious', 'Relationship'],
                            ][index],
                            isVerified: index % 3 == 0,
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final String name;
  final int age;
  final String photoUrl;
  final List<String> badges;
  final bool isVerified;

  const _DiscoverCard({
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.badges,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image with badges
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Gerçek resim
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.asset(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Eğer resim yüklenemezse placeholder göster
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Badges overlay
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
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getBadgeIcon(badge),
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
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
                  
                  // Like button
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.pink,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Profile info
          Row(
            children: [
              Text(
                '$name, $age',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 16,
                ),
              ],
              const Spacer(),
              const Icon(
                Icons.favorite_border,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ],
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