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
  DateRange _selectedDateRange = DateRange.last7Days;

  final Map<String, DateRange> _timeRangeMap = {
    'Week': DateRange.last7Days,
    'Month': DateRange.last30Days,
    '3 Months': DateRange.last90Days,
    'All': DateRange.allTime,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load progress data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadProgress();
      context.read<ProtocolProvider>().loadProtocols();
    });
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
                children: _timeRangeMap.entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Text(entry.key),
                            selected: _selectedDateRange == entry.value,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedDateRange = entry.value);
                                // Update the progress provider with the new date range
                                context.read<ProgressProvider>().setDateRange(entry.value);
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
                _OverviewTab(dateRange: _selectedDateRange),
                _AdherenceTab(dateRange: _selectedDateRange),
                const _InsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final DateRange dateRange;

  const _OverviewTab({required this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProtocolProvider, ProgressProvider>(
      builder: (context, protocolProvider, progressProvider, _) {
        // Show content immediately - empty states will display if no data
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
                    value: '${progressProvider.totalDosesTaken}',
                    subtitle: 'completed',
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _StatCard(
                    icon: Icons.percent,
                    title: 'Adherence',
                    value: '${progressProvider.overallAdherence.round()}%',
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
                    value: '${progressProvider.currentStreak}',
                    subtitle: 'days',
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _StatCard(
                    icon: Icons.description,
                    title: 'Active',
                    value: '${protocolProvider.activeCount}',
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
                      child: _WeeklyActivityChart(progressProvider: progressProvider),
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
                    if (progressProvider.protocols.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Text(
                          'No active protocols',
                          style: AppTypography.body.copyWith(
                            color: AppColors.mediumGray,
                          ),
                        ),
                      )
                    else
                      ...progressProvider.protocols
                        .take(5)
                        .map((protocol) {
                        final adherence = progressProvider.protocolAdherence[protocol.id] ?? 0.0;
                      return _ProtocolProgressItem(
                        name: protocol.peptideName,
                          progress: adherence / 100,
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
}

class _AdherenceTab extends StatelessWidget {
  final DateRange dateRange;

  const _AdherenceTab({required this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProtocolProvider, ProgressProvider>(
      builder: (context, protocolProvider, progressProvider, _) {
        // Show content immediately - empty states will display if no data
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
                      child: _AdherenceTrendChart(progressProvider: progressProvider),
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
                    _TimeDistributionChart(progressProvider: progressProvider),
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
                    _MissedDosesSummary(
                      progressProvider: progressProvider,
                      protocolProvider: protocolProvider,
                    ),
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
  const _InsightsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, _) {
        // Show content immediately - empty state will display if no insights
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
  final ProgressProvider progressProvider;

  const _WeeklyActivityChart({required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    final weekData = progressProvider.getWeeklyAdherence();

    // Check if all days have zero doses (no data)
    final hasAnyDoses = weekData.any((d) => d.totalDoses > 0);
    
    if (weekData.isEmpty || !hasAnyDoses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: AppColors.mediumGray.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'No activity data yet',
              style: AppTypography.body.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Start a protocol to see your progress',
              style: AppTypography.caption1.copyWith(color: AppColors.mediumGray),
            ),
          ],
        ),
      );
    }

    // Find max doses for scaling
    final maxDoses = weekData.map((d) => d.totalDoses).fold(1, (a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekData.map((day) {
        const maxHeight = 100.0;
        final height = day.totalDoses > 0
            ? (day.dosesTaken / maxDoses) * maxHeight
            : 0.0;

        // Determine color based on adherence
        Color barColor;
        if (day.totalDoses == 0) {
          barColor = AppColors.lightGray;
        } else if (day.adherence >= 100) {
          barColor = AppColors.green;
        } else if (day.adherence >= 50) {
          barColor = AppColors.yellow;
        } else if (day.dosesTaken > 0) {
          barColor = AppColors.yellow.withOpacity(0.6);
        } else {
          barColor = AppColors.lightGray;
        }

        final dayName = _getDayAbbreviation(day.date.weekday);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (day.totalDoses > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${day.dosesTaken}/${day.totalDoses}',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.mediumGray,
                    fontSize: 10,
                  ),
                ),
              ),
            Container(
              width: 30,
              height: height.clamp(4.0, maxHeight),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: AppRadius.smallRadius,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dayName,
              style: AppTypography.caption2.copyWith(
                color: day.date.day == DateTime.now().day &&
                        day.date.month == DateTime.now().month
                    ? AppColors.primaryBlue
                    : AppColors.mediumGray,
                fontWeight: day.date.day == DateTime.now().day &&
                        day.date.month == DateTime.now().month
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getDayAbbreviation(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
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
  final ProgressProvider progressProvider;

  const _AdherenceTrendChart({required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    final weekData = progressProvider.getWeeklyAdherence();

    if (weekData.isEmpty || weekData.every((d) => d.totalDoses == 0)) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
              color: AppColors.mediumGray.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
              'No adherence data yet',
              style: AppTypography.body.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Track doses to see trends',
            style: AppTypography.caption1.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
    }

    // Build a simple line chart representation
    return Column(
      children: [
        // Chart area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekData.map((day) {
              const maxHeight = 140.0;
              final height = day.totalDoses > 0
                  ? (day.adherence / 100) * maxHeight
                  : 0.0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Adherence percentage label
                    if (day.totalDoses > 0)
                      Text(
                        '${day.adherence.round()}%',
                        style: AppTypography.caption2.copyWith(
                          color: _getAdherenceColor(day.adherence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: height.clamp(4.0, maxHeight),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _getAdherenceColor(day.adherence).withOpacity(0.7),
                            _getAdherenceColor(day.adherence),
                          ],
                        ),
                        borderRadius: AppRadius.smallRadius,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Day labels
        Row(
          children: weekData.map((day) {
            final isToday = day.date.day == DateTime.now().day &&
                day.date.month == DateTime.now().month &&
                day.date.year == DateTime.now().year;
            return Expanded(
              child: Text(
                _formatDayLabel(day.date),
                textAlign: TextAlign.center,
                style: AppTypography.caption2.copyWith(
                  color: isToday ? AppColors.primaryBlue : AppColors.mediumGray,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getAdherenceColor(double adherence) {
    if (adherence >= 90) return AppColors.green;
    if (adherence >= 70) return AppColors.yellow;
    if (adherence >= 50) return Colors.orange;
    return Colors.red.shade400;
  }

  String _formatDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class _TimeDistributionChart extends StatelessWidget {
  final ProgressProvider progressProvider;

  const _TimeDistributionChart({required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    // Calculate time slot distribution from hourly data
    final hourlyDistribution = progressProvider.hourlyDistribution;
    
    if (hourlyDistribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 40,
                color: AppColors.mediumGray.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'No dose timing data yet',
                style: AppTypography.body.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
        ),
      );
    }

    // Aggregate into time slots
    int morning = 0;   // 5 AM - 12 PM
    int afternoon = 0; // 12 PM - 5 PM
    int evening = 0;   // 5 PM - 9 PM
    int night = 0;     // 9 PM - 5 AM

    for (final entry in hourlyDistribution.entries) {
      final hour = entry.key;
      final count = entry.value;
      
      if (hour >= 5 && hour < 12) {
        morning += count;
      } else if (hour >= 12 && hour < 17) {
        afternoon += count;
      } else if (hour >= 17 && hour < 21) {
        evening += count;
      } else {
        night += count;
      }
    }

    final total = morning + afternoon + evening + night;
    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 40,
                color: AppColors.mediumGray.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'No dose timing data yet',
                style: AppTypography.body.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
        ),
      );
    }

    final timeSlots = [
      {'name': 'Morning', 'count': morning, 'icon': Icons.wb_sunny_outlined},
      {'name': 'Afternoon', 'count': afternoon, 'icon': Icons.wb_sunny},
      {'name': 'Evening', 'count': evening, 'icon': Icons.nights_stay_outlined},
      {'name': 'Night', 'count': night, 'icon': Icons.nights_stay},
    ];

    return Column(
      children: timeSlots.map((slot) {
        final count = slot['count'] as int;
        final percentage = (count / total * 100).round();
        final icon = slot['icon'] as IconData;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.mediumGray),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 80,
                child: Text(
                  slot['name'] as String,
                  style: AppTypography.body,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppColors.lightGray,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                  borderRadius: AppRadius.smallRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              SizedBox(
                width: 50,
                child: Text(
                  '$percentage% ($count)',
                  style: AppTypography.caption1,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MissedDosesSummary extends StatelessWidget {
  final ProgressProvider progressProvider;
  final ProtocolProvider protocolProvider;

  const _MissedDosesSummary({
    required this.progressProvider,
    required this.protocolProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Get missed doses from progressProvider's doses
    final missedDoses = progressProvider.doses
        .where((d) => d.status == DoseStatus.missed || d.status == DoseStatus.skipped)
        .take(5)
        .toList();

    final missedCount = progressProvider.totalDosesMissed;

    if (missedDoses.isEmpty && missedCount == 0) {
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
            Expanded(
              child: Text(
              'No missed doses! Keep it up!',
              style: AppTypography.body.copyWith(color: AppColors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missedCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Text(
              '$missedCount missed in this period',
              style: AppTypography.caption1.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ),
        ...missedDoses.map((dose) {
          final protocol = protocolProvider.getProtocolById(dose.protocolId);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              backgroundColor: dose.status == DoseStatus.missed 
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.yellow.withOpacity(0.1),
              child: Icon(
                dose.status == DoseStatus.missed ? Icons.close : Icons.skip_next, 
                color: dose.status == DoseStatus.missed ? Colors.red : AppColors.yellow,
              ),
          ),
            title: Text(protocol?.peptideName ?? 'Unknown Protocol'),
            subtitle: Text(
              '${_formatDate(dose.scheduledDate)} at ${dose.scheduledTime}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dose.status == DoseStatus.missed 
                    ? Colors.red.withOpacity(0.1)
                    : AppColors.yellow.withOpacity(0.1),
                borderRadius: AppRadius.smallRadius,
              ),
              child: Text(
                dose.status == DoseStatus.missed ? 'Missed' : 'Skipped',
                style: AppTypography.caption2.copyWith(
                  color: dose.status == DoseStatus.missed ? Colors.red : AppColors.yellow,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

