import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/peptide.dart';
import 'peptide_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peptide Library'),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? AppColors.error : null,
            ),
            onPressed: () =>
                setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
        ],
      ),
      body: Consumer<PeptideProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredPeptides = _filterPeptides(provider.peptides);
          final categories = _getCategorizedPeptides(filteredPeptides);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search peptides...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Category Filter Chips
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  itemCount: PeptideCategory.all.length + 1, // +1 for "All"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "All" option
                      final isSelected = _selectedCategory == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          selectedColor: AppColors.primaryBlue.withOpacity(0.1),
                          checkmarkColor: AppColors.primaryBlue,
                        ),
                      );
                    }
                    
                    final category = PeptideCategory.all[index - 1];
                    final isSelected = _selectedCategory == category;
                    final shortName = PeptideCategory.getShortName(category);

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        label: Text(shortName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: AppColors.primaryBlue.withOpacity(0.1),
                        checkmarkColor: AppColors.primaryBlue,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.s),

              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Row(
                  children: [
                    Text(
                      '${filteredPeptides.length} peptides',
                      style: AppTypography.caption1
                          .copyWith(color: AppColors.mediumGray),
                    ),
                    if (_showFavoritesOnly || _selectedCategory != null) ...[
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showFavoritesOnly = false;
                            _selectedCategory = null;
                            _searchQuery = '';
                          });
                        },
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ],
                ),
              ),

              // Peptide List
              Expanded(
                child: filteredPeptides.isEmpty
                    ? _buildEmptyState()
                    : _selectedCategory != null || _searchQuery.isNotEmpty
                        ? _buildFlatList(filteredPeptides)
                        : _buildGroupedList(categories),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Peptide> _filterPeptides(List<Peptide> peptides) {
    return peptides.where((p) {
      // Favorites filter
      if (_showFavoritesOnly && !p.isFavorite) return false;

      // Category filter
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            p.alternativeNames.any((n) => n.toLowerCase().contains(query)) ||
            p.description.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  Map<String, List<Peptide>> _getCategorizedPeptides(List<Peptide> peptides) {
    final Map<String, List<Peptide>> categories = {};
    for (final peptide in peptides) {
      categories.putIfAbsent(peptide.category, () => []).add(peptide);
    }
    return categories;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 64,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'No Peptides Found',
            style: AppTypography.headline.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _showFavoritesOnly
                ? 'You haven\'t favorited any peptides yet'
                : 'Try adjusting your search or filters',
            style: AppTypography.body.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatList(List<Peptide> peptides) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: peptides.length,
      itemBuilder: (context, index) {
        return _PeptideCard(
          peptide: peptides[index],
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.peptideDetail,
            arguments: peptides[index].id,
          ),
          onFavoriteToggle: () {
            context.read<PeptideProvider>().toggleFavorite(
                  peptides[index].id,
                );
          },
        );
      },
    );
  }

  Widget _buildGroupedList(Map<String, List<Peptide>> categories) {
    final sortedCategories = categories.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final peptides = categories[category]!;
        final categoryColor = AppColors.getCategoryColor(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: AppRadius.smallRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    category,
                    style: AppTypography.subhead.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '(${peptides.length})',
                    style: AppTypography.caption1.copyWith(
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Peptides in category
            ...peptides.map(
              (peptide) => _PeptideCard(
                peptide: peptide,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.peptideDetail,
                  arguments: peptide.id,
                ),
                onFavoriteToggle: () {
                  context.read<PeptideProvider>().toggleFavorite(
                        peptide.id,
                      );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PeptideCard extends StatelessWidget {
  final Peptide peptide;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _PeptideCard({
    required this.peptide,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.getCategoryColor(peptide.category);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: categoryColor.withOpacity(0.1),
                radius: 24,
                child: Text(
                  peptide.name[0],
                  style: AppTypography.title2.copyWith(color: categoryColor),
                ),
              ),
              const SizedBox(width: AppSpacing.m),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            peptide.name,
                            style: AppTypography.headline,
                          ),
                        ),
                        if (peptide.isFavorite)
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppColors.error,
                          ),
                      ],
                    ),
                    if (peptide.alternativeNames.isNotEmpty)
                      Text(
                        peptide.alternativeNames.first,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      peptide.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Benefits preview
                    Wrap(
                      spacing: AppSpacing.xxs,
                      runSpacing: AppSpacing.xxs,
                      children: peptide.benefits.take(2).map((benefit) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: AppRadius.smallRadius,
                          ),
                          child: Text(
                            benefit,
                            style: AppTypography.caption2.copyWith(
                              color: categoryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Favorite button
              IconButton(
                icon: Icon(
                  peptide.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: peptide.isFavorite ? AppColors.error : AppColors.mediumGray,
                ),
                onPressed: onFavoriteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

