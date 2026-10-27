part of 'clubs_page.dart';

extension _ClubRequestWorkflow on _ClubsPageState {
  Future<void> _loadMyRequests() async {
    _update(() {
      _requestLoading = true;
      _requestError = null;
    });
    try {
      final requests = await widget.repository.myRequests();
      if (!mounted) return;
      _update(() {
        _myRequests = requests;
        _requestLoading = false;
      });
    } on AuthFailure catch (failure) {
      if (mounted) {
        _update(() {
          _requestError = failure.message;
          _requestLoading = false;
        });
      }
    } on Object {
      if (mounted) {
        _update(() {
          _requestError = 'Unable to load your club requests. Please retry.';
          _requestLoading = false;
        });
      }
    }
  }

  Future<void> _requestClub() async {
    final values = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const _ClubRequestDialog(),
    );
    if (values == null || !mounted) return;
    _update(() => _requestSaving = true);
    try {
      await widget.repository.submitRequest(
        name: values['name']!,
        category: values['category']!,
        description: values['description']!,
        logoUrl: values['logo'],
        contactEmail: values['email'],
      );
      await _loadMyRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club request submitted for review.')),
        );
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to submit your request. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) _update(() => _requestSaving = false);
    }
  }

  Widget _requestSection() => SectionCard(
    title: 'My club creation requests',
    subtitle: 'Requests are reviewed by a system administrator. If approved, you become an administrator of the new club.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _requestLoading ? null : _loadMyRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh requests'),
            ),
            FilledButton.icon(
              onPressed: _requestSaving ? null : _requestClub,
              icon: const Icon(Icons.add),
              label: const Text('Request a club'),
            ),
          ],
        ),
        if (_requestSaving) const LinearProgressIndicator(minHeight: 2),
        if (_requestLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_requestError != null)
          Column(
            children: [
              Text(_requestError!, textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: _loadMyRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          )
        else if (_myRequests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('You have not requested a club yet.'),
          )
        else
          for (final request in _myRequests)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
              title: Text(request.clubName),
              subtitle: Text(
                '${request.category} · Submitted ${request.createdAt.toLocal().toString().split('.').first}',
              ),
              trailing: Chip(
                label: Text(request.status),
                visualDensity: VisualDensity.compact,
              ),
            ),
      ],
    ),
  );
}
