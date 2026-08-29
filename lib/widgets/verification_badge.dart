import 'package:flutter/material.dart';
import '../models/produce_image.dart';
import '../theme/app_theme.dart';

/// Mirrors StatusBadge's look, scoped to verification results. Color and
/// label both stay risk-based — see ImageVerificationStatusX.label.
class VerificationBadge extends StatelessWidget {
  final ImageVerificationStatus status;
  const VerificationBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case ImageVerificationStatus.pending:
        return Colors.blueGrey;
      case ImageVerificationStatus.authenticityLikely:
        return AppTheme.primary;
      case ImageVerificationStatus.suspicious:
        return AppTheme.accent;
      case ImageVerificationStatus.highManipulationRisk:
      case ImageVerificationStatus.highAiGenerationRisk:
      case ImageVerificationStatus.verificationFailed:
        return AppTheme.danger;
    }
  }

  IconData get _icon {
    switch (status) {
      case ImageVerificationStatus.pending:
        return Icons.hourglass_top;
      case ImageVerificationStatus.authenticityLikely:
        return Icons.check_circle;
      case ImageVerificationStatus.suspicious:
        return Icons.visibility;
      case ImageVerificationStatus.highManipulationRisk:
      case ImageVerificationStatus.highAiGenerationRisk:
        return Icons.warning_amber;
      case ImageVerificationStatus.verificationFailed:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
