import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/protocol.dart';
import 'protocol_provider.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocols'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
          ),
        ],
      ),
      body: Consumer<ProtocolProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final protocols = _filterProtocols(provider.protocols);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search protocols',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Metrics row
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  children: [
                    _MetricChip(
                      icon: Icons.checklist,
                      label: 'Active',
                      value: '${provider.activeCount}',
                      color: AppColors.purple,
                    ),
                    _MetricChip(
                      icon: Icons.calendar_today,
                      label: 'Today',
                      value: '${provider.todaysDoses.length}',
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),

              // Protocols list
              Expanded(
                child: protocols.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        itemCount: protocols.length,
                        itemBuilder: (context, index) {
                          return _ProtocolCard(
                            protocol: protocols[index],
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.protocolDetail,
                              arguments: protocols[index].id,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
        child: const Icon(Icons.add),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'No Protocols Yet',
            style: AppTypography.title3.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add your first protocol to start tracking',
            style: AppTypography.body.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: AppSpacing.l),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
            icon: const Icon(Icons.add),
            label: const Text('Create Protocol'),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.s),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mediumRadius,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.headline.copyWith(color: color),
              ),
              Text(
                label,
                style: AppTypography.caption1.copyWith(color: color),
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediumRadius,
            border: Border(
              left: BorderSide(color: categoryColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      protocol.peptideName,
                      style: AppTypography.headline,
                    ),
                  ),
                  if (!protocol.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mediumGray.withOpacity(0.2),
                        borderRadius: AppRadius.smallRadius,
                      ),
                      child: Text(
                        'Paused',
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    protocol.formattedDosage,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    protocol.frequency,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
              if (protocol.notes != null && protocol.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
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
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
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

