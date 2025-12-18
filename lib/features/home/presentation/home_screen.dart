import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ProtocolProvider>().loadProtocols(),
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
              
              // Library Card
              SliverToBoxAdapter(
                child: _buildLibraryCard(context),
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

  Widget _buildLibraryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.library),
        borderRadius: AppRadius.mediumRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediumRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teal.withOpacity(0.1),
                AppColors.teal.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: AppColors.teal.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peptide Library',
                      style: AppTypography.headline,
                    ),
                    Text(
                      'Explore 60+ peptides',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.mediumGray,
              ),
            ],
          ),
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

class _DoseCard extends StatelessWidget {
  final Dose dose;
  final dynamic protocol;
  final VoidCallback onMarkTaken;

  const _DoseCard({
    required this.dose,
    required this.protocol,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = dose.isOverdue;
    final isDueSoon = dose.isDueSoon;
    final isTaken = dose.status == DoseStatus.taken;
    
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mediumRadius,
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: AppShadows.level1,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.1),
            ),
            child: Icon(statusIcon, color: statusColor),
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
                Row(
                  children: [
                    Text(
                      protocol.formattedDosage,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      '• ${dose.scheduledTime}',
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
              onPressed: onMarkTaken,
              child: const Text('Take'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: AppRadius.smallRadius,
              ),
              child: Text(
                statusText,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }
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

