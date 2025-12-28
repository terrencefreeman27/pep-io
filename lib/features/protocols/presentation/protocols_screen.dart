import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/protocol.dart';
import '../../../core/widgets/animated_widgets.dart';
import 'protocol_provider.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProtocolProvider>().loadProtocols();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Protocols', style: AppTypography.title3),
        actions: [
          BouncyTap(
            onTap: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              margin: const EdgeInsets.only(right: AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: AppRadius.mediumRadius,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ProtocolProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const ShimmerList(itemCount: 5, itemHeight: 100);
          }

          if (provider.protocols.isEmpty) {
            return _buildFirstTimeEmptyState(context);
          }

          final protocols = _filterProtocols(provider.protocols);

          return Column(
            children: [
              // Search bar
              _buildSearchBar(context),

              // Metrics row
              _buildMetricsRow(provider),

              // Protocols list
              Expanded(
                child: protocols.isEmpty
                    ? _buildSearchEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        itemCount: protocols.length,
                        itemBuilder: (context, index) {
                          return AnimatedListItem(
                            index: index,
                            child: _ProtocolCard(
                            protocol: protocols[index],
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.protocolDetail,
                              arguments: protocols[index].id,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.softGray,
          borderRadius: AppRadius.largeRadius,
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search protocols',
            prefixIcon: const Icon(Icons.search, color: AppColors.mediumGray),
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
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildMetricsRow(ProtocolProvider provider) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        children: [
          _MetricChip(
            icon: Icons.science_rounded,
            label: 'Active',
            value: '${provider.activeCount}',
            color: AppColors.purple,
          )
              .animate()
              .fadeIn(delay: 100.ms)
              .slideX(begin: 0.1, end: 0),
          const SizedBox(width: AppSpacing.s),
          _MetricChip(
            icon: Icons.calendar_today_rounded,
            label: 'Today',
            value: '${provider.todaysDoses.length}',
            color: AppColors.primaryBlue,
          )
              .animate()
              .fadeIn(delay: 150.ms)
              .slideX(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  List<Protocol> _filterProtocols(List<Protocol> protocols) {
    if (_searchQuery.isEmpty) return protocols;
    return protocols.where((p) {
      return p.peptideName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Widget _buildFirstTimeEmptyState(BuildContext context) {
    return AnimatedEmptyState(
      icon: Icons.science_outlined,
      title: 'No Protocols Yet',
      subtitle: 'Create your first protocol to start tracking\nyour peptide regimen',
      iconColor: AppColors.primaryBlue,
      imagePath: 'assets/images/empty_protocols.png',
      action: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
                icon: const Icon(Icons.add),
                label: const Text('Add Protocol'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.library),
              child: const Text('Browse Peptide Library'),
            ),
          ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return AnimatedEmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      subtitle: 'Try adjusting your search',
      iconColor: AppColors.mediumGray,
      imagePath: 'assets/images/empty_search.png',
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.largeRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isDark ? 0.2 : 0.1),
            color.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.s),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.title3.copyWith(color: color),
              ),
              Text(
                label,
                style: AppTypography.caption2.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  final Protocol protocol;
  final VoidCallback onTap;

  const _ProtocolCard({
    required this.protocol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.getCategoryColor(protocol.peptideName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTap(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: AppRadius.largeRadius,
          border: Border.all(
            color: isDark ? AppColors.cardDark : AppColors.lightGray.withOpacity(0.5),
          ),
          boxShadow: isDark ? null : AppShadows.level1,
        ),
        child: Column(
          children: [
            // Gradient accent bar
            Container(
              height: 4,
          decoration: BoxDecoration(
                gradient: AppColors.getGradientForColor(categoryColor),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
            
            Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.getGradientForColor(categoryColor),
                          borderRadius: AppRadius.mediumRadius,
                          boxShadow: AppShadows.glow(categoryColor, intensity: 0.25),
                        ),
                        child: Center(
                          child: Text(
                            protocol.peptideName[0],
                            style: AppTypography.headline.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      
                  Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                      protocol.peptideName,
                      style: AppTypography.headline,
                    ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 14,
                                  color: AppColors.mediumGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  protocol.formattedDosage,
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: AppColors.mediumGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  protocol.frequency,
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Status badge
                  if (!protocol.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                            color: AppColors.mediumGray.withOpacity(0.15),
                        borderRadius: AppRadius.smallRadius,
                      ),
                      child: Text(
                        'Paused',
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.mediumGray,
                              fontWeight: FontWeight.w500,
                        ),
                      ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.15),
                            borderRadius: AppRadius.smallRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PulsingDot(color: AppColors.green, size: 6),
                              const SizedBox(width: 4),
                              Text(
                                'Active',
                                style: AppTypography.caption2.copyWith(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                  IconButton(
                        icon: const Icon(Icons.more_vert, color: AppColors.mediumGray),
                    onPressed: () => _showOptions(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
                  
              if (protocol.notes != null && protocol.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s),
                Text(
                  protocol.notes!,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.mediumGray,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.s),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: const Text('Edit Protocol'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.protocolEdit,
                  arguments: protocol.id,
                );
              },
            ),
            ListTile(
              leading: Icon(
                protocol.active ? Icons.pause_outlined : Icons.play_arrow_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(protocol.active ? 'Pause Protocol' : 'Resume Protocol'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProtocolProvider>().toggleProtocolActive(
                  protocol.id,
                  !protocol.active,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'Delete Protocol',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Protocol?'),
        content: Text(
          'Are you sure you want to delete the ${protocol.peptideName} protocol? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProtocolProvider>().deleteProtocol(protocol.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
