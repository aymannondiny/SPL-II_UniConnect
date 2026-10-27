import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enrollment.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_status_badge.dart';

/// Enrollment periods are intentionally separate from current-series cards.
/// Leaving and rejoining the same series must retain both periods.
class ParticipationHistory extends StatefulWidget {
  const ParticipationHistory({
    required this.repository,
    this.revision = 0,
    super.key,
  });

  final MentorshipRepository repository;
  final int revision;

  @override
  State<ParticipationHistory> createState() => _ParticipationHistoryState();
}

class _ParticipationHistoryState extends State<ParticipationHistory> {
  List<MentorshipEnrollment>? _periods;
  String? _error;
  bool _loading = false;

  int _generation = 0;

  @override
  void didUpdateWidget(covariant ParticipationHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision != oldWidget.revision &&
        (_periods != null || _loading)) {
      _load(refresh: true);
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading && !refresh) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final periods = await widget.repository.getMyParticipation();
      if (mounted && generation == _generation) {
        setState(() => _periods = periods);
      }
    } on AuthFailure catch (failure) {
      if (mounted && generation == _generation) {
        setState(() => _error = failure.message);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'Unable to load participation history.');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  String _date(DateTime value) =>
      '${value.toIso8601String().substring(0, 10)} UTC';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        key: const PageStorageKey<String>('mentorship-participation-history'),
        leading: Icon(Icons.history, color: colors.primary),
        title: const Text('Participation History'),
        subtitle: const Text(
          'Current and past enrollment periods, including rejoined sessions.',
        ),
        onExpansionChanged: (expanded) {
          if (expanded && _periods == null) _load();
        },
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: TextStyle(color: colors.error)),
          if (!_loading && _periods?.isEmpty == true)
            const Text(
              'No participation records yet. Join a session to start learning.',
            ),
          if (_error == null)
            for (final period in _periods ?? <MentorshipEnrollment>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.slotTopic,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    MentorshipStatusBadge.enrollmentStatus(
                      period.status,
                      colors,
                    ),
                    if (period.joinedAt != null)
                      Text('Joined ${_date(period.joinedAt!)}'),
                    if (period.leftAt != null)
                      Text('Left ${_date(period.leftAt!)}'),
                    if (period.learningGoal?.isNotEmpty == true)
                      Text('Your goal: ${period.learningGoal}'),
                    if (period.joinMessage?.isNotEmpty == true)
                      Text('Your message: ${period.joinMessage}'),
                  ],
                ),
              ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: Text(_error == null ? 'Refresh History' : 'Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
