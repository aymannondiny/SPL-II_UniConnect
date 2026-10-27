part of 'club_management_panel.dart';

extension _ClubPublicationLists on _ClubManagementPanelState {
  Widget _announcementList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _saving ? null : () => _editAnnouncement(),
          icon: const Icon(Icons.add),
          label: const Text('New announcement'),
        ),
      ),
      if (_announcements.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No announcements yet.'),
        )
      else
        for (final item in _announcements)
          Card(
            margin: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Chip(
                        label: Text(item.status),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    item.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        onPressed:
                            _saving ||
                                item.status == 'REMOVED' ||
                                item.status == 'EXPIRED'
                            ? null
                            : () => _editAnnouncement(item: item),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit'),
                      ),
                      if (item.status == 'UNPUBLISHED')
                        FilledButton.icon(
                          onPressed: _saving || _club?.status != 'ACTIVE'
                              ? null
                              : () => _publish(item, 'publish'),
                          icon: const Icon(Icons.publish, size: 17),
                          label: const Text('Publish'),
                        ),
                      if (item.status == 'PUBLISHED')
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => _publish(item, 'unpublish'),
                          child: const Text('Unpublish'),
                        ),
                      if (item.status != 'REMOVED')
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => _publish(item, 'remove'),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ],
  );

  Widget _eventList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _saving || _club?.status != 'ACTIVE'
              ? null
              : () => _editEvent(),
          icon: const Icon(Icons.add),
          label: const Text('New event'),
        ),
      ),
      if (_events.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No events yet.'),
        )
      else
        for (final item in _events)
          Card(
            margin: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Chip(
                        label: Text(item.status),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    '${item.startsAt.toLocal()} · ${item.location ?? 'Location to be announced'}',
                  ),
                  if (item.registrationUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Registration link: ${item.registrationUrl}'),
                    ),
                  if (item.registrationDeadline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Register by ${item.registrationDeadline!.toLocal()}',
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving || item.status == 'REMOVED'
                            ? null
                            : () => _editEvent(item: item),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit'),
                      ),
                      if (item.status != 'REMOVED')
                        TextButton(
                          onPressed: _saving ? null : () => _removeEvent(item),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ],
  );
}
