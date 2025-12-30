import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/peptide.dart';
import '../../../core/widgets/animated_widgets.dart';
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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Peptide Library',
          style: AppTypography.title3,
        ),
        actions: [
          BouncyTap(
            onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: _showFavoritesOnly 
                    ? AppColors.pink.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: AppRadius.smallRadius,
              ),
              child: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: _showFavoritesOnly ? AppColors.pink : AppColors.mediumGray,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: Consumer<PeptideProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const ShimmerList(itemCount: 6, itemHeight: 100);
          }

          final filteredPeptides = _filterPeptides(provider.peptides);
          final categories = _getCategorizedPeptides(filteredPeptides);

          return Column(
            children: [
              // Animated Search Bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: _isSearchFocused ? AppSpacing.s : AppSpacing.m,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.softGray,
                    borderRadius: AppRadius.largeRadius,
                    border: _isSearchFocused
                        ? Border.all(color: AppColors.primaryBlue, width: 2)
                        : null,
                    boxShadow: _isSearchFocused
                        ? AppShadows.glow(AppColors.primaryBlue, intensity: 0.2)
                        : null,
                  ),
                child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search peptides...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isSearchFocused ? AppColors.primaryBlue : AppColors.mediumGray,
                      ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                          )
                        : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, end: 0),

              // Category Filter Chips
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  itemCount: PeptideCategory.all.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CategoryChip(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: index * 50));
                    }
                    
                    final category = PeptideCategory.all[index - 1];
                    final isSelected = _selectedCategory == category;
                    final shortName = PeptideCategory.getShortName(category);
                    final categoryColor = AppColors.getCategoryColor(category);

                    return _CategoryChip(
                      label: shortName,
                      isSelected: isSelected,
                      color: categoryColor,
                      onTap: () => setState(() => _selectedCategory = category),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: index * 50));
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
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    if (_showFavoritesOnly || _selectedCategory != null) ...[
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showFavoritesOnly = false;
                            _selectedCategory = null;
                            _searchQuery = '';
                            _searchController.clear();
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
                    ? AnimatedEmptyState(
                        icon: Icons.science_outlined,
                        title: 'No Peptides Found',
                        subtitle: _showFavoritesOnly
                            ? "You haven't favorited any peptides yet"
                            : 'Try adjusting your search or filters',
                        iconColor: AppColors.purple,
                        imagePath: _showFavoritesOnly 
                            ? 'assets/images/empty_favorites.png'
                            : 'assets/images/empty_search.png',
                      )
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
      if (_showFavoritesOnly && !p.isFavorite) return false;

      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }

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

  Widget _buildFlatList(List<Peptide> peptides) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: peptides.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: _PeptideCard(
          peptide: peptides[index],
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.peptideDetail,
            arguments: peptides[index].id,
          ),
          onFavoriteToggle: () {
              context.read<PeptideProvider>().toggleFavorite(peptides[index].id);
          },
          ),
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
            // Category Header with Icon
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withOpacity(0.15),
                    categoryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: AppRadius.mediumRadius,
                border: Border.all(color: categoryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: AppRadius.smallRadius,
                      boxShadow: AppShadows.glow(categoryColor, intensity: 0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.smallRadius,
                      child: AppColors.getCategoryIcon(category) != null
                          ? Image.asset(
                              AppColors.getCategoryIcon(category)!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.category_outlined,
                                  color: categoryColor,
                                  size: 20,
                                );
                              },
                            )
                          : Icon(
                              Icons.category_outlined,
                              color: categoryColor,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                    category,
                    style: AppTypography.subhead.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: AppRadius.smallRadius,
                    ),
                    child: Text(
                      '${peptides.length}',
                      style: AppTypography.caption2.copyWith(
                      color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 100))
                .slideX(begin: -0.05, end: 0),

            // Peptides in category
            ...peptides.asMap().entries.map((entry) => 
              AnimatedListItem(
                index: entry.key,
                delay: Duration(milliseconds: index * 50 + 100),
                child: _PeptideCard(
                  peptide: entry.value,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.peptideDetail,
                    arguments: entry.value.id,
                ),
                onFavoriteToggle: () {
                    context.read<PeptideProvider>().toggleFavorite(entry.value.id);
                },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primaryBlue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: BouncyTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? chipColor.withOpacity(isDark ? 0.3 : 0.15)
                : isDark ? AppColors.cardDark : AppColors.softGray,
            borderRadius: AppRadius.fullRadius,
            border: Border.all(
              color: isSelected ? chipColor : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? AppShadows.glow(chipColor, intensity: 0.2)
                : null,
          ),
          child: Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: isSelected ? chipColor : AppColors.mediumGray,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTap(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
          padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: AppRadius.largeRadius,
          border: Border.all(
            color: isDark ? AppColors.cardDark : AppColors.lightGray.withOpacity(0.5),
          ),
          boxShadow: isDark ? null : AppShadows.level1,
        ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Avatar with gradient
            Hero(
              tag: 'peptide_avatar_${peptide.id}',
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.getGradientForColor(categoryColor),
                  borderRadius: AppRadius.mediumRadius,
                  boxShadow: AppShadows.glow(categoryColor, intensity: 0.3),
                ),
                child: Center(
                child: Text(
                  peptide.name[0],
                    style: AppTypography.title2.copyWith(color: Colors.white),
                  ),
                ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'peptide_name_${peptide.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          peptide.name,
                          style: AppTypography.headline,
                        ),
                      ),
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
                  const SizedBox(height: AppSpacing.s),

                    // Benefits preview
                    Wrap(
                      spacing: AppSpacing.xxs,
                      runSpacing: AppSpacing.xxs,
                      children: peptide.benefits.take(2).map((benefit) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: AppRadius.smallRadius,
                          ),
                          child: Text(
                            benefit,
                            style: AppTypography.caption2.copyWith(
                              color: categoryColor,
                            fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Favorite button
            BouncyTap(
              onTap: onFavoriteToggle,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  peptide.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: peptide.isFavorite ? AppColors.pink : AppColors.mediumGray,
                  size: 24,
                ),
              ),
              ),
            ],
        ),
      ),
    );
  }
}
