import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

class MentorshipStatusBadge extends StatelessWidget {
  const MentorshipStatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    super.key,
  });

  factory MentorshipStatusBadge.mentorStatus(
    MentorStatus status,
    ColorScheme colors,
  ) {
    return switch (status) {
      MentorStatus.available => MentorshipStatusBadge(
        label: 'Available',
        backgroundColor: colors.primaryContainer.withValues(alpha: 0.7),
        textColor: colors.onPrimaryContainer,
        icon: Icons.check_circle_outline,
      ),
      MentorStatus.unavailable => MentorshipStatusBadge(
        label: 'Unavailable',
        backgroundColor: colors.surfaceContainerHighest,
        textColor: colors.onSurfaceVariant,
        icon: Icons.pause_circle_outline,
      ),
    };
  }

  factory MentorshipStatusBadge.slotStatus(
    SlotStatus status,
    ColorScheme colors,
  ) {
    return switch (status) {
      SlotStatus.open => MentorshipStatusBadge(
        label: 'Open',
        backgroundColor: colors.primaryContainer,
        textColor: colors.onPrimaryContainer,
        icon: Icons.lock_open,
      ),
      SlotStatus.full => MentorshipStatusBadge(
        label: 'Full',
        backgroundColor: colors.secondaryContainer,
        textColor: colors.onSecondaryContainer,
        icon: Icons.people,
      ),
      SlotStatus.closed => MentorshipStatusBadge(
        label: 'Closed',
        backgroundColor: colors.surfaceContainerHighest,
        textColor: colors.onSurfaceVariant,
        icon: Icons.lock_outline,
      ),
      SlotStatus.cancelled => MentorshipStatusBadge(
        label: 'Cancelled',
        backgroundColor: colors.errorContainer,
        textColor: colors.onErrorContainer,
        icon: Icons.cancel_outlined,
      ),
    };
  }

  factory MentorshipStatusBadge.mode(SlotMode mode, ColorScheme colors) {
    return switch (mode) {
      SlotMode.online => MentorshipStatusBadge(
        label: 'Online',
        backgroundColor: colors.primaryContainer,
        textColor: colors.onPrimaryContainer,
        icon: Icons.videocam_outlined,
      ),
      SlotMode.inPerson => MentorshipStatusBadge(
        label: 'In-person',
        backgroundColor: colors.secondaryContainer,
        textColor: colors.onSecondaryContainer,
        icon: Icons.location_on_outlined,
      ),
    };
  }

  factory MentorshipStatusBadge.enrollmentStatus(
    EnrollmentStatus status,
    ColorScheme colors,
  ) {
    return switch (status) {
      EnrollmentStatus.active => MentorshipStatusBadge(
        label: 'Enrolled',
        backgroundColor: colors.primaryContainer,
        textColor: colors.onPrimaryContainer,
        icon: Icons.check_circle_outline,
      ),
      EnrollmentStatus.left => MentorshipStatusBadge(
        label: 'Left',
        backgroundColor: colors.surfaceContainerHighest,
        textColor: colors.onSurfaceVariant,
        icon: Icons.exit_to_app,
      ),
      EnrollmentStatus.cancelled => MentorshipStatusBadge(
        label: 'Cancelled',
        backgroundColor: colors.errorContainer,
        textColor: colors.onErrorContainer,
        icon: Icons.cancel_outlined,
      ),
    };
  }

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
