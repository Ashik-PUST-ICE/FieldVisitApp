import 'package:flutter/material.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';

/// A colored status badge / chip.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.small = false,
  });

  /// Factory for common statuses.
  factory StatusBadge.fromStatus(String? status) {
    final s = (status ?? 'unknown').toLowerCase();
    Color c;
    IconData ic;
    if (s == 'active' ||
        s == 'completed' ||
        s == 'delivered' ||
        s == 'verified') {
      c = AppColors.success;
      ic = Icons.check_circle_outline;
    } else if (s == 'pending' || s == 'in_progress' || s == 'started') {
      c = AppColors.warning;
      ic = Icons.schedule;
    } else if (s == 'inactive' || s == 'cancelled' || s == 'failed') {
      c = AppColors.error;
      ic = Icons.cancel_outlined;
    } else {
      c = AppColors.info;
      ic = Icons.info_outline;
    }
    return StatusBadge(label: status ?? 'Unknown', color: c, icon: ic);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final fontSize = small ? 10.0 : 12.0;
    final px = small ? 8.0 : 10.0;
    final py = small ? 3.0 : 5.0;
    final iconSize = small ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: px, vertical: py),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: c),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: c,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gradient-accented icon circle for list leading widgets.
class AccentIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final bool useGradient;

  const AccentIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 40,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: useGradient ? AppColors.primaryGradient : null,
        color: useGradient ? null : c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: useGradient ? Colors.white : c,
      ),
    );
  }
}
