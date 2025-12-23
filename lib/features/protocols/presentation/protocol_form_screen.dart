import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/protocol.dart';
import '../../../core/services/storage_service.dart';
import '../../library/presentation/peptide_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import 'protocol_provider.dart';

class ProtocolFormScreen extends StatefulWidget {
  final String? protocolId; // null for create, non-null for edit

  const ProtocolFormScreen({super.key, this.protocolId});

  @override
  State<ProtocolFormScreen> createState() => _ProtocolFormScreenState();
}

class _ProtocolFormScreenState extends State<ProtocolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get isEditing => widget.protocolId != null;
  bool _savedSuccessfully = false;
  bool _loadedFromDraft = false;

  String? _selectedPeptideId;
  String _peptideName = '';
  final _dosageController = TextEditingController();
  String _dosageUnit = 'mcg';
  String _frequency = 'Daily';
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _syncToCalendar = false;
  final _notesController = TextEditingController();

  final List<String> _dosageUnits = ['mcg', 'mg', 'IU', 'units'];
  final List<String> _frequencies = [
    'Daily',
    'Twice Daily',
    'Every Other Day',
    'Weekly',
    'Twice Weekly',
    '5 days on, 2 days off',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProtocol();
      });
    } else {
      // Try to load draft for new protocols
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDraft();
      });
    }
  }

  void _loadProtocol() {
    final provider = context.read<ProtocolProvider>();
    final protocol = provider.getProtocolById(widget.protocolId!);
    if (protocol != null) {
      setState(() {
        _selectedPeptideId = protocol.peptideId;
        _peptideName = protocol.peptideName;
        _dosageController.text = protocol.dosageAmount.toString();
        _dosageUnit = protocol.dosageUnit;
        _frequency = protocol.frequency;
        _scheduledTime = _parseTimeString(protocol.times.isNotEmpty ? protocol.times.first : '8:00 AM');
        _startDate = protocol.startDate;
        _endDate = protocol.endDate;
        _syncToCalendar = protocol.syncToCalendar;
        _notesController.text = protocol.notes ?? '';
      });
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    // Parse time string like "8:00 AM" to TimeOfDay
    final parts = timeStr.split(':');
    int hour = int.tryParse(parts[0]) ?? 8;
    int minute = 0;
    
    if (parts.length > 1) {
      final minutePart = parts[1].split(' ');
      minute = int.tryParse(minutePart[0]) ?? 0;
      
      if (minutePart.length > 1) {
        final period = minutePart[1].toUpperCase();
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _loadDraft() {
    final storage = context.read<StorageService>();
    final draftJson = storage.draftProtocol;
    
    if (draftJson != null) {
      try {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        setState(() {
          _selectedPeptideId = draft['peptideId'] as String?;
          _peptideName = draft['peptideName'] as String? ?? '';
          if (draft['dosage'] != null) {
            _dosageController.text = draft['dosage'].toString();
          }
          _dosageUnit = draft['dosageUnit'] as String? ?? 'mcg';
          _frequency = draft['frequency'] as String? ?? 'Daily';
          if (draft['scheduledTimeHour'] != null && draft['scheduledTimeMinute'] != null) {
            _scheduledTime = TimeOfDay(
              hour: draft['scheduledTimeHour'] as int,
              minute: draft['scheduledTimeMinute'] as int,
            );
          }
          if (draft['startDate'] != null) {
            _startDate = DateTime.fromMillisecondsSinceEpoch(draft['startDate'] as int);
          }
          if (draft['endDate'] != null) {
            _endDate = DateTime.fromMillisecondsSinceEpoch(draft['endDate'] as int);
          }
          _syncToCalendar = draft['syncToCalendar'] as bool? ?? false;
          _notesController.text = draft['notes'] as String? ?? '';
          _loadedFromDraft = true;
        });
        
        // Show a message that draft was restored
        if (_loadedFromDraft && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Resumed your unfinished protocol'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Clear',
                onPressed: () async {
                  await storage.clearDraftProtocol();
                  setState(() {
                    _selectedPeptideId = null;
                    _peptideName = '';
                    _dosageController.clear();
                    _dosageUnit = 'mcg';
                    _frequency = 'Daily';
                    _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
                    _startDate = DateTime.now();
                    _endDate = null;
                    _syncToCalendar = false;
                    _notesController.clear();
                    _loadedFromDraft = false;
                  });
                },
              ),
            ),
          );
        }
      } catch (e) {
        // Invalid draft data, clear it
        storage.clearDraftProtocol();
      }
    }
  }

  Future<void> _saveDraft() async {
    // Don't save draft if editing an existing protocol or if saved successfully
    if (isEditing || _savedSuccessfully) return;
    
    // Only save if there's some meaningful data entered
    final hasData = _peptideName.isNotEmpty || 
                    _dosageController.text.isNotEmpty ||
                    _notesController.text.isNotEmpty;
    
    if (!hasData) return;
    
    final storage = context.read<StorageService>();
    final draft = {
      'peptideId': _selectedPeptideId,
      'peptideName': _peptideName,
      'dosage': _dosageController.text.isNotEmpty ? double.tryParse(_dosageController.text) : null,
      'dosageUnit': _dosageUnit,
      'frequency': _frequency,
      'scheduledTimeHour': _scheduledTime.hour,
      'scheduledTimeMinute': _scheduledTime.minute,
      'startDate': _startDate.millisecondsSinceEpoch,
      'endDate': _endDate?.millisecondsSinceEpoch,
      'syncToCalendar': _syncToCalendar,
      'notes': _notesController.text,
    };
    
    await storage.setDraftProtocol(jsonEncode(draft));
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Save draft before allowing pop
        if (!_savedSuccessfully && !isEditing) {
          await _saveDraft();
        }
        
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Protocol' : 'New Protocol'),
          actions: [
            TextButton(
              onPressed: _saveProtocol,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // Peptide Selection
            _SectionTitle(title: 'Peptide'),
            _buildPeptideSelector(),
            const SizedBox(height: AppSpacing.l),

            // Dosage
            _SectionTitle(title: 'Dosage'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '250',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _dosageUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _dosageUnits
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _dosageUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Frequency
            _SectionTitle(title: 'Schedule'),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: _frequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: AppSpacing.m),

            // Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Time'),
              subtitle: Text(_formatTime(_scheduledTime)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),

            // Start Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectDate(isStart: true),
            ),

            // End Date (optional)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('End Date (Optional)'),
              subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Not set'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _selectDate(isStart: false),
            ),
            const SizedBox(height: AppSpacing.l),

            // Calendar Sync
            _SectionTitle(title: 'Integration'),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sync to Apple Calendar'),
                      subtitle: Text(
                        settings.calendarSyncEnabled && settings.selectedCalendarName != null
                            ? 'Add doses to "${settings.selectedCalendarName}"'
                            : 'Enable calendar sync in Settings first',
                      ),
                      value: _syncToCalendar,
                      onChanged: settings.calendarSyncEnabled && settings.selectedCalendar != null
                          ? (v) => setState(() => _syncToCalendar = v)
                          : null,
                    ),
                    if (!settings.calendarSyncEnabled)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.m),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, 
                              size: 16, 
                              color: AppColors.mediumGray,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Go to Settings → Calendar Integration to enable',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.l),

            // Notes
            _SectionTitle(title: 'Notes'),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this protocol...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProtocol,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Text(
                    isEditing ? 'Update Protocol' : 'Create Protocol',
                    style: AppTypography.headline.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Delete button (only for editing)
            if (isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                    child: Text(
                      'Delete Protocol',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPeptideSelector() {
    return Consumer<PeptideProvider>(
      builder: (context, provider, _) {
        final peptides = provider.peptides;

        return InkWell(
          onTap: () => _showPeptideSelector(peptides),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Select Peptide',
              suffixIcon: const Icon(Icons.arrow_drop_down),
              errorText: _selectedPeptideId == null && _peptideName.isEmpty
                  ? null
                  : null,
            ),
            child: Text(
              _peptideName.isNotEmpty ? _peptideName : 'Choose a peptide',
              style: _peptideName.isEmpty
                  ? TextStyle(color: AppColors.mediumGray)
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _showPeptideSelector(List<dynamic> peptides) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    Text('Select Peptide', style: AppTypography.headline),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: peptides.length + 1, // +1 for "Other" option
                  itemBuilder: (context, index) {
                    // "Other" option at the end
                    if (index == peptides.length) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.purple.withOpacity(0.1),
                          child: const Icon(Icons.add, color: AppColors.purple),
                        ),
                        title: const Text('Other (Custom)'),
                        subtitle: const Text('Enter your own peptide name'),
                        trailing: _selectedPeptideId == 'custom'
                            ? Icon(Icons.check, color: AppColors.primaryBlue)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _showCustomPeptideDialog();
                        },
                      );
                    }
                    
                    final peptide = peptides[index];
                    final categoryColor =
                        AppColors.getCategoryColor(peptide.category);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: categoryColor.withOpacity(0.1),
                        child: Text(
                          peptide.name[0],
                          style: TextStyle(color: categoryColor),
                        ),
                      ),
                      title: Text(peptide.name),
                      subtitle: Text(peptide.category),
                      trailing: _selectedPeptideId == peptide.id
                          ? Icon(Icons.check, color: AppColors.primaryBlue)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedPeptideId = peptide.id;
                          _peptideName = peptide.name;
                        });
                        Navigator.pop(context);
                      },
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

  void _showCustomPeptideDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Peptide Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., BPC-157, TB-500',
            labelText: 'Peptide Name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _selectedPeptideId = 'custom';
                  _peptideName = controller.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: isStart ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _saveProtocol() async {
    if (_peptideName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a peptide')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Get the calendar ID from settings if sync is enabled
    final settings = context.read<SettingsProvider>();
    final calendarId = _syncToCalendar && settings.calendarSyncEnabled 
        ? settings.selectedCalendar 
        : null;

    final protocol = Protocol(
      id: widget.protocolId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      peptideId: _selectedPeptideId ?? '',
      peptideName: _peptideName,
      dosageAmount: double.parse(_dosageController.text),
      dosageUnit: _dosageUnit,
      frequency: _frequency,
      times: [_formatTime(_scheduledTime)],
      startDate: _startDate,
      endDate: _endDate,
      syncToCalendar: _syncToCalendar && calendarId != null,
      calendarId: calendarId,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<ProtocolProvider>();
    if (isEditing) {
      provider.updateProtocol(protocol);
    } else {
      provider.addProtocol(protocol);
    }

    // Mark as saved successfully and clear draft
    _savedSuccessfully = true;
    await context.read<StorageService>().clearDraftProtocol();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Protocol?'),
        content: const Text(
          'Are you sure you want to delete this protocol? This will also delete all dose history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProtocolProvider>().deleteProtocol(widget.protocolId!);
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        title,
        style: AppTypography.headline.copyWith(
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}

