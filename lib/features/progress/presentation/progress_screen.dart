import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/dose.dart';
import '../../protocols/presentation/protocol_provider.dart';
import 'progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = 'Week';

  final List<String> _timeRanges = ['Week', 'Month', '3 Months', 'Year', 'All'];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Adherence'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Time Range Selector
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeRanges
                    .map((range) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Text(range),
                            selected: _selectedTimeRange == range,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedTimeRange = range);
                              }
                            },
                            selectedColor: AppColors.primaryBlue.withOpacity(0.1),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(timeRange: _selectedTimeRange),
                _AdherenceTab(timeRange: _selectedTimeRange),
                _InsightsTab(timeRange: _selectedTimeRange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String timeRange;

  const _OverviewTab({required this.timeRange});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProtocolProvider>(
      builder: (context, provider, _) {
        final stats = _calculateStats(provider);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    title: 'Total Doses',
                    value: '${stats['totalCompleted']}',
                    subtitle: 'completed',
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _StatCard(
                    icon: Icons.percent,
                    title: 'Adherence',
                    value: '${stats['adherence']}%',
                    subtitle: 'on time',
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
                    icon: Icons.local_fire_department,
                    title: 'Current Streak',
                    value: '${stats['streak']}',
                    subtitle: 'days',
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _StatCard(
                    icon: Icons.description,
                    title: 'Active',
                    value: '${stats['activeProtocols']}',
                    subtitle: 'protocols',
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.l),

            // Weekly Activity Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Activity', style: AppTypography.headline),
                    const SizedBox(height: AppSpacing.m),
                    SizedBox(
                      height: 150,
                      child: _WeeklyActivityChart(provider: provider),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // Protocol Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Protocol Progress', style: AppTypography.headline),
                    const SizedBox(height: AppSpacing.m),
                    ...provider.protocols
                        .where((p) => p.active)
                        .take(5)
                        .map((protocol) {
                      final progress = _getProtocolProgress(provider, protocol.id);
                      return _ProtocolProgressItem(
                        name: protocol.peptideName,
                        progress: progress,
                        color: AppColors.getCategoryColor(protocol.peptideName),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _calculateStats(ProtocolProvider provider) {
    final doses = provider.allDoses;
    final completed = doses.where((d) => d.status == DoseStatus.taken).length;
    final total = doses.where((d) =>
        d.status == DoseStatus.taken || d.status == DoseStatus.skipped).length;

    return {
      'totalCompleted': completed,
      'adherence': total > 0 ? ((completed / total) * 100).round() : 0,
      'streak': _calculateStreak(doses),
      'activeProtocols': provider.protocols.where((p) => p.active).length,
    };
  }

  int _calculateStreak(List<Dose> doses) {
    // Simple streak calculation
    int streak = 0;
    var currentDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final dayDoses = doses.where((d) =>
          d.scheduledDate.year == currentDate.year &&
          d.scheduledDate.month == currentDate.month &&
          d.scheduledDate.day == currentDate.day);

      if (dayDoses.isEmpty) {
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }

      final allCompleted = dayDoses.every((d) => d.status == DoseStatus.taken);
      if (allCompleted) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  double _getProtocolProgress(ProtocolProvider provider, String protocolId) {
    final doses = provider.getDosesForProtocol(protocolId);
    final completed = doses.where((d) => d.status == DoseStatus.taken).length;
    return doses.isNotEmpty ? completed / doses.length : 0;
  }
}

class _AdherenceTab extends StatelessWidget {
  final String timeRange;

  const _AdherenceTab({required this.timeRange});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProtocolProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // Adherence Trend Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adherence Trend', style: AppTypography.headline),
                    const SizedBox(height: AppSpacing.m),
                    SizedBox(
                      height: 200,
                      child: _AdherenceTrendChart(provider: provider),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // Time Distribution
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dose Distribution', style: AppTypography.headline),
                    const SizedBox(height: AppSpacing.m),
                    _TimeDistributionChart(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // Missed Doses Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.yellow),
                        const SizedBox(width: AppSpacing.xs),
                        Text('Missed Doses', style: AppTypography.headline),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _MissedDosesSummary(provider: provider),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InsightsTab extends StatelessWidget {
  final String timeRange;

  const _InsightsTab({required this.timeRange});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, _) {
        final insights = provider.getInsights();

        if (insights.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 64,
                  color: AppColors.mediumGray,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'No Insights Yet',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    'Keep tracking your doses to receive personalized insights',
                    style: AppTypography.body.copyWith(
                      color: AppColors.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final insight = insights[index];
            return _InsightCard(insight: insight);
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
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
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              value,
              style: AppTypography.largeTitle.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.caption1.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  final ProtocolProvider provider;

  const _WeeklyActivityChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final weekData = _getWeekData();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekData.map((day) {
        final maxHeight = 100.0;
        final height = day['completed']! > 0
            ? (day['completed']! / day['total']!) * maxHeight
            : 0.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height.clamp(4.0, maxHeight),
              decoration: BoxDecoration(
                color: day['completed'] == day['total']
                    ? AppColors.green
                    : day['completed']! > 0
                        ? AppColors.yellow
                        : AppColors.lightGray,
                borderRadius: AppRadius.smallRadius,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              day['day'] as String,
              style: AppTypography.caption2.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getWeekData() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayDoses = provider.allDoses.where((d) =>
          d.scheduledDate.year == date.year &&
          d.scheduledDate.month == date.month &&
          d.scheduledDate.day == date.day);

      return {
        'day': days[index],
        'total': dayDoses.length,
        'completed':
            dayDoses.where((d) => d.status == DoseStatus.taken).length,
      };
    });
  }
}

class _ProtocolProgressItem extends StatelessWidget {
  final String name;
  final double progress;
  final Color color;

  const _ProtocolProgressItem({
    required this.name,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTypography.body),
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.subhead.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: AppRadius.smallRadius,
          ),
        ],
      ),
    );
  }
}

class _AdherenceTrendChart extends StatelessWidget {
  final ProtocolProvider provider;

  const _AdherenceTrendChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Placeholder for actual chart
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: AppColors.primaryBlue.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Adherence chart visualization',
            style: AppTypography.caption1.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeDistributionChart extends StatelessWidget {
  const _TimeDistributionChart();

  @override
  Widget build(BuildContext context) {
    final timeSlots = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final values = [45, 25, 20, 10];

    return Column(
      children: List.generate(timeSlots.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  timeSlots[index],
                  style: AppTypography.body,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: values[index] / 100,
                  backgroundColor: AppColors.lightGray,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                  borderRadius: AppRadius.smallRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              SizedBox(
                width: 40,
                child: Text(
                  '${values[index]}%',
                  style: AppTypography.caption1,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MissedDosesSummary extends StatelessWidget {
  final ProtocolProvider provider;

  const _MissedDosesSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final missedDoses = provider.allDoses
        .where((d) => d.status == DoseStatus.skipped)
        .take(5)
        .toList();

    if (missedDoses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.1),
          borderRadius: AppRadius.mediumRadius,
        ),
        child: Row(
          children: [
            Icon(Icons.celebration, color: AppColors.green),
            const SizedBox(width: AppSpacing.s),
            Text(
              'No missed doses! Keep it up!',
              style: AppTypography.body.copyWith(color: AppColors.green),
            ),
          ],
        ),
      );
    }

    return Column(
      children: missedDoses.map((dose) {
        final protocol = provider.getProtocolById(dose.protocolId);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.yellow.withOpacity(0.1),
            child: Icon(Icons.skip_next, color: AppColors.yellow),
          ),
          title: Text(protocol?.peptideName ?? 'Unknown'),
          subtitle: Text(_formatDate(dose.scheduledDate)),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final type = insight['type'] as String;
    final color = type == 'success'
        ? AppColors.green
        : type == 'warning'
            ? AppColors.yellow
            : AppColors.primaryBlue;
    final icon = type == 'success'
        ? Icons.check_circle
        : type == 'warning'
            ? Icons.warning_amber
            : Icons.lightbulb;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight['title'] as String,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    insight['description'] as String,
                    style: AppTypography.body.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

