import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/peptide.dart';
import 'peptide_provider.dart';

class PeptideDetailScreen extends StatefulWidget {
  final String peptideId;

  const PeptideDetailScreen({super.key, required this.peptideId});

  @override
  State<PeptideDetailScreen> createState() => _PeptideDetailScreenState();
}

class _PeptideDetailScreenState extends State<PeptideDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Record view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PeptideProvider>().markAsViewed(widget.peptideId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PeptideProvider>(
      builder: (context, provider, _) {
        final peptide = provider.getPeptideById(widget.peptideId);

        if (peptide == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Peptide')),
            body: const Center(child: Text('Peptide not found')),
          );
        }

        final categoryColor = AppColors.getCategoryColor(peptide.category);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor,
                          categoryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: AppRadius.smallRadius,
                              ),
                              child: Text(
                                peptide.category,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              peptide.name,
                              style: AppTypography.largeTitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            if (peptide.alternativeNames.isNotEmpty)
                              Text(
                                peptide.alternativeNames.join(', '),
                                style: AppTypography.body.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      peptide.isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: () => provider.toggleFavorite(peptide.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _sharePeptide(peptide),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.add,
                              label: 'Add Protocol',
                              color: categoryColor,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.protocolCreate,
                                arguments: peptide.id,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.calculate,
                              label: 'Calculator',
                              color: categoryColor,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.calculator,
                                arguments: peptide.id,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.l),

                      // Description
                      _SectionCard(
                        title: 'Overview',
                        icon: Icons.info_outline,
                        color: categoryColor,
                        child: Text(
                          peptide.description,
                          style: AppTypography.body,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.m),

                      // Benefits
                      _SectionCard(
                        title: 'Research Benefits',
                        icon: Icons.star_outline,
                        color: categoryColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: peptide.benefits
                              .map((benefit) => _BulletPoint(
                                    text: benefit,
                                    color: categoryColor,
                                  ))
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.m),

                      // Research Protocols
                      if (peptide.researchProtocols != null)
                        _SectionCard(
                          title: 'Research Protocols',
                          icon: Icons.science_outlined,
                          color: categoryColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailRow(
                                label: 'Dosage Range',
                                value: peptide.researchProtocols.dosageRange,
                              ),
                              _DetailRow(
                                label: 'Frequency',
                                value: peptide.researchProtocols.frequency,
                              ),
                              _DetailRow(
                                label: 'Administration',
                                value: peptide.researchProtocols.administration,
                              ),
                              _DetailRow(
                                label: 'Duration',
                                value: peptide.researchProtocols.duration,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSpacing.m),

                      // Reconstitution
                      _SectionCard(
                        title: 'Reconstitution',
                        icon: Icons.water_drop_outlined,
                        color: categoryColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (peptide.reconstitution.commonVialSizes.isNotEmpty)
                              _DetailRow(
                                label: 'Vial Sizes',
                                value: peptide.reconstitution.commonVialSizes
                                    .map((s) => '${s}mg')
                                    .join(', '),
                              ),
                            _DetailRow(
                              label: 'Typical Water Volume',
                              value: peptide.reconstitution.typicalWaterVolume,
                            ),
                            _DetailRow(
                              label: 'Concentration Example',
                              value: peptide.reconstitution.concentrationExample,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.m),

                      // Considerations
                      if (peptide.considerations.isNotEmpty)
                        _SectionCard(
                          title: 'Considerations',
                          icon: Icons.warning_amber_outlined,
                          color: AppColors.yellow,
                          child: Text(
                            peptide.considerations,
                            style: AppTypography.body.copyWith(
                              color: AppColors.darkGray,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.m),

                      // Storage
                      if (peptide.storage.isNotEmpty)
                        _SectionCard(
                          title: 'Storage',
                          icon: Icons.inventory_2_outlined,
                          color: categoryColor,
                          child: Text(
                            peptide.storage,
                            style: AppTypography.body,
                          ),
                        ),

                      const SizedBox(height: AppSpacing.m),

                      // Stacks Well With
                      if (peptide.stacksWellWith.isNotEmpty)
                        _SectionCard(
                          title: 'Stacks Well With',
                          icon: Icons.layers_outlined,
                          color: categoryColor,
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: peptide.stacksWellWith
                                .map((stack) => Chip(
                                      label: Text(stack),
                                      backgroundColor:
                                          categoryColor.withOpacity(0.1),
                                      labelStyle: TextStyle(color: categoryColor),
                                    ))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.m),

                      // Research References
                      if (peptide.researchReferences.isNotEmpty)
                        _SectionCard(
                          title: 'Research References',
                          icon: Icons.library_books_outlined,
                          color: categoryColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: peptide.researchReferences
                                .map((ref) => _ReferenceItem(reference: ref))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.m),

                      // User Notes
                      _SectionCard(
                        title: 'My Notes',
                        icon: Icons.edit_note,
                        color: categoryColor,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editNotes(peptide),
                        ),
                        child: (peptide.userNotes?.isEmpty ?? true)
                            ? Text(
                                'Tap to add your personal notes...',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.mediumGray,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                peptide.userNotes!,
                                style: AppTypography.body,
                              ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: AppRadius.mediumRadius,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.mediumGray,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Text(
                                'This information is for educational purposes only and is not intended as medical advice. Always consult a healthcare professional before starting any peptide protocol.',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.l),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sharePeptide(Peptide peptide) {
    // Share peptide info
  }

  void _editNotes(Peptide peptide) {
    final controller = TextEditingController(text: peptide.userNotes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('My Notes', style: AppTypography.headline),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      context.read<PeptideProvider>().updateUserNotes(
                            peptide.id,
                            controller.text,
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: controller,
                maxLines: 6,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Add your personal notes about this peptide...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: AppRadius.mediumRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.subhead.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.trailing,
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
                  style: AppTypography.headline.copyWith(color: color),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            child,
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletPoint({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(text, style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.mediumGray),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}

class _ReferenceItem extends StatelessWidget {
  final ResearchReference reference;

  const _ReferenceItem({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reference.title,
            style: AppTypography.subhead,
          ),
          Text(
            '${reference.studyType} (${reference.year})',
            style: AppTypography.caption1.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
          if (reference.url.isNotEmpty)
            Text(
              reference.url,
              style: AppTypography.caption2.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
        ],
      ),
    );
  }
}

