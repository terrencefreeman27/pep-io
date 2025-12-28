import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/dose.dart';
import '../../../core/models/protocol.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../protocols/presentation/protocol_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar', style: AppTypography.title3),
        actions: [
          BouncyTap(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(
                Icons.today,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_agenda_outlined),
            onSelected: (format) => setState(() => _calendarFormat = format),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('Month View'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2 Week View'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('Week View'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProtocolProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Calendar Widget
              _CustomCalendar(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                calendarFormat: _calendarFormat,
                doses: provider.allDoses,
                protocols: provider.protocols,
                onDaySelected: (selectedDay, focusedDay) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0),

              const Divider(height: 1),

              // Selected Day Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: AppRadius.mediumRadius,
                      ),
                      child: Center(
                        child: Text(
                          '${_selectedDay.day}',
                          style: AppTypography.headline.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(_selectedDay),
                      style: AppTypography.headline,
                    ),
                          Text(
                            _getRelativeDay(_selectedDay),
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDayStats(provider),
                  ],
                ),
              ),

              // Doses List for Selected Day
              Expanded(
                child: _buildDosesList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Today';
    if (selected == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';
    
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  Widget _buildDayStats(ProtocolProvider provider) {
    final dayDoses = _getDosesForDay(provider, _selectedDay);
    final completed = dayDoses.where((d) => d.status == DoseStatus.taken).length;
    final total = dayDoses.length;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: completed == total
              ? [AppColors.green.withOpacity(0.2), AppColors.green.withOpacity(0.1)]
              : [AppColors.primaryBlue.withOpacity(0.2), AppColors.primaryBlue.withOpacity(0.1)],
        ),
        borderRadius: AppRadius.fullRadius,
        boxShadow: completed == total
            ? AppShadows.glow(AppColors.green, intensity: 0.2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed == total)
            const Icon(Icons.check_circle, size: 16, color: AppColors.green),
          if (completed == total) const SizedBox(width: 4),
          Text(
            '$completed/$total',
            style: AppTypography.subhead.copyWith(
          color: completed == total ? AppColors.green : AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
        ),
        ],
      ),
    );
  }

  Widget _buildDosesList(ProtocolProvider provider) {
    final dayDoses = _getDosesForDay(provider, _selectedDay);

    if (dayDoses.isEmpty) {
      return AnimatedEmptyState(
        icon: Icons.event_available,
        title: 'No Doses Scheduled',
        subtitle: 'No doses are scheduled for this day',
        iconColor: AppColors.mediumGray,
        imagePath: 'assets/images/empty_calendar.png',
      );
    }

    // Group by protocol
    final grouped = <String, List<Dose>>{};
    for (final dose in dayDoses) {
      grouped.putIfAbsent(dose.protocolId, () => []).add(dose);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final protocolId = grouped.keys.elementAt(index);
        final doses = grouped[protocolId]!;
        final protocol = provider.getProtocolById(protocolId);

        return AnimatedListItem(
          index: index,
          child: _ProtocolDoseGroup(
          protocol: protocol,
          doses: doses,
          onDoseAction: (dose, status) {
              HapticFeedback.mediumImpact();
            provider.logDose(dose.id, status);
          },
          ),
        );
      },
    );
  }

  List<Dose> _getDosesForDay(ProtocolProvider provider, DateTime day) {
    return provider.allDoses.where((dose) {
      return dose.scheduledDate.year == day.year &&
          dose.scheduledDate.month == day.month &&
          dose.scheduledDate.day == day.day;
    }).toList()
      ..sort((a, b) {
        final aParts = a.scheduledTime.split(':');
        final bParts = b.scheduledTime.split(':');
        final aMinutes = (int.tryParse(aParts[0]) ?? 0) * 60 + (int.tryParse(aParts.length > 1 ? aParts[1] : '0') ?? 0);
        final bMinutes = (int.tryParse(bParts[0]) ?? 0) * 60 + (int.tryParse(bParts.length > 1 ? bParts[1] : '0') ?? 0);
        return aMinutes.compareTo(bMinutes);
      });
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

enum CalendarFormat { month, twoWeeks, week }

class _CustomCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final List<Dose> doses;
  final List<Protocol> protocols;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;

  const _CustomCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.doses,
    required this.protocols,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = _getWeeksToShow();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Month/Year Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              BouncyTap(
                onTap: () {
                  onPageChanged(DateTime(focusedDay.year, focusedDay.month - 1, 1));
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.softGray,
                    borderRadius: AppRadius.mediumRadius,
                  ),
                  child: const Icon(Icons.chevron_left, size: 20),
                ),
              ),
              Expanded(
                child: Text(
                  _formatMonthYear(focusedDay),
                  style: AppTypography.title2,
                  textAlign: TextAlign.center,
                ),
              ),
              BouncyTap(
                onTap: () {
                  onPageChanged(DateTime(focusedDay.year, focusedDay.month + 1, 1));
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.softGray,
                    borderRadius: AppRadius.mediumRadius,
                  ),
                  child: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Weekday Headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.mediumGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Calendar Grid
        ...weeks.asMap().entries.map((weekEntry) {
          final weekIndex = weekEntry.key;
          final week = weekEntry.value;
          
          return Row(
            children: week.asMap().entries.map((dayEntry) {
              final dayIndex = dayEntry.key;
              final day = dayEntry.value;
              
              return Expanded(
                        child: _CalendarDay(
                          date: day,
                          isSelected: _isSameDay(day, selectedDay),
                          isToday: _isSameDay(day, DateTime.now()),
                          isCurrentMonth: day.month == focusedDay.month,
                          hasDoses: _hasDoses(day),
                          completionStatus: _getCompletionStatus(day),
                          onTap: () => onDaySelected(day, focusedDay),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: weekIndex * 50 + dayIndex * 20),
                      duration: 200.ms,
                        ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  List<List<DateTime>> _getWeeksToShow() {
    int weeksCount;
    switch (calendarFormat) {
      case CalendarFormat.week:
        weeksCount = 1;
        break;
      case CalendarFormat.twoWeeks:
        weeksCount = 2;
        break;
      case CalendarFormat.month:
        weeksCount = 6;
        break;
    }

    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final firstDayOffset = firstDayOfMonth.weekday - 1;
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOffset));

    final weeks = <List<DateTime>>[];
    var currentDay = startDate;

    for (var w = 0; w < weeksCount; w++) {
      final week = <DateTime>[];
      for (var d = 0; d < 7; d++) {
        week.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return weeks;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasDoses(DateTime day) {
    return doses.any((dose) =>
        dose.scheduledDate.year == day.year &&
        dose.scheduledDate.month == day.month &&
        dose.scheduledDate.day == day.day);
  }

  double _getCompletionStatus(DateTime day) {
    final dayDoses = doses.where((dose) =>
        dose.scheduledDate.year == day.year &&
        dose.scheduledDate.month == day.month &&
        dose.scheduledDate.day == day.day);

    if (dayDoses.isEmpty) return 0;

    final completed = dayDoses.where((d) => d.status == DoseStatus.taken).length;
    return completed / dayDoses.length;
  }

  String _formatMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isCurrentMonth;
  final bool hasDoses;
  final double completionStatus;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isCurrentMonth,
    required this.hasDoses,
    required this.completionStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? borderColor;
    Color textColor = isCurrentMonth 
        ? Theme.of(context).colorScheme.onSurface 
        : AppColors.mediumGray.withOpacity(0.5);
    
    if (isSelected) {
      backgroundColor = AppColors.primaryBlue;
      textColor = Colors.white;
    } else if (isToday) {
      borderColor = AppColors.primaryBlue;
      textColor = AppColors.primaryBlue;
    }

    Color dotColor = AppColors.primaryBlue;
    if (completionStatus == 1) {
      dotColor = AppColors.green;
    } else if (completionStatus > 0) {
      dotColor = AppColors.yellow;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected 
              ? backgroundColor 
              : completionStatus == 1 
                  ? AppColors.green.withOpacity(0.1) 
                  : null,
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
          borderRadius: AppRadius.smallRadius,
          boxShadow: isSelected
              ? AppShadows.glow(AppColors.primaryBlue, intensity: 0.3)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasDoses)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                  boxShadow: completionStatus == 1
                      ? AppShadows.glow(AppColors.green, intensity: 0.5)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolDoseGroup extends StatelessWidget {
  final Protocol? protocol;
  final List<Dose> doses;
  final Function(Dose, DoseStatus) onDoseAction;

  const _ProtocolDoseGroup({
    required this.protocol,
    required this.doses,
    required this.onDoseAction,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = protocol != null
        ? AppColors.getCategoryColor(protocol!.peptideName)
        : AppColors.mediumGray;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Protocol Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.15),
                  categoryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.getGradientForColor(categoryColor),
                    borderRadius: AppRadius.mediumRadius,
                    boxShadow: AppShadows.glow(categoryColor, intensity: 0.3),
                  ),
                  child: Center(
                  child: Text(
                    protocol?.peptideName[0] ?? '?',
                      style: AppTypography.headline.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        protocol?.peptideName ?? 'Unknown Protocol',
                        style: AppTypography.headline,
                      ),
                      Text(
                        protocol?.formattedDosage ?? '',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Doses List
          ...doses.asMap().entries.map((entry) {
            final index = entry.key;
            final dose = entry.value;
            
            return _DoseListItem(
                dose: dose,
                categoryColor: categoryColor,
                onComplete: () => onDoseAction(dose, DoseStatus.taken),
                onSkip: () => onDoseAction(dose, DoseStatus.skipped),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 50));
          }),
        ],
      ),
    );
  }
}

class _DoseListItem extends StatelessWidget {
  final Dose dose;
  final Color categoryColor;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const _DoseListItem({
    required this.dose,
    required this.categoryColor,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = dose.status == DoseStatus.taken;
    final isSkipped = dose.status == DoseStatus.skipped;
    final isPending = dose.status == DoseStatus.scheduled;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightGray.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.green.withOpacity(0.15)
                  : isSkipped
                      ? AppColors.yellow.withOpacity(0.15)
                      : categoryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check
                  : isSkipped
                      ? Icons.skip_next
                      : Icons.schedule,
              size: 18,
              color: isCompleted
                  ? AppColors.green
                  : isSkipped
                      ? AppColors.yellow
                      : categoryColor,
            ),
          ),

          const SizedBox(width: AppSpacing.m),

          // Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.scheduledTime,
                  style: AppTypography.headline.copyWith(
                    decoration: isCompleted || isSkipped
                        ? TextDecoration.lineThrough
                        : null,
                    color: isCompleted || isSkipped
                        ? AppColors.mediumGray
                        : null,
                  ),
                ),
                if (isCompleted && dose.actualTime != null)
                  Text(
                    'Taken at ${dose.actualTime!}',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.green,
                    ),
                  ),
                if (isSkipped)
                  Text(
                    'Skipped',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.yellow,
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          if (isPending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BouncyTap(
                  onTap: onComplete,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: AppRadius.mediumRadius,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                  color: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                BouncyTap(
                  onTap: onSkip,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.1),
                      borderRadius: AppRadius.mediumRadius,
                    ),
                    child: const Icon(
                      Icons.skip_next_outlined,
                  color: AppColors.yellow,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
