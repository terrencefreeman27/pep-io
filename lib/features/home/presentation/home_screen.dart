import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/dose.dart';
import '../../../core/widgets/animated_widgets.dart';
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
  
  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
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
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            slivers: [
              // Header with greeting
              SliverToBoxAdapter(
                child: _buildHeader(context)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0, duration: 400.ms),
              ),
              
              // Metric Cards
              SliverToBoxAdapter(
                child: _buildMetricCards(context),
              ),
              
              // Today's Doses section
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          // Animated Avatar with App Icon
          BouncyTap(
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.primaryBlue, intensity: 0.3),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Center(
                        child: Text(
                          name?.isNotEmpty == true ? name![0].toUpperCase() : '👤',
                          style: AppTypography.title2.copyWith(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.mediumGray,
                  ),
                    ),
                    const SizedBox(width: 4),
                    Text(_getGreetingEmoji()),
                  ],
                ),
                Text(
                  name ?? 'Welcome back',
                  style: AppTypography.title2,
                ),
              ],
            ),
          ),
          
          // Settings button
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.softGray,
              borderRadius: AppRadius.mediumRadius,
            ),
            child: IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context) {
    final provider = context.watch<ProtocolProvider>();
    
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        children: [
          AnimatedMetricCard(
            icon: Icons.science_outlined,
            value: '${provider.activeCount}',
            label: 'Active Protocols',
            color: AppColors.purple,
            animationIndex: 0,
          ),
          const SizedBox(width: AppSpacing.s),
          AnimatedMetricCard(
            icon: Icons.check_circle_outline,
            value: '${provider.adherenceRate.toStringAsFixed(0)}%',
            label: 'Adherence',
            color: AppColors.green,
            animationIndex: 1,
          ),
          const SizedBox(width: AppSpacing.s),
          AnimatedMetricCard(
            icon: Icons.local_fire_department_outlined,
            value: '${provider.currentStreak}',
            label: 'Day Streak',
            color: AppColors.orange,
            animationIndex: 2,
          ),
          const SizedBox(width: AppSpacing.s),
          AnimatedMetricCard(
            icon: Icons.access_time,
            value: _getNextDoseTime(provider),
            label: 'Next Dose',
            color: AppColors.primaryBlue,
            animationIndex: 3,
          ),
          const SizedBox(width: AppSpacing.s),
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
          AnimatedSectionHeader(
            title: "Today's Doses",
            trailing: TextButton(
                onPressed: () {
                  // Navigate to calendar
                },
                child: const Text('See all'),
              ),
            animationIndex: 0,
          ),
          const SizedBox(height: AppSpacing.s),
          
          if (doses.isEmpty)
            _buildEmptyDosesCard(context)
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1))
          else
            ...doses.take(3).toList().asMap().entries.map((entry) => 
              AnimatedListItem(
                index: entry.key,
                child: _DoseCard(
                  dose: entry.value,
              protocol: provider.protocols.firstWhere(
                    (p) => p.id == entry.value.protocolId,
                orElse: () => throw Exception('Protocol not found'),
              ),
                  onMarkTaken: () => provider.markDoseAsTaken(entry.value.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDosesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        borderRadius: AppRadius.largeRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.cardDark, AppColors.surfaceDark]
              : [AppColors.softGray, AppColors.white],
        ),
        border: Border.all(
          color: isDark ? AppColors.cardDark : AppColors.lightGray,
        ),
      ),
      child: Column(
        children: [
          // Empty doses image
          SizedBox(
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/images/empty_doses.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 32,
                    color: AppColors.primaryBlue,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'No doses scheduled today',
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add a protocol to get started',
            style: AppTypography.footnote.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: AppSpacing.m),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Protocol'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.calculate_outlined,
              label: 'Calculator',
              color: AppColors.teal,
              onTap: () => Navigator.pushNamed(context, AppRoutes.calculator),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'New Protocol',
              color: AppColors.primaryBlue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.protocolCreate),
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.menu_book_outlined,
              label: 'Library',
              color: AppColors.purple,
              onTap: () => Navigator.pushNamed(context, AppRoutes.library),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.analytics_outlined,
              label: 'Progress',
              color: AppColors.green,
              onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
            )
                .animate()
                .fadeIn(delay: 250.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
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
          borderRadius: AppRadius.largeRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.orange.withOpacity(0.15),
              AppColors.orange.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
          ),
          boxShadow: AppShadows.glow(AppColors.orange, intensity: 0.15),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            
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
            
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.protocolCreate).then((_) {
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
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
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
    HapticFeedback.mediumImpact();
    
    setState(() {
      _showCelebration = true;
      _justTaken = true;
    });
    
    _animationController.forward();
    widget.onMarkTaken();
    
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        final progress = _animationController.value;
        final scaleValue = _showCelebration 
            ? 1.0 + (sin(progress * pi) * 0.03) 
            : 1.0;
        final checkScale = _showCelebration 
            ? Curves.elasticOut.transform(progress.clamp(0.0, 1.0))
            : 1.0;
            
        return Transform.scale(
          scale: scaleValue,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: AppSpacing.s),
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.largeRadius,
                  color: _showCelebration 
                      ? AppColors.green.withOpacity(0.08)
                      : isDark ? AppColors.cardDark : AppColors.white,
                  border: Border.all(
                    color: _showCelebration 
                        ? AppColors.green
                        : isTaken
                            ? AppColors.green.withOpacity(0.3)
                            : isDark 
                                ? AppColors.cardDark 
                                : AppColors.lightGray,
                    width: _showCelebration ? 2 : 1,
                  ),
                  boxShadow: _showCelebration 
                      ? AppShadows.glow(AppColors.green, intensity: 0.3)
                      : AppShadows.level1,
                ),
                child: Row(
                  children: [
                    // Status icon with animation
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor.withOpacity(0.2),
                            statusColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: _showCelebration
                          ? Transform.scale(
                              scale: checkScale.clamp(0.0, 1.5),
                              child: const Icon(Icons.check_circle, color: AppColors.green, size: 28),
                            )
                          : Icon(statusIcon, color: statusColor, size: 24),
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                widget.protocol.formattedDosage,
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Text(
                                widget.dose.scheduledTime,
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
                      BouncyTap(
                        onTap: _handleTake,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: AppRadius.mediumRadius,
                          ),
                          child: Text(
                            'Take',
                            style: AppTypography.subhead.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                    left: 26 + dx,
                    top: 26 + dy,
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
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
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
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption1.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
