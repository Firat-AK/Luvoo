import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/features/discovery/providers/filter_provider.dart';
import 'package:luvoo/features/discovery/widgets/filter_modal.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  bool _isBasicFilter = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Narrow your search',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter type selection
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBasicFilter = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isBasicFilter ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Text(
                        'Basic filters',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isBasicFilter ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBasicFilter = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isBasicFilter ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Text(
                        'Advanced filters',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isBasicFilter ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter content
          Expanded(
            child: _isBasicFilter ? const _BasicFiltersContent() : const _AdvancedFiltersContent(),
          ),
        ],
      ),
    );
  }
}

class _BasicFiltersContent extends ConsumerWidget {
  const _BasicFiltersContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age Range
          _buildFilterSection(
            context,
            'How old are they?',
            '${filterState.ageRange[0]} - ${filterState.ageRange[1]} years old',
            Icons.person,
            () => _showAgeRangeModal(context, ref),
          ),
          
          const SizedBox(height: 16),
          
          // Distance
          _buildFilterSection(
            context,
            'How far away?',
            'Within ${filterState.maxDistance} km',
            Icons.location_on,
            () => _showDistanceModal(context, ref),
          ),
          
          const SizedBox(height: 16),
          
          // Height
          _buildFilterSection(
            context,
            'How tall are they?',
            '${filterState.heightRange[0]} - ${filterState.heightRange[1]} cm',
            Icons.height,
            () => _showHeightModal(context, ref),
          ),
          
          const SizedBox(height: 16),
          
          // Looking for
          _buildFilterSection(
            context,
            'What are they looking for?',
            filterState.selectedLookingFor.isEmpty 
                ? 'Any relationship type is fine'
                : '${filterState.selectedLookingFor.length} selected',
            Icons.favorite,
            () => _showLookingForModal(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _showAgeRangeModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AgeRangeModal(),
    );
  }

  void _showDistanceModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DistanceModal(),
    );
  }

  void _showHeightModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HeightModal(),
    );
  }

  void _showLookingForModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LookingForModal(),
    );
  }
}

class _AdvancedFiltersContent extends ConsumerWidget {
  const _AdvancedFiltersContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedFilterOption(
            context,
            'What\'s their education level?',
            Icons.school,
            () => _showEducationModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'What are their political views?',
            Icons.account_balance,
            () => _showPoliticalViewsModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'Do they exercise?',
            Icons.fitness_center,
            () => _showExerciseModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'Do they smoke?',
            Icons.smoking_rooms,
            () => _showSmokingModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'Do they drink?',
            Icons.local_bar,
            () => _showDrinkingModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'What\'s their star sign?',
            Icons.star,
            () => _showStarSignModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'What\'s their religion?',
            Icons.church,
            () => _showReligionModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'What are their family plans?',
            Icons.family_restroom,
            () => _showFamilyPlansModal(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvancedFilterOption(
            context,
            'Do they have kids?',
            Icons.child_care,
            () => _showHasKidsModal(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Add this filter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.add, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  void _showEducationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EducationModal(),
    );
  }

  void _showPoliticalViewsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PoliticalViewsModal(),
    );
  }

  void _showExerciseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseModal(),
    );
  }

  void _showSmokingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SmokingModal(),
    );
  }

  void _showDrinkingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DrinkingModal(),
    );
  }

  void _showStarSignModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StarSignModal(),
    );
  }

  void _showReligionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReligionModal(),
    );
  }

  void _showFamilyPlansModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FamilyPlansModal(),
    );
  }

  void _showHasKidsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HasKidsModal(),
    );
  }
} 