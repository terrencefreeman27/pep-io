import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/calculation.dart';
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

    // Calculate units to draw
    final unitsNeeded = volumeNeeded / (syringeVolume / syringeUnits);

    // Calculate total doses from vial
    final totalDoses = (vialMcg / desiredMcg).floor();

    setState(() {
      _concentration = concentration;
      _dosePerUnit = mcgPerUnit;
      _volumeNeeded = volumeNeeded;
      _totalDoses = totalDoses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dose Calculator'),
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
          _buildCalculatorTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Educational disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryBlue),
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
          ),

          const SizedBox(height: AppSpacing.l),

          // Vial Information
          _SectionHeader(title: 'Vial Information'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _vialQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Peptide Amount',
                    hintText: '5',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateDose(),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _vialUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _vialUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _vialUnit = v!);
                    _calculateDose();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          // Reconstitution
          _SectionHeader(title: 'Reconstitution'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _waterVolumeController,
                  decoration: const InputDecoration(
                    labelText: 'Bacteriostatic Water',
                    hintText: '2',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateDose(),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _waterUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _waterUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _waterUnit = v!);
                    _calculateDose();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          // Desired Dose
          _SectionHeader(title: 'Desired Dose'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _desiredDoseController,
                  decoration: const InputDecoration(
                    labelText: 'Dose Amount',
                    hintText: '250',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateDose(),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _doseUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _doseUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _doseUnit = v!);
                    _calculateDose();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          // Syringe Type
          _SectionHeader(title: 'Syringe Type'),
          DropdownButtonFormField<String>(
            value: _syringeType,
            decoration: const InputDecoration(labelText: 'Select Syringe'),
            items: _syringeTypes
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              setState(() => _syringeType = v!);
              _calculateDose();
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Results
          if (_concentration != null) _buildResults(),

          const SizedBox(height: AppSpacing.l),

          // Save Calculation Button
          if (_concentration != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveCalculation,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Calculation'),
              ),
            ),

          const SizedBox(height: AppSpacing.m),

          // Reset Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetCalculator,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final unitsNeeded = _volumeNeeded! * 100 / 1.0; // Assuming 100 unit syringe

    return Card(
      color: AppColors.green.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.green),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Results',
                  style: AppTypography.headline.copyWith(color: AppColors.green),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // Main result - Units to draw
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
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
                    ),
                  ),
                  Text(
                    '${unitsNeeded.toStringAsFixed(1)} units',
                    style: AppTypography.largeTitle.copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '(${(_volumeNeeded! * 1000).toStringAsFixed(2)} µL)',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),

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
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, _) {
        if (provider.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppColors.mediumGray,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'No Saved Calculations',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your saved calculations will appear here',
                  style: AppTypography.body.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: provider.history.length,
          itemBuilder: (context, index) {
            final calc = provider.history[index];
            return _HistoryCard(
              calculation: calc,
              onLoad: () => _loadCalculation(calc),
              onDelete: () => provider.deleteFromHistory(calc.id),
            );
          },
        );
      },
    );
  }

  void _saveCalculation() {
    final calculation = Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peptideId: widget.peptideId,
      peptideName: '', // Would come from selected peptide
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
      const SnackBar(content: Text('Calculation saved')),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.subhead.copyWith(
          color: AppColors.mediumGray,
        ),
      ),
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
            style: AppTypography.headline,
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        title: Text(
          calculation.peptideName.isNotEmpty
              ? calculation.peptideName
              : 'Custom Calculation',
          style: AppTypography.headline,
        ),
        subtitle: Text(
          '${calculation.desiredDose} ${calculation.desiredDoseUnit} • ${calculation.vialQuantity} ${calculation.vialUnit} vial',
          style: AppTypography.caption1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onLoad,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        onTap: onLoad,
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

