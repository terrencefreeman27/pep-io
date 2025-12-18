import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/protocol.dart';
import '../../../core/models/dose.dart';
import 'protocol_provider.dart';

class ProtocolDetailScreen extends StatefulWidget {
  final String protocolId;

  const ProtocolDetailScreen({super.key, required this.protocolId});

  @override
  State<ProtocolDetailScreen> createState() => _ProtocolDetailScreenState();
}

class _ProtocolDetailScreenState extends State<ProtocolDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProtocolProvider>(
      builder: (context, provider, _) {
        final protocol = provider.getProtocolById(widget.protocolId);

        if (protocol == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Protocol')),
            body: const Center(child: Text('Protocol not found')),
          );
        }

        final categoryColor = AppColors.getCategoryColor(protocol.peptideName);
        final doses = provider.getDosesForProtocol(protocol.id);

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor,
                            categoryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (!protocol.active)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s,
                                        vertical: AppSpacing.xxs,
                                      ),
                                      margin: const EdgeInsets.only(
                                        bottom: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: AppRadius.smallRadius,
                                      ),
                                      child: const Text(
                                        'PAUSED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                protocol.peptideName,
                                style: AppTypography.largeTitle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                protocol.formattedDosage,
                                style: AppTypography.headline.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.protocolEdit,
                        arguments: protocol.id,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOptions(context, protocol),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: categoryColor,
                    indicatorColor: categoryColor,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Schedule'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(protocol: protocol, doses: doses),
                _ScheduleTab(protocol: protocol, doses: doses),
                _HistoryTab(protocol: protocol, doses: doses),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOptions(BuildContext context, Protocol protocol) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                protocol.active
                    ? Icons.pause_outlined
                    : Icons.play_arrow_outlined,
              ),
              title:
                  Text(protocol.active ? 'Pause Protocol' : 'Resume Protocol'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProtocolProvider>().toggleProtocolActive(
                      protocol.id,
                      !protocol.active,
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                protocol.syncToCalendar
                    ? 'Remove from Calendar'
                    : 'Add to Calendar',
              ),
              onTap: () {
                Navigator.pop(context);
                // Toggle calendar sync
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
                _confirmDelete(context, protocol);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Protocol protocol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Protocol?'),
        content: Text(
          'Are you sure you want to delete the ${protocol.peptideName} protocol? This will also delete all dose history. This action cannot be undone.',
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
              Navigator.pop(context);
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

class _OverviewTab extends StatelessWidget {
  final Protocol protocol;
  final List<Dose> doses;

  const _OverviewTab({required this.protocol, required this.doses});

  @override
  Widget build(BuildContext context) {
    final completedDoses =
        doses.where((d) => d.status == DoseStatus.taken).length;
    final totalDoses = doses.length;
    final adherenceRate =
        totalDoses > 0 ? (completedDoses / totalDoses * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        // Statistics cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                label: 'Adherence',
                value: '$adherenceRate%',
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_outlined,
                label: 'Total Doses',
                value: '$completedDoses',
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                label: 'Streak',
                value: '${_calculateStreak()} days',
                color: AppColors.yellow,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: _StatCard(
                icon: Icons.history,
                label: 'Duration',
                value: _calculateDuration(),
                color: AppColors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.l),

        // Protocol details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Protocol Details', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.m),
                _DetailRow(
                  icon: Icons.medication_outlined,
                  label: 'Dosage',
                  value: protocol.formattedDosage,
                ),
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'Frequency',
                  value: protocol.frequency,
                ),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Start Date',
                  value: _formatDate(protocol.startDate),
                ),
                if (protocol.endDate != null)
                  _DetailRow(
                    icon: Icons.event,
                    label: 'End Date',
                    value: _formatDate(protocol.endDate!),
                  ),
                _DetailRow(
                  icon: Icons.sync,
                  label: 'Calendar Sync',
                  value: protocol.syncToCalendar ? 'Enabled' : 'Disabled',
                ),
              ],
            ),
          ),
        ),

        if (protocol.notes != null && protocol.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: AppTypography.headline),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    protocol.notes!,
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  int _calculateStreak() {
    // Calculate consecutive days of completed doses
    return 0; // Placeholder
  }

  String _calculateDuration() {
    final days = DateTime.now().difference(protocol.startDate).inDays;
    if (days < 7) return '$days days';
    if (days < 30) return '${days ~/ 7} weeks';
    return '${days ~/ 30} months';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.s),
            Text(value, style: AppTypography.title2.copyWith(color: color)),
            Text(
              label,
              style: AppTypography.caption1.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.mediumGray),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.mediumGray),
            ),
          ),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  final Protocol protocol;
  final List<Dose> doses;

  const _ScheduleTab({required this.protocol, required this.doses});

  @override
  Widget build(BuildContext context) {
    final upcomingDoses = doses
        .where((d) =>
            d.status == DoseStatus.scheduled &&
            d.scheduledDate.isAfter(
              DateTime.now().subtract(const Duration(hours: 1)),
            ))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    if (upcomingDoses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: AppColors.mediumGray,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'No Upcoming Doses',
              style: AppTypography.headline.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'All scheduled doses are complete',
              style: AppTypography.body.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: upcomingDoses.length,
      itemBuilder: (context, index) {
        final dose = upcomingDoses[index];
        return _DoseCard(dose: dose);
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final Protocol protocol;
  final List<Dose> doses;

  const _HistoryTab({required this.protocol, required this.doses});

  @override
  Widget build(BuildContext context) {
    final completedDoses = doses
        .where((d) =>
            d.status == DoseStatus.taken || d.status == DoseStatus.skipped)
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    if (completedDoses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.mediumGray,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'No History Yet',
              style: AppTypography.headline.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Completed doses will appear here',
              style: AppTypography.body.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: completedDoses.length,
      itemBuilder: (context, index) {
        final dose = completedDoses[index];
        return _DoseCard(dose: dose, showStatus: true);
      },
    );
  }
}

class _DoseCard extends StatelessWidget {
  final Dose dose;
  final bool showStatus;

  const _DoseCard({required this.dose, this.showStatus = false});

  @override
  Widget build(BuildContext context) {
    final isCompleted = dose.status == DoseStatus.taken;
    final isSkipped = dose.status == DoseStatus.skipped;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? AppColors.green.withOpacity(0.1)
              : isSkipped
                  ? AppColors.yellow.withOpacity(0.1)
                  : AppColors.primaryBlue.withOpacity(0.1),
          child: Icon(
            isCompleted
                ? Icons.check
                : isSkipped
                    ? Icons.skip_next
                    : Icons.schedule,
            color: isCompleted
                ? AppColors.green
                : isSkipped
                    ? AppColors.yellow
                    : AppColors.primaryBlue,
          ),
        ),
        title: Text(
          _formatDateTime(dose.scheduledDate, dose.scheduledTime),
          style: AppTypography.headline,
        ),
        subtitle: showStatus
            ? Text(
                isCompleted
                    ? 'Completed${dose.actualTime != null ? ' at ${_formatTime(dose.actualTime!)}' : ''}'
                    : 'Skipped',
                style: AppTypography.caption1,
              )
            : null,
        trailing: !showStatus
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    color: AppColors.green,
                    onPressed: () {
                      context.read<ProtocolProvider>().logDose(
                            dose.id,
                            DoseStatus.taken,
                          );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_outlined),
                    color: AppColors.yellow,
                    onPressed: () {
                      context.read<ProtocolProvider>().logDose(
                            dose.id,
                            DoseStatus.skipped,
                          );
                    },
                  ),
                ],
              )
            : null,
      ),
    );
  }

  String _formatDateTime(DateTime date, String time) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isTomorrow = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1;

    String dateStr;
    if (isToday) {
      dateStr = 'Today';
    } else if (isTomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${date.month}/${date.day}';
    }

    return '$dateStr at $time';
  }

  String _formatTime(String time) {
    // Time is already formatted as a string
    return time;
  }
}

