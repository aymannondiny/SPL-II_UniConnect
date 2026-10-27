part of 'career_board_page.dart';

extension _CareerBoardActions on _CareerBoardPageState {
  Future<void> _showDetails(CareerPost post) async {
    try {
      final fresh = await widget.repository.detail(post.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => CareerPostDetailsDialog(
          post: fresh,
          studentView: _student,
          onApply: _student ? _apply : null,
          onToggleSave: _student ? _toggleSave : null,
        ),
      );
    } on AuthFailure catch (failure) {
      _toast(failure.message);
    } on Object {
      _toast(
        'Unable to load this opportunity. Refresh the board and try again.',
      );
    }
  }

  Future<void> _toggleSave(CareerPost post) async {
    if (!_busyPosts.add(post.id)) return;
    _update(() {});
    try {
      if (post.saved) {
        await widget.repository.unsave(post.id);
        _toast('Removed from saved opportunities.');
      } else {
        await widget.repository.save(post.id);
        _toast('Opportunity saved.');
      }
      await _load();
    } on AuthFailure catch (failure) {
      _toast(failure.message);
    } on Object {
      _toast('Unable to update saved opportunities. Please retry.');
    } finally {
      _busyPosts.remove(post.id);
      if (mounted) _update(() {});
    }
  }

  Future<void> _editNote(SavedCareerPost saved) async {
    final controller = TextEditingController(text: saved.note ?? '');
    final note = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Private note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 1000,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Add a reminder for yourself…',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save note'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || !mounted) return;
    try {
      await widget.repository.updateNote(saved.id, note);
      await _load();
      _toast('Private note updated.');
    } on AuthFailure catch (failure) {
      _toast(failure.message);
    } on Object {
      _toast('Unable to update your note. Please retry.');
    }
  }

  Future<void> _apply(CareerPost previous) async {
    late final CareerPost post;
    try {
      post = await widget.repository.detail(previous.id);
      if (!mounted) return;
    } on AuthFailure catch (failure) {
      _toast(failure.message);
      return;
    } on Object {
      _toast('Unable to refresh this opportunity. Please retry.');
      return;
    }
    if (!post.canApply) {
      _toast('Applications are no longer available for this opportunity.');
      await _load();
      return;
    }
    final channels = post.applicationChannels.toList();
    if (channels.isEmpty) {
      _toast('No application channel is available for this opportunity.');
      return;
    }
    if (channels.length == 1) {
      unawaited(_launchApplication(post, channels.single));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose how to apply'),
        children: [
          for (final channel in channels)
            SimpleDialogOption(
              onPressed: () {
                // Start navigation in the user's click before the dialog closes.
                final opening = _launchApplication(post, channel);
                Navigator.pop(dialogContext);
                unawaited(opening);
              },
              child: Row(
                children: [
                  Icon(
                    channel == CareerApplicationChannel.url
                        ? Icons.open_in_new
                        : Icons.email_outlined,
                  ),
                  const SizedBox(width: 12),
                  Text(channel.label),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchApplication(
    CareerPost previous,
    CareerApplicationChannel channel,
  ) async {
    try {
      final uri = await CareerApplicationResolver(widget.repository)
          .resolve(previous.id, channel);
      if (!mounted) return;
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );
      if (!opened) {
        _toast('Could not open the application destination on this device.');
      }
    } on AuthFailure catch (failure) {
      _toast(failure.message);
    } on Object {
      _toast('Unable to open the application destination. Please retry.');
    }
  }

  Future<void> _createPost() async {
    final input = await showDialog<CareerPostInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CareerPostFormDialog(),
    );
    if (input == null || !mounted) return;
    try {
      await widget.repository.create(input);
      _update(() => _savedTab = true);
      await _load();
      _toast('Your opportunity has been published.');
    } on AuthFailure catch (failure) {
      _toast(failure.message);
    } on Object {
      _toast('Unable to publish this opportunity. Please retry.');
    }
  }

  Future<void> _editPost(CareerPost post) async {
    final input = await showDialog<CareerPostInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CareerPostFormDialog(initial: post),
    );
    if (input == null || !mounted) return;
    try {
      await widget.repository.update(post.id, input);
      await _load();
      _toast('Your opportunity has been updated.');
    } on AuthFailure catch (failure) {
      _toast(failure.message);
    } on Object {
      _toast('Unable to update this opportunity. Please retry.');
    }
  }

  Future<void> _closePost(CareerPost post) async {
    final close = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close this opportunity?'),
        content: const Text(
          'Closing is permanent. Students will no longer be able to apply, and this post cannot be reopened.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep open'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close opportunity'),
          ),
        ],
      ),
    );
    if (close != true || !mounted) return;
    try {
      await widget.repository.close(post.id);
      await _load();
      _toast('The opportunity is now closed.');
    } on AuthFailure catch (failure) {
      _toast(failure.message);
    } on Object {
      _toast('Unable to close this opportunity. Please retry.');
    }
  }
}
