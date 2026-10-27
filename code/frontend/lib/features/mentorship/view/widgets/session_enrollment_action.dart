import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot.dart';

/// Reserves a place only after the server confirms enrollment.
class SessionEnrollmentAction extends StatefulWidget {
  const SessionEnrollmentAction({
    required this.slot,
    required this.controller,
    required this.onJoined,
    required this.isHost,
    required this.isEnrolled,
    super.key,
  });

  final MentorshipSlot slot;
  final MentorshipController controller;
  final Future<void> Function() onJoined;
  final bool isHost;
  final bool isEnrolled;

  @override
  State<SessionEnrollmentAction> createState() =>
      _SessionEnrollmentActionState();
}

class _SessionEnrollmentActionState extends State<SessionEnrollmentAction> {
  bool _busy = false;
  bool _joined = false;
  String? _error;

  Future<void> _join() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await widget.controller.joinSlot(
      widget.slot.slotId,
      const EnrollSlotRequest(),
    );
    if (!mounted) return;
    setState(() {
      _joined = success;
      _error = success
          ? null
          : widget.controller.error ?? 'Unable to join. Please retry.';
    });
    // Re-read capacity even on rejection: another member may have filled the slot.
    await widget.onJoined();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final enrolled =
          _joined ||
          widget.isEnrolled ||
          widget.controller.myEnrolledSlots.any(
            (slot) => slot.slotId == widget.slot.slotId,
          );
      final host =
          widget.isHost ||
          widget.controller.myMentoringSlots.any(
            (slot) => slot.slotId == widget.slot.slotId,
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (host)
            const Text('You are hosting this session')
          else if (enrolled) ...[
            const Text('Joined — your spot is reserved'),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.controller.selectTab(MentorshipTab.mySessions);
              },
              child: const Text('View My Mentorship'),
            ),
          ] else
            FilledButton.icon(
              onPressed:
                  _busy || widget.controller.loading || !widget.slot.isOpen
                  ? null
                  : _join,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1, size: 18),
              label: Text(
                _busy
                    ? 'Joining...'
                    : widget.slot.isOpen
                    ? 'Join Session'
                    : widget.slot.isFull
                    ? 'Session Full'
                    : 'Enrollment Closed',
              ),
            ),
        ],
      );
    },
  );
}
