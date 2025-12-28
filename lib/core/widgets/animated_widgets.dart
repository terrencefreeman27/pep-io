import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Animated list item wrapper for staggered animations
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay * index)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideY(begin: 0.1, end: 0, duration: duration, curve: Curves.easeOutCubic);
  }
}

/// Shimmer loading placeholder for cards
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppRadius.mediumRadius,
        ),
      ),
    );
  }
}

/// Shimmer loading list
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(AppSpacing.m),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: ShimmerCard(height: itemHeight),
      ),
    );
  }
}

/// Glassmorphism card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 200,
      borderRadius: borderRadius?.topLeft.x ?? 16,
      blur: blur,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ]
            : [
                Colors.white.withOpacity(0.4),
                Colors.white.withOpacity(0.2),
              ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ]
            : [
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.2),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.m),
        child: child,
      ),
    );
  }
}

/// Gradient card with subtle animation
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColors = isDark
        ? [
            AppColors.primaryBlue.withOpacity(0.2),
            AppColors.purple.withOpacity(0.1),
          ]
        : [
            AppColors.primaryBlue.withOpacity(0.08),
            AppColors.purple.withOpacity(0.04),
          ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppRadius.largeRadius,
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? AppRadius.largeRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors ?? defaultColors,
            ),
            border: Border.all(
              color: (colors?.first ?? AppColors.primaryBlue).withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Animated counter for statistics
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$value$suffix',
          style: style,
        );
      },
    );
  }
}

/// Pulsing dot indicator
class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = AppColors.green,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.3, 1.3),
          duration: 800.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 800.ms,
        );
  }
}

/// Animated progress ring
class AnimatedProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.color = AppColors.primaryBlue,
    this.backgroundColor = AppColors.lightGray,
    this.size = 60,
    this.strokeWidth = 6,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              if (child != null) child!,
            ],
          ),
        );
      },
    );
  }
}

/// Bouncy scale on tap wrapper
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Slide fade transition for page navigation
class SlideFadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final bool reverse;

  const SlideFadeTransition({
    super.key,
    required this.child,
    required this.animation,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: Offset(reverse ? -0.2 : 0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

/// Animated gradient background
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
          const Color(0xFF0f3460),
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft + Alignment(_controller.value * 0.5, 0),
              end: Alignment.bottomRight - Alignment(_controller.value * 0.5, 0),
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Floating action button with entrance animation
class AnimatedFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: Icon(icon),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}

/// Empty state widget with animation
class AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final Color? iconColor;
  final String? imagePath; // Optional image path

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.iconColor,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image or Icon
            if (imagePath != null)
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (iconColor ?? AppColors.mediumGray).withOpacity(0.1),
                      ),
                      child: Icon(
                        icon,
                        size: 48,
                        color: iconColor ?? AppColors.mediumGray,
                      ),
                    );
                  },
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn()
            else
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (iconColor ?? AppColors.mediumGray).withOpacity(0.1),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: iconColor ?? AppColors.mediumGray,
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.mediumGray,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGray,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.l),
              action!.animate().fadeIn(delay: 400.ms).scale(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

/// Metric card with gradient and animation
class AnimatedMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int animationIndex;

  const AnimatedMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BouncyTap(
      onTap: onTap,
      child: Container(
        height: 140, // Fixed height for proper layout
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          borderRadius: AppRadius.largeRadius,
          color: isDark ? AppColors.cardDark : AppColors.white,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(isDark ? 0.2 : 0.15),
              color.withOpacity(isDark ? 0.1 : 0.05),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.3 : 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(isDark ? 0.3 : 0.2),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.title1.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption1.copyWith(
                color: isDark ? AppColors.lightGray : AppColors.mediumGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationIndex * 100))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, duration: 400.ms);
  }
}

/// Section header with animation
class AnimatedSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final int animationIndex;

  const AnimatedSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (trailing != null) trailing!,
      ],
    )
        .animate(delay: Duration(milliseconds: animationIndex * 50))
        .fadeIn()
        .slideX(begin: -0.05, end: 0);
  }
}

/// Animated error state with retry button
class AnimatedErrorState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final bool isNetworkError;

  const AnimatedErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle = 'Please try again later',
    this.onRetry,
    this.isNetworkError = false,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = isNetworkError 
        ? 'assets/images/error_network.png' 
        : 'assets/images/error_generic.png';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(0.1),
                    ),
                    child: Icon(
                      isNetworkError ? Icons.wifi_off : Icons.error_outline,
                      size: 40,
                      color: AppColors.error,
                    ),
                  );
                },
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.error,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGray,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.l),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ).animate().fadeIn(delay: 400.ms).scale(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success celebration overlay
class SuccessCelebration extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onDismiss;

  const SuccessCelebration({
    super.key,
    this.title = 'Great job!',
    this.subtitle,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  'assets/images/success_dose.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.check_circle,
                      size: 100,
                      color: AppColors.green,
                    );
                  },
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),
              const SizedBox(height: AppSpacing.m),
              Text(
                title,
                style: AppTypography.title1.copyWith(color: Colors.white),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTypography.body.copyWith(color: Colors.white70),
                ).animate().fadeIn(delay: 300.ms),
              ],
              const SizedBox(height: AppSpacing.l),
              Text(
                'Tap to continue',
                style: AppTypography.caption1.copyWith(color: Colors.white54),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

