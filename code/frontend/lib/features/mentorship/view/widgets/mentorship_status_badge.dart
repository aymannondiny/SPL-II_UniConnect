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
        backgroundColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
        icon: Icons.lock_open,
      ),
      SlotStatus.full => MentorshipStatusBadge(
        label: 'Full',
        backgroundColor: Colors.amber.shade50,
        textColor: Colors.amber.shade900,
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
        backgroundColor: Colors.red.shade50,
        textColor: Colors.red.shade800,
        icon: Icons.cancel_outlined,
      ),
    };
  }

  factory MentorshipStatusBadge.mode(
    SlotMode mode,
    ColorScheme colors,
  ) {
    return switch (mode) {
      SlotMode.online => MentorshipStatusBadge(
        label: 'Online',
        backgroundColor: Colors.blue.shade50,
        textColor: Colors.blue.shade800,
        icon: Icons.videocam_outlined,
      ),
      SlotMode.inPerson => MentorshipStatusBadge(
        label: 'In-person',
        backgroundColor: Colors.purple.shade50,
        textColor: Colors.purple.shade800,
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
        backgroundColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
        icon: Icons.check_circle_outline,
      ),
      EnrollmentStatus.left => MentorshipStatusBadge(
        label: 'Left',
        backgroundColor: Colors.orange.shade50,
        textColor: Colors.orange.shade800,
        icon: Icons.exit_to_app,
      ),
      EnrollmentStatus.cancelled => MentorshipStatusBadge(
        label: 'Cancelled',
        backgroundColor: Colors.red.shade50,
        textColor: Colors.red.shade800,
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
