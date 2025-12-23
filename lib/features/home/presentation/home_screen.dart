import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/dose.dart';
import '../../protocols/presentation/protocol_provider.dart';
import '../../settings/presentation/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProtocolProvider>().loadProtocols();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _handleRefresh() async {
    await context.read<ProtocolProvider>().loadProtocols();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              
              // Metric Cards
              SliverToBoxAdapter(
                child: _buildMetricCards(context),
              ),
              
              // Today's Doses
              SliverToBoxAdapter(
                child: _buildTodaysDoses(context),
              ),
              
              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(context),
              ),
              
              // Resume Draft Card
              SliverToBoxAdapter(
                child: _buildResumeDraftCard(context),
              ),
              
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final name = settings.userProfile?.name;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: Icon(
                Icons.person_outline,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                Text(
                  name ?? 'Welcome',
                  style: AppTypography.title3,
                ),
              ],
            ),
          ),
          
          // Settings
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context) {
    final provider = context.watch<ProtocolProvider>();
    
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        children: [
          _MetricCard(
            icon: Icons.checklist_outlined,
            iconColor: AppColors.purple,
            value: '${provider.activeCount}',
            label: 'Active Protocols',
            gradient: AppColors.purpleGradient,
          ),
          _MetricCard(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.green,
            value: '${provider.adherenceRate.toStringAsFixed(0)}%',
            label: 'Adherence',
            gradient: AppColors.greenGradient,
          ),
          _MetricCard(
            icon: Icons.local_fire_department_outlined,
            iconColor: AppColors.orange,
            value: '${provider.currentStreak}',
            label: 'Day Streak',
            gradient: AppColors.orangeGradient,
          ),
          _MetricCard(
            icon: Icons.access_time,
            iconColor: AppColors.primaryBlue,
            value: _getNextDoseTime(provider),
            label: 'Next Dose',
            gradient: AppColors.blueGradient,
          ),
        ],
      ),
    );
  }

  String _getNextDoseTime(ProtocolProvider provider) {
    final upcomingDoses = provider.todaysDoses
        .where((d) => d.status == DoseStatus.scheduled && d.isUpcoming)
        .toList();
    
    if (upcomingDoses.isEmpty) return '--';
    
    upcomingDoses.sort((a, b) => 
        a.scheduledDateTime.compareTo(b.scheduledDateTime));
    
    final nextDose = upcomingDoses.first;
    final diff = nextDose.scheduledDateTime.difference(DateTime.now());
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    return '${diff.inHours}h';
  }

  Widget _buildTodaysDoses(BuildContext context) {
    final provider = context.watch<ProtocolProvider>();
    final doses = provider.todaysDoses;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Doses",
                style: AppTypography.headline,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to calendar
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          
          if (doses.isEmpty)
            _buildEmptyDosesCard(context)
          else
            ...doses.take(3).map((dose) => _DoseCard(
              dose: dose,
              protocol: provider.protocols.firstWhere(
                (p) => p.id == dose.protocolId,
                orElse: () => throw Exception('Protocol not found'),
              ),
              onMarkTaken: () => provider.markDoseAsTaken(dose.id),
            )),
        ],
      ),
    );
  }

  Widget _buildEmptyDosesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'No doses scheduled today',
            style: AppTypography.headline.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add a protocol to get started',
            style: AppTypography.footnote.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: AppSpacing.m),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
            icon: const Icon(Icons.add),
            label: const Text('Add Protocol'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.calculate_outlined,
              label: 'Calculator',
              onTap: () => Navigator.pushNamed(context, AppRoutes.calculator),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'New Protocol',
              onTap: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.menu_book_outlined,
              label: 'Library',
              onTap: () => Navigator.pushNamed(context, AppRoutes.library),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.analytics_outlined,
              label: 'Progress',
              onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeDraftCard(BuildContext context) {
    final storage = context.read<StorageService>();
    
    if (!storage.hasDraftProtocol) {
      return const SizedBox.shrink();
    }
    
    // Parse draft to get peptide name for display
    String draftPeptideName = 'Unnamed Protocol';
    final draftJson = storage.draftProtocol;
    if (draftJson != null) {
      try {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        final peptideName = draft['peptideName'] as String?;
        if (peptideName != null && peptideName.isNotEmpty) {
          draftPeptideName = peptideName;
        }
      } catch (e) {
        // Ignore parse errors
      }
    }
    
    // Format timestamp
    String timeAgo = '';
    final timestamp = storage.draftProtocolTimestamp;
    if (timestamp != null) {
      final diff = DateTime.now().difference(timestamp);
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mediumRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.orange.withOpacity(0.12),
              AppColors.orange.withOpacity(0.04),
            ],
          ),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.orange,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unfinished Protocol',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$draftPeptideName • $timeAgo',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Discard button
                IconButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Discard Draft?'),
                        content: const Text('Are you sure you want to discard this unfinished protocol?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Discard',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await storage.clearDraftProtocol();
                      if (context.mounted) {
                        setState(() {});
                      }
                    }
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.mediumGray,
                    size: 22,
                  ),
                  tooltip: 'Discard draft',
                ),
                
                // Resume button
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.protocolCreate).then((_) {
                      // Refresh when returning to check if draft was cleared
                      setState(() {});
                    });
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Resume'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final LinearGradient gradient;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        borderRadius: AppRadius.largeRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient.colors.first.withOpacity(0.15),
            gradient.colors.last.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.2),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.title2.copyWith(
              color: iconColor,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: AppColors.mediumGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DoseCard extends StatefulWidget {
  final Dose dose;
  final dynamic protocol;
  final VoidCallback onMarkTaken;

  const _DoseCard({
    required this.dose,
    required this.protocol,
    required this.onMarkTaken,
  });

  @override
  State<_DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends State<_DoseCard> with SingleTickerProviderStateMixin {
  bool _showCelebration = false;
  bool _justTaken = false;
  late AnimationController _animationController;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Generate confetti particles
    final random = Random();
    for (int i = 0; i < 12; i++) {
      _particles.add(_ConfettiParticle(
        angle: (i / 12) * 2 * pi,
        speed: 60 + random.nextDouble() * 40,
        color: [
          AppColors.green,
          AppColors.primaryBlue,
          AppColors.yellow,
          AppColors.purple,
          AppColors.orange,
        ][random.nextInt(5)],
        size: 4 + random.nextDouble() * 4,
      ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTake() async {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() {
      _showCelebration = true;
      _justTaken = true;
    });
    
    _animationController.forward();
    
    // Call the actual take action
    widget.onMarkTaken();
    
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      setState(() => _showCelebration = false);
      _animationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.dose.isOverdue;
    final isDueSoon = widget.dose.isDueSoon;
    final isTaken = widget.dose.status == DoseStatus.taken || _justTaken;
    
    Color statusColor = AppColors.mediumGray;
    String statusText = 'Upcoming';
    IconData statusIcon = Icons.schedule;
    
    if (isTaken) {
      statusColor = AppColors.green;
      statusText = 'Taken';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = AppColors.error;
      statusText = 'Overdue';
      statusIcon = Icons.error_outline;
    } else if (isDueSoon) {
      statusColor = AppColors.warning;
      statusText = 'Due now';
      statusIcon = Icons.access_time;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Simple scale animation using sin for bounce effect
        final progress = _animationController.value;
        final scaleValue = _showCelebration 
            ? 1.0 + (sin(progress * pi) * 0.05) 
            : 1.0;
        final checkScale = _showCelebration 
            ? Curves.elasticOut.transform(progress.clamp(0.0, 1.0))
            : 1.0;
            
        return Transform.scale(
          scale: scaleValue,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main card
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: AppSpacing.s),
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mediumRadius,
                  color: _showCelebration 
                      ? AppColors.green.withOpacity(0.08)
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: _showCelebration 
                        ? AppColors.green
                        : isTaken
                            ? AppColors.green.withOpacity(0.3)
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: _showCelebration ? 2 : 1,
                  ),
                  boxShadow: _showCelebration 
                      ? [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : AppShadows.level1,
                ),
                child: Row(
                  children: [
                    // Status icon with celebration animation
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withOpacity(0.1),
                      ),
                      child: _showCelebration
                          ? Transform.scale(
                              scale: checkScale.clamp(0.0, 1.5),
                              child: const Icon(Icons.check_circle, color: AppColors.green, size: 28),
                            )
                          : Icon(statusIcon, color: statusColor),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.protocol.peptideName,
                            style: AppTypography.headline,
                          ),
                          Row(
                            children: [
                              Text(
                                widget.protocol.formattedDosage,
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Text(
                                '• ${widget.dose.scheduledTime}',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isTaken)
                      TextButton(
                        onPressed: _handleTake,
                        child: const Text('Take'),
                      )
                    else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.1),
                          borderRadius: AppRadius.smallRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showCelebration)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.celebration, color: AppColors.green, size: 14),
                              ),
                            Text(
                              _showCelebration ? 'Nice!' : statusText,
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.green,
                                fontWeight: _showCelebration ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Confetti particles
              if (_showCelebration)
                ..._particles.map((particle) {
                  final distance = particle.speed * progress;
                  final opacity = (1 - progress).clamp(0.0, 1.0);
                  final dx = cos(particle.angle) * distance;
                  final dy = sin(particle.angle) * distance - (progress * 30);
                  
                  return Positioned(
                    left: 24 + dx,
                    top: 24 + dy,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: progress * 3 * pi,
                        child: Container(
                          width: particle.size,
                          height: particle.size,
                          decoration: BoxDecoration(
                            color: particle.color,
                            borderRadius: BorderRadius.circular(particle.size / 4),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mediumRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mediumRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.caption1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

