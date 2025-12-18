import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/protocol.dart';
import '../../../core/models/peptide.dart';
import '../../library/presentation/peptide_provider.dart';
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

  @override
  void dispose() {
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sync to Calendar'),
              subtitle: const Text('Add doses to your device calendar'),
              value: _syncToCalendar,
              onChanged: (v) => setState(() => _syncToCalendar = v),
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
                  itemCount: peptides.length,
                  itemBuilder: (context, index) {
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

  void _saveProtocol() {
    if (_peptideName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a peptide')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

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
      syncToCalendar: _syncToCalendar,
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

    Navigator.pop(context);
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

