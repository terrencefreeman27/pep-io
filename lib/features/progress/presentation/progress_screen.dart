import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/dose.dart';
import '../../../core/widgets/animated_widgets.dart';
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
        title: Text('Progress', style: AppTypography.title3),
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
                children: _timeRangeMap.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final mapEntry = entry.value;
                  
                  return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _TimeRangeChip(
                      label: mapEntry.key,
                      isSelected: _selectedDateRange == mapEntry.value,
                      onTap: () {
                        setState(() => _selectedDateRange = mapEntry.value);
                        context.read<ProgressProvider>().setDateRange(mapEntry.value);
                      },
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50));
                }).toList(),
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

class _TimeRangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeRangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BouncyTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(isDark ? 0.3 : 0.15)
              : isDark ? AppColors.cardDark : AppColors.softGray,
          borderRadius: AppRadius.fullRadius,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? AppShadows.glow(AppColors.primaryBlue, intensity: 0.2)
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.subhead.copyWith(
            color: isSelected ? AppColors.primaryBlue : AppColors.mediumGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: AnimatedMetricCard(
                    icon: Icons.check_circle_outline,
                    value: '${progressProvider.totalDosesTaken}',
                    label: 'Total Doses',
                    color: AppColors.green,
                    animationIndex: 0,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AnimatedMetricCard(
                    icon: Icons.percent,
                    value: '${progressProvider.overallAdherence.round()}%',
                    label: 'Adherence',
                    color: AppColors.primaryBlue,
                    animationIndex: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.m),

            Row(
              children: [
                Expanded(
                  child: AnimatedMetricCard(
                    icon: Icons.local_fire_department_outlined,
                    value: '${progressProvider.currentStreak}',
                    label: 'Day Streak',
                    color: AppColors.orange,
                    animationIndex: 2,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AnimatedMetricCard(
                    icon: Icons.science_outlined,
                    value: '${protocolProvider.activeCount}',
                    label: 'Active Protocols',
                    color: AppColors.purple,
                    animationIndex: 3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.l),

            // Weekly Activity Chart
            _AnimatedCard(
              index: 4,
              title: 'Weekly Activity',
              icon: Icons.bar_chart_outlined,
              color: AppColors.teal,
              child: SizedBox(
                      height: 150,
                      child: _WeeklyActivityChart(progressProvider: progressProvider),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // Protocol Progress
            _AnimatedCard(
              index: 5,
              title: 'Protocol Progress',
              icon: Icons.trending_up,
              color: AppColors.purple,
              child: progressProvider.protocols.isEmpty
                  ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Text(
                          'No active protocols',
                        style: AppTypography.body.copyWith(color: AppColors.mediumGray),
                        ),
                      )
                  : Column(
                      children: progressProvider.protocols.take(5).map((protocol) {
                        final adherence = progressProvider.protocolAdherence[protocol.id] ?? 0.0;
                      return _ProtocolProgressItem(
                        name: protocol.peptideName,
                          progress: adherence / 100,
                        color: AppColors.getCategoryColor(protocol.peptideName),
                      );
                      }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // Achievements Section
            _AnimatedCard(
              index: 6,
              title: 'Achievements',
              icon: Icons.emoji_events_outlined,
              color: AppColors.orange,
              child: _AchievementBadges(
                currentStreak: progressProvider.currentStreak,
                longestStreak: progressProvider.longestStreak,
                totalDoses: progressProvider.totalDosesTaken,
                protocolCount: protocolProvider.activeCount,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AchievementBadges extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int totalDoses;
  final int protocolCount;

  const _AchievementBadges({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDoses,
    required this.protocolCount,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = <_Achievement>[
      // First protocol - always show
      _Achievement(
        name: 'First Protocol',
        description: 'Started your journey',
        imagePath: 'assets/images/badge_first_protocol.png',
        color: AppColors.teal,
        isUnlocked: protocolCount >= 1,
        currentValue: protocolCount.clamp(0, 1),
        requiredValue: 1,
        requirementLabel: 'Create your first protocol',
      ),
      // Streak badge
      _Achievement(
        name: '7 Day Streak',
        description: 'Keep the momentum going!',
        imagePath: 'assets/images/badge_streak.png',
        color: AppColors.orange,
        isUnlocked: currentStreak >= 7,
        currentValue: currentStreak.clamp(0, 7),
        requiredValue: 7,
        requirementLabel: 'Maintain a 7 day streak',
      ),
      // Perfect week
      _Achievement(
        name: 'Perfect Week',
        description: '7 days of consistency',
        imagePath: 'assets/images/badge_perfect_week.png',
        color: AppColors.primaryBlue,
        isUnlocked: longestStreak >= 7,
        currentValue: longestStreak.clamp(0, 7),
        requiredValue: 7,
        requirementLabel: 'Complete 7 perfect days',
      ),
      // Century badge (100 doses)
      _Achievement(
        name: 'Century Club',
        description: '100 doses completed',
        imagePath: 'assets/images/badge_century.png',
        color: AppColors.yellow,
        isUnlocked: totalDoses >= 100,
        currentValue: totalDoses.clamp(0, 100),
        requiredValue: 100,
        requirementLabel: 'Take 100 doses total',
      ),
      // Early bird badge
      _Achievement(
        name: 'Early Bird',
        description: 'Morning dose champion',
        imagePath: 'assets/images/badge_early_bird.png',
        color: AppColors.orange,
        isUnlocked: totalDoses >= 10,
        currentValue: totalDoses.clamp(0, 10),
        requiredValue: 10,
        requirementLabel: 'Take 10 morning doses',
      ),
      // Night owl badge
      _Achievement(
        name: 'Night Owl',
        description: 'Evening protocol master',
        imagePath: 'assets/images/badge_night_owl.png',
        color: AppColors.purple,
        isUnlocked: totalDoses >= 10,
        currentValue: totalDoses.clamp(0, 10),
        requiredValue: 10,
        requirementLabel: 'Take 10 evening doses',
      ),
      // Knowledge seeker badge
      _Achievement(
        name: 'Knowledge Seeker',
        description: 'Explored the library',
        imagePath: 'assets/images/badge_knowledge.png',
        color: AppColors.primaryBlue,
        isUnlocked: protocolCount >= 3,
        currentValue: protocolCount.clamp(0, 3),
        requiredValue: 3,
        requirementLabel: 'Create 3 different protocols',
      ),
      // Consistency champion (30+ day streak)
      _Achievement(
        name: 'Consistency Champion',
        description: '30 days of dedication',
        imagePath: 'assets/images/badge_consistency.png',
        color: AppColors.purple,
        isUnlocked: longestStreak >= 30,
        currentValue: longestStreak.clamp(0, 30),
        requiredValue: 30,
        requirementLabel: 'Achieve a 30 day streak',
      ),
    ];

    if (achievements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppColors.mediumGray.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'No achievements yet',
                style: AppTypography.body.copyWith(color: AppColors.mediumGray),
              ),
              Text(
                'Keep tracking to unlock badges!',
                style: AppTypography.caption1.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: achievements.map((achievement) {
        return _AchievementBadge(achievement: achievement);
      }).toList(),
    );
  }
}

class _Achievement {
  final String name;
  final String description;
  final String imagePath;
  final Color color;
  final bool isUnlocked;
  final int currentValue;
  final int requiredValue;
  final String requirementLabel;

  const _Achievement({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.color,
    required this.isUnlocked,
    required this.currentValue,
    required this.requiredValue,
    required this.requirementLabel,
  });

  double get progress => requiredValue > 0 
      ? (currentValue / requiredValue).clamp(0.0, 1.0) 
      : 0.0;
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  void _showAchievementDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: AppRadius.largeRadius,
          border: Border.all(
            color: achievement.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: AppShadows.glow(achievement.color, intensity: 0.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mediumGray.withOpacity(0.3),
                borderRadius: AppRadius.fullRadius,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            
            // Badge image with glow effect
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: achievement.isUnlocked
                    ? achievement.color.withOpacity(0.15)
                    : (isDark ? AppColors.surfaceDark : AppColors.lightGray),
                boxShadow: achievement.isUnlocked
                    ? AppShadows.glow(achievement.color, intensity: 0.5)
                    : null,
              ),
              child: Opacity(
                opacity: achievement.isUnlocked ? 1.0 : 0.4,
                child: ClipOval(
                  child: Image.asset(
                    achievement.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.emoji_events,
                        color: achievement.isUnlocked
                            ? achievement.color
                            : AppColors.mediumGray,
                        size: 56,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            
            // Badge name
            Text(
              achievement.name,
              style: AppTypography.title3.copyWith(
                color: achievement.isUnlocked 
                    ? achievement.color 
                    : (isDark ? AppColors.white : AppColors.black),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            
            // Description
            Text(
              achievement.description,
              style: AppTypography.body.copyWith(
                color: AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.l),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? AppColors.green.withOpacity(0.15)
                    : achievement.color.withOpacity(0.1),
                borderRadius: AppRadius.fullRadius,
                border: Border.all(
                  color: achievement.isUnlocked
                      ? AppColors.green.withOpacity(0.5)
                      : achievement.color.withOpacity(0.3),
                ),
              ),
              child: Text(
                achievement.isUnlocked ? '✓ Unlocked!' : 'In Progress',
                style: AppTypography.subhead.copyWith(
                  color: achievement.isUnlocked 
                      ? AppColors.green 
                      : achievement.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            
            // Requirement text
            Text(
              achievement.requirementLabel,
              style: AppTypography.subhead.copyWith(
                color: isDark ? AppColors.white : AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            
            // Progress bar with values
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.surfaceDark 
                    : AppColors.softGray.withOpacity(0.5),
                borderRadius: AppRadius.mediumRadius,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Progress',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                      Text(
                        '${achievement.currentValue} / ${achievement.requiredValue}',
                        style: AppTypography.headline.copyWith(
                          color: achievement.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: achievement.progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Stack(
                        children: [
                          // Background track
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? AppColors.cardDark 
                                  : AppColors.lightGray,
                              borderRadius: AppRadius.fullRadius,
                            ),
                          ),
                          // Progress fill
                          FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    achievement.color.withOpacity(0.8),
                                    achievement.color,
                                  ],
                                ),
                                borderRadius: AppRadius.fullRadius,
                                boxShadow: AppShadows.glow(
                                  achievement.color, 
                                  intensity: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${(achievement.progress * 100).round()}% complete',
                    style: AppTypography.caption2.copyWith(
                      color: achievement.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: BouncyTap(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  decoration: BoxDecoration(
                    color: achievement.color.withOpacity(0.15),
                    borderRadius: AppRadius.mediumRadius,
                    border: Border.all(
                      color: achievement.color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: AppTypography.headline.copyWith(
                      color: achievement.color,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTap(
      onTap: () => _showAchievementDetails(context),
      child: Opacity(
        opacity: achievement.isUnlocked ? 1.0 : 0.5,
        child: SizedBox(
          width: 80,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: achievement.isUnlocked
                          ? achievement.color.withOpacity(0.1)
                          : (isDark ? AppColors.cardDark : AppColors.lightGray),
                      boxShadow: achievement.isUnlocked
                          ? AppShadows.glow(achievement.color, intensity: 0.3)
                          : null,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        achievement.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.emoji_events,
                            color: achievement.isUnlocked
                                ? achievement.color
                                : AppColors.mediumGray,
                            size: 32,
                          );
                        },
                      ),
                    ),
                  ),
                  // Progress ring for locked badges
                  if (!achievement.isUnlocked)
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: achievement.progress,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(
                          achievement.color.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                style: AppTypography.caption2.copyWith(
                  color: achievement.isUnlocked
                      ? (isDark ? AppColors.white : AppColors.black)
                      : AppColors.mediumGray,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn();
  }
}

class _AdherenceTab extends StatelessWidget {
  final DateRange dateRange;

  const _AdherenceTab({required this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProtocolProvider, ProgressProvider>(
      builder: (context, protocolProvider, progressProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // Adherence Trend Chart
            _AnimatedCard(
              index: 0,
              title: 'Adherence Trend',
              icon: Icons.show_chart,
              color: AppColors.primaryBlue,
              child: SizedBox(
                      height: 200,
                      child: _AdherenceTrendChart(progressProvider: progressProvider),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // Time Distribution
            _AnimatedCard(
              index: 1,
              title: 'Dose Distribution',
              icon: Icons.schedule,
              color: AppColors.teal,
              child: _TimeDistributionChart(progressProvider: progressProvider),
            ),

            const SizedBox(height: AppSpacing.m),

            // Missed Doses Summary
            _AnimatedCard(
              index: 2,
              title: 'Missed Doses',
              icon: Icons.warning_amber_outlined,
              color: AppColors.yellow,
              child: _MissedDosesSummary(
                      progressProvider: progressProvider,
                      protocolProvider: protocolProvider,
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
        final insights = provider.getInsights();

        if (insights.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.lightbulb_outline,
            title: 'No Insights Yet',
            subtitle: 'Keep tracking your doses to receive personalized insights',
            iconColor: AppColors.yellow,
            imagePath: 'assets/images/empty_progress.png',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final insight = insights[index];
            return AnimatedListItem(
              index: index,
              child: _InsightCard(insight: insight),
            );
          },
        );
      },
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _AnimatedCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: AppRadius.largeRadius,
        border: Border.all(
          color: isDark ? AppColors.cardDark : AppColors.lightGray.withOpacity(0.5),
        ),
        boxShadow: isDark ? null : AppShadows.level1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: Icon(icon, color: color, size: 18),
            ),
                const SizedBox(width: AppSpacing.s),
                Text(title, style: AppTypography.headline),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            child,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 100), duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  final ProgressProvider progressProvider;

  const _WeeklyActivityChart({required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    final weekData = progressProvider.getWeeklyAdherence();
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
          ],
        ),
      );
    }

    final maxDoses = weekData.map((d) => d.totalDoses).fold(1, (a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekData.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        const maxHeight = 100.0;
        final height = day.totalDoses > 0 ? (day.dosesTaken / maxDoses) * maxHeight : 0.0;

        Color barColor;
        if (day.totalDoses == 0) {
          barColor = AppColors.lightGray;
        } else if (day.adherence >= 100) {
          barColor = AppColors.green;
        } else if (day.adherence >= 50) {
          barColor = AppColors.yellow;
        } else {
          barColor = AppColors.lightGray;
        }

        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.date.weekday - 1];
        final isToday = day.date.day == DateTime.now().day &&
            day.date.month == DateTime.now().month;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (day.totalDoses > 0)
              Text(
                  '${day.dosesTaken}/${day.totalDoses}',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.mediumGray,
                    fontSize: 10,
                  ),
                ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height.clamp(4.0, maxHeight),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    barColor.withOpacity(0.7),
                    barColor,
                  ],
                ),
                borderRadius: AppRadius.smallRadius,
                boxShadow: day.adherence >= 100
                    ? AppShadows.glow(AppColors.green, intensity: 0.3)
                    : null,
              ),
            )
                .animate()
                .scaleY(
                  begin: 0,
                  end: 1,
                  alignment: Alignment.bottomCenter,
                  delay: Duration(milliseconds: index * 100),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dayName,
              style: AppTypography.caption2.copyWith(
                color: isToday ? AppColors.primaryBlue : AppColors.mediumGray,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
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
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: AppRadius.smallRadius,
              );
            },
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
              style: AppTypography.body.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekData.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              const maxHeight = 140.0;
              final height = day.totalDoses > 0
                  ? (day.adherence / 100) * maxHeight
                  : 0.0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (day.totalDoses > 0)
                      Text(
                        '${day.adherence.round()}%',
                        style: AppTypography.caption2.copyWith(
                          color: _getAdherenceColor(day.adherence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
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
                    )
                        .animate()
                        .scaleY(
                          begin: 0,
                          end: 1,
                          alignment: Alignment.bottomCenter,
                          delay: Duration(milliseconds: index * 100),
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: weekData.map((day) {
            final isToday = day.date.day == DateTime.now().day &&
                day.date.month == DateTime.now().month &&
                day.date.year == DateTime.now().year;
            return Expanded(
              child: Text(
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.date.weekday - 1],
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
}

class _TimeDistributionChart extends StatelessWidget {
  final ProgressProvider progressProvider;

  const _TimeDistributionChart({required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    final hourlyDistribution = progressProvider.hourlyDistribution;
    
    if (hourlyDistribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              Icon(Icons.schedule, size: 40, color: AppColors.mediumGray.withOpacity(0.5)),
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

    int morning = 0, afternoon = 0, evening = 0, night = 0;

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
    if (total == 0) return const SizedBox.shrink();

    final timeSlots = [
      {'name': 'Morning', 'count': morning, 'icon': Icons.wb_sunny_outlined, 'color': AppColors.yellow},
      {'name': 'Afternoon', 'count': afternoon, 'icon': Icons.wb_sunny, 'color': AppColors.orange},
      {'name': 'Evening', 'count': evening, 'icon': Icons.nights_stay_outlined, 'color': AppColors.purple},
      {'name': 'Night', 'count': night, 'icon': Icons.nights_stay, 'color': AppColors.indigo},
    ];

    return Column(
      children: timeSlots.asMap().entries.map((entry) {
        final index = entry.key;
        final slot = entry.value;
        final count = slot['count'] as int;
        final percentage = (count / total * 100).round();
        final icon = slot['icon'] as IconData;
        final color = slot['color'] as Color;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppRadius.smallRadius,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 80,
                child: Text(slot['name'] as String, style: AppTypography.body),
              ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage / 100),
                  duration: Duration(milliseconds: 800 + index * 200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                  backgroundColor: AppColors.lightGray,
                      valueColor: AlwaysStoppedAnimation(color),
                  borderRadius: AppRadius.smallRadius,
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              SizedBox(
                width: 50,
                child: Text(
                  '$percentage%',
                  style: AppTypography.caption1.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .slideX(begin: 0.05, end: 0);
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
    final missedDoses = progressProvider.doses
        .where((d) => d.status == DoseStatus.missed || d.status == DoseStatus.skipped)
        .take(5)
        .toList();

    final missedCount = progressProvider.totalDosesMissed;

    if (missedDoses.isEmpty && missedCount == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.green.withOpacity(0.15),
              AppColors.green.withOpacity(0.05),
            ],
          ),
          borderRadius: AppRadius.mediumRadius,
          border: Border.all(color: AppColors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration, color: AppColors.green),
            ),
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
          Text(
              '$missedCount missed in this period',
            style: AppTypography.caption1.copyWith(color: AppColors.mediumGray),
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
            subtitle: Text(dose.scheduledTime),
          );
        }),
      ],
    );
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: AppRadius.largeRadius,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
        boxShadow: AppShadows.glow(color, intensity: 0.1),
      ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
            width: 44,
            height: 44,
              decoration: BoxDecoration(
              gradient: AppColors.getGradientForColor(color),
              borderRadius: AppRadius.mediumRadius,
              ),
            child: Icon(icon, color: Colors.white),
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
    );
  }
}
