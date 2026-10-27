part of '../project_dialogs.dart';

class ProjectDetailsDialog extends StatefulWidget {
  const ProjectDetailsDialog({
    required this.project,
    required this.repository,
    super.key,
  });
  final ProjectListing project;
  final ProjectRepository repository;

  @override
  State<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<ProjectDetailsDialog> {
  late Future<List<ProjectMember>> _members;
  @override
  void initState() {
    super.initState();
    _members = widget.repository.members(widget.project.id);
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: project.availability),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (project.creatorUserId !=
                      widget.repository.session.account?.userId)
                    ReportContentButton(
                      targetType: 'PROJECT',
                      targetId: project.id,
                    ),
                  Text(project.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.groups_outlined,
                        label:
                            '${project.membershipCount} of ${project.teamSizeLimit} teammates',
                      ),
                      _InfoChip(
                        icon: Icons.event_outlined,
                        label:
                            'Apply by ${_formatDateString(project.applicationDeadline)}',
                      ),
                      if (project.courseName != null)
                        _InfoChip(
                          icon: Icons.menu_book_outlined,
                          label: project.courseName!,
                        ),
                      if (project.duration != null)
                        _InfoChip(
                          icon: Icons.schedule_outlined,
                          label: project.duration!,
                        ),
                    ],
                  ),
                  if (project.skills.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Skills',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final skill in project.skills)
                          _SkillChip(skill: skill),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Project team',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<ProjectMember>>(
                    future: _members,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return const Text('Unable to load team members.');
                      }
                      return Column(
                        children: [
                          for (final member in snapshot.data ?? [])
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                child: Text(_initials(member.displayName)),
                              ),
                              title: Text(member.displayName),
                              subtitle: Text(
                                member.role == 'CREATOR'
                                    ? 'Project creator'
                                    : 'Teammate',
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
