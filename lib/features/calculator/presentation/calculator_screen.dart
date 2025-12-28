import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/calculation.dart';
import '../../../core/widgets/animated_widgets.dart';
import 'calculator_provider.dart';

class CalculatorScreen extends StatefulWidget {
  final String? peptideId;

  const CalculatorScreen({super.key, this.peptideId});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Calculator inputs
  final _vialQuantityController = TextEditingController(text: '5');
  String _vialUnit = 'mg';
  final _waterVolumeController = TextEditingController(text: '2');
  String _waterUnit = 'mL';
  final _desiredDoseController = TextEditingController(text: '250');
  String _doseUnit = 'mcg';
  String _syringeType = '100 unit (1mL)';

  // Results
  double? _concentration;
  double? _dosePerUnit;
  double? _volumeNeeded;
  int? _totalDoses;
  bool _showResults = false;

  final List<String> _vialUnits = ['mg', 'mcg', 'IU'];
  final List<String> _waterUnits = ['mL'];
  final List<String> _doseUnits = ['mcg', 'mg', 'IU'];
  final List<String> _syringeTypes = [
    '100 unit (1mL)',
    '50 unit (0.5mL)',
    '30 unit (0.3mL)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateDose();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vialQuantityController.dispose();
    _waterVolumeController.dispose();
    _desiredDoseController.dispose();
    super.dispose();
  }

  void _calculateDose() {
    final vialQty = double.tryParse(_vialQuantityController.text);
    final waterVol = double.tryParse(_waterVolumeController.text);
    final desiredDose = double.tryParse(_desiredDoseController.text);

    if (vialQty == null || waterVol == null || desiredDose == null) {
      setState(() {
        _concentration = null;
        _dosePerUnit = null;
        _volumeNeeded = null;
        _totalDoses = null;
        _showResults = false;
      });
      return;
    }

    // Convert everything to mcg and mL for calculation
    double vialMcg = vialQty;
    if (_vialUnit == 'mg') {
      vialMcg = vialQty * 1000;
    }

    double desiredMcg = desiredDose;
    if (_doseUnit == 'mg') {
      desiredMcg = desiredDose * 1000;
    }

    // Calculate concentration (mcg per mL)
    final concentration = vialMcg / waterVol;

    // Get syringe units
    int syringeUnits = 100;
    if (_syringeType.contains('50')) {
      syringeUnits = 50;
    } else if (_syringeType.contains('30')) {
      syringeUnits = 30;
    }

    // Calculate dose per unit
    double syringeVolume = 1.0;
    if (_syringeType.contains('0.5')) {
      syringeVolume = 0.5;
    } else if (_syringeType.contains('0.3')) {
      syringeVolume = 0.3;
    }

    final mcgPerUnit = concentration * (syringeVolume / syringeUnits);

    // Calculate volume needed (in mL)
    final volumeNeeded = desiredMcg / concentration;

    // Calculate total doses from vial
    final totalDoses = (vialMcg / desiredMcg).floor();

    setState(() {
      _concentration = concentration;
      _dosePerUnit = mcgPerUnit;
      _volumeNeeded = volumeNeeded;
      _totalDoses = totalDoses;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dose Calculator', style: AppTypography.title3),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calculate'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(isDark),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calculator header image
          Center(
            child: SizedBox(
              height: 80,
              child: Image.asset(
                'assets/images/calculator_header.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: AppSpacing.m),
          
          // Educational disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.purple.withOpacity(0.05),
                ],
              ),
              borderRadius: AppRadius.largeRadius,
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    'This calculator is for educational purposes only. Always verify calculations independently.',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.1, end: 0),

          const SizedBox(height: AppSpacing.l),

          // Input sections
          _buildInputSection(
            index: 0,
            title: 'Vial Information',
            icon: Icons.science_outlined,
            color: AppColors.purple,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                  child: _AnimatedTextField(
                  controller: _vialQuantityController,
                    label: 'Peptide Amount',
                    hint: '5',
                  onChanged: (_) => _calculateDose(),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                  child: _AnimatedDropdown(
                  value: _vialUnit,
                    label: 'Unit',
                    items: _vialUnits,
                  onChanged: (v) {
                    setState(() => _vialUnit = v!);
                    _calculateDose();
                  },
                ),
              ),
            ],
          ),
          ),

          _buildInputSection(
            index: 1,
            title: 'Reconstitution',
            icon: Icons.water_drop_outlined,
            color: AppColors.teal,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                  child: _AnimatedTextField(
                  controller: _waterVolumeController,
                    label: 'Bacteriostatic Water',
                    hint: '2',
                  onChanged: (_) => _calculateDose(),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                  child: _AnimatedDropdown(
                  value: _waterUnit,
                    label: 'Unit',
                    items: _waterUnits,
                  onChanged: (v) {
                    setState(() => _waterUnit = v!);
                    _calculateDose();
                  },
                ),
              ),
            ],
          ),
          ),

          _buildInputSection(
            index: 2,
            title: 'Desired Dose',
            icon: Icons.medication_outlined,
            color: AppColors.orange,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                  child: _AnimatedTextField(
                  controller: _desiredDoseController,
                    label: 'Dose Amount',
                    hint: '250',
                  onChanged: (_) => _calculateDose(),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                  child: _AnimatedDropdown(
                  value: _doseUnit,
                    label: 'Unit',
                    items: _doseUnits,
                  onChanged: (v) {
                    setState(() => _doseUnit = v!);
                    _calculateDose();
                  },
                ),
              ),
            ],
          ),
          ),

          _buildInputSection(
            index: 3,
            title: 'Syringe Type',
            icon: Icons.colorize_outlined,
            color: AppColors.pink,
            child: _AnimatedDropdown(
            value: _syringeType,
              label: 'Select Syringe',
              items: _syringeTypes,
              isFullWidth: true,
            onChanged: (v) {
              setState(() => _syringeType = v!);
              _calculateDose();
            },
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          // Results
          if (_showResults && _concentration != null) _buildResults(isDark),

          const SizedBox(height: AppSpacing.l),

          // Action Buttons
          if (_concentration != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetCalculator,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saveCalculation,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Calculation'),
              ),
            ),
              ],
            )
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildInputSection({
    required int index,
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppRadius.smallRadius,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.subhead.copyWith(
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        child,
        const SizedBox(height: AppSpacing.m),
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 80))
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildResults(bool isDark) {
    final unitsNeeded = _volumeNeeded! * 100 / 1.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.green.withOpacity(0.15),
            AppColors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: AppRadius.largeRadius,
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
        boxShadow: AppShadows.glow(AppColors.green, intensity: 0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.green),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  'Results',
                  style: AppTypography.title3.copyWith(color: AppColors.green),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // Main result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: AppRadius.mediumRadius,
              ),
              child: Column(
                children: [
                  Text(
                    'Draw',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${unitsNeeded.toStringAsFixed(1)} units',
                    style: AppTypography.metricLarge.copyWith(
                      color: AppColors.green,
                    ),
                  ),
                  Text(
                    '(${(_volumeNeeded! * 1000).toStringAsFixed(2)} µL)',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.green.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
                .fadeIn(),

            const SizedBox(height: AppSpacing.m),

            // Additional info
            _ResultRow(
              label: 'Concentration',
              value: '${_concentration!.toStringAsFixed(2)} mcg/mL',
            ),
            _ResultRow(
              label: 'mcg per unit',
              value: _dosePerUnit!.toStringAsFixed(2),
            ),
            _ResultRow(
              label: 'Total doses in vial',
              value: '$_totalDoses doses',
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildHistoryTab() {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        if (provider.history.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.history,
            title: 'No Saved Calculations',
            subtitle: 'Your saved calculations will appear here',
            iconColor: AppColors.mediumGray,
            imagePath: 'assets/images/empty_progress.png',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: provider.history.length,
          itemBuilder: (context, index) {
            final calc = provider.history[index];
            return AnimatedListItem(
              index: index,
              child: _HistoryCard(
              calculation: calc,
              onLoad: () => _loadCalculation(calc),
              onDelete: () => provider.deleteFromHistory(calc.id),
              ),
            );
          },
        );
      },
    );
  }

  void _saveCalculation() {
    HapticFeedback.mediumImpact();
    
    final calculation = Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peptideId: widget.peptideId,
      peptideName: '',
      vialQuantity: double.parse(_vialQuantityController.text),
      vialUnit: _vialUnit,
      waterVolume: double.parse(_waterVolumeController.text),
      syringeType: _syringeType,
      desiredDose: double.parse(_desiredDoseController.text),
      desiredDoseUnit: _doseUnit,
      concentration: _concentration!,
      dosePerUnit: _dosePerUnit!,
      volumeNeeded: _volumeNeeded!,
      totalDoses: _totalDoses!,
      createdAt: DateTime.now(),
    );

    context.read<CalculatorProvider>().saveToHistory();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Calculation saved'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadCalculation(Calculation calc) {
    setState(() {
      _vialQuantityController.text = calc.vialQuantity.toString();
      _vialUnit = calc.vialUnit;
      _waterVolumeController.text = calc.waterVolume.toString();
      _syringeType = calc.syringeType;
      _desiredDoseController.text = calc.desiredDose.toString();
      _doseUnit = calc.desiredDoseUnit;
    });
    _calculateDose();
    _tabController.animateTo(0);
  }

  void _resetCalculator() {
    HapticFeedback.lightImpact();
    
    setState(() {
      _vialQuantityController.text = '5';
      _vialUnit = 'mg';
      _waterVolumeController.text = '2';
      _syringeType = '100 unit (1mL)';
      _desiredDoseController.text = '250';
      _doseUnit = 'mcg';
    });
    _calculateDose();
  }
}

class _AnimatedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _AnimatedTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
}

class _AnimatedDropdown extends StatelessWidget {
  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final bool isFullWidth;

  const _AnimatedDropdown({
    required this.value,
    required this.label,
    required this.items,
    this.onChanged,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: onChanged,
      isExpanded: isFullWidth,
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.mediumGray),
          ),
          Text(
            value,
            style: AppTypography.headline.copyWith(color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Calculation calculation;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.calculation,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BouncyTap(
      onTap: onLoad,
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: AppRadius.largeRadius,
          border: Border.all(
            color: isDark ? AppColors.cardDark : AppColors.lightGray,
          ),
          boxShadow: isDark ? null : AppShadows.level1,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                borderRadius: AppRadius.mediumRadius,
              ),
              child: const Icon(Icons.calculate_outlined, color: AppColors.teal),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
          calculation.peptideName.isNotEmpty
              ? calculation.peptideName
              : 'Custom Calculation',
          style: AppTypography.headline,
        ),
                  Text(
          '${calculation.desiredDose} ${calculation.desiredDoseUnit} • ${calculation.vialQuantity} ${calculation.vialUnit} vial',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.mediumGray,
                    ),
        ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
              onPressed: onLoad,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Calculation?'),
        content: const Text('Are you sure you want to delete this saved calculation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
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
