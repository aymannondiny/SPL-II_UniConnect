import 'package:uniconnect/features/career/data/career_application_resolver.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/career/data/career_repository.dart';
import 'package:uniconnect/features/career/model/career_models.dart';
import 'package:uniconnect/features/career/view/career_post_form_dialog.dart';
import 'package:uniconnect/features/career/view/widgets/career_post_card.dart';
import 'package:uniconnect/features/career/view/widgets/career_post_details_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerBoardPage extends StatefulWidget {
  const CareerBoardPage({
    required this.repository,
    required this.role,
    this.active = true,
    super.key,
  });

  final CareerRepository repository;
  final String role;
  final bool active;

  @override
  State<CareerBoardPage> createState() => _CareerBoardPageState();
}

class _CareerBoardPageState extends State<CareerBoardPage> {
  final _location = TextEditingController();
  final _skill = TextEditingController();
  final Set<int> _busyPosts = {};
  List<CareerPost> _posts = [];
  List<SavedCareerPost> _saved = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _savedTab = false;
  String? _error;
  int _page = 0;
  int _total = 0;
  int _queryRevision = 0;
  CareerEmploymentType? _employmentType;
  CareerWorkMode? _workMode;
  CareerSort _sort = CareerSort.newest;

  bool get _student => widget.role == 'STUDENT';
  bool get _alumni => widget.role == 'ALUMNI';
  bool get _hasActiveFilters =>
      _employmentType != null ||
      _workMode != null ||
      _location.text.trim().isNotEmpty ||
      _skill.text.trim().isNotEmpty;
  int get _visibleCount =>
      _student && _savedTab ? _saved.length : _posts.length;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant CareerBoardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) unawaited(_load());
  }

  @override
  void dispose() {
    _location.dispose();
    _skill.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading || _loadingMore) return;
    final nextPage = more ? _page + 1 : 0;
    final revision = _queryRevision;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
        _page = 0;
        _total = 0;
      }
    });
    try {
      if (_student && _savedTab) {
        final result = await widget.repository.saved(page: nextPage);
        if (!mounted) return;
        setState(() {
          _saved = more ? [..._saved, ...result.items] : result.items;
          _page = result.page;
          _total = result.totalElements;
        });
      } else if (_student) {
        final result = await widget.repository.browse(
          page: nextPage,
          employmentType: _employmentType,
          workMode: _workMode,
          location: _location.text.trim(),
          skill: _skill.text.trim(),
          sort: _sort,
        );
        if (!mounted) return;
        setState(() {
          _posts = more ? [..._posts, ...result.items] : result.items;
          _page = result.page;
          _total = result.totalElements;
        });
      } else if (_alumni) {
        final result = await widget.repository.mine(page: nextPage);
        if (!mounted) return;
        setState(() {
          _posts = more ? [..._posts, ...result.items] : result.items;
          _page = result.page;
          _total = result.totalElements;
        });
      }
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Unable to load Career Board. Please retry.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
        if (revision != _queryRevision) unawaited(_load());
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
    setState(() {});
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
      if (mounted) setState(() {});
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

  void _switchTab(bool saved) {
    if (_savedTab == saved || _loading || _loadingMore) return;
    setState(() {
      _savedTab = saved;
      _error = null;
      _queryRevision++;
    });
    unawaited(_load());
  }

  void _setEmployment(CareerEmploymentType? value) {
    if (_employmentType == value) return;
    setState(() {
      _employmentType = value;
      _queryRevision++;
    });
    unawaited(_load());
  }

  void _setWorkMode(CareerWorkMode? value) {
    if (_workMode == value) return;
    setState(() {
      _workMode = value;
      _queryRevision++;
    });
    unawaited(_load());
  }

  void _applyFilters() {
    setState(() => _queryRevision++);
    unawaited(_load());
  }

  void _clearFilters() {
    _location.clear();
    _skill.clear();
    setState(() {
      _employmentType = null;
      _workMode = null;
      _queryRevision++;
    });
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    if (!_student && !_alumni) return _restricted(context);
    final theme = Theme.of(context);
    final posts = _student && _savedTab
        ? _saved.map((item) => item.post).toList()
        : _posts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(theme),
        if (_student) ...[
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'browse',
                label: Text('Browse opportunities'),
                icon: Icon(Icons.search),
              ),
              ButtonSegment(
                value: 'saved',
                label: Text('Saved'),
                icon: Icon(Icons.bookmark_border),
              ),
            ],
            selected: {_savedTab ? 'saved' : 'browse'},
            onSelectionChanged: (selection) =>
                _switchTab(selection.first == 'saved'),
          ),
        ],
        if (_student && !_savedTab) ...[
          const SizedBox(height: 20),
          _filters(theme),
        ],
        const SizedBox(height: 18),
        if (_error != null) _errorPanel(theme),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_student && _savedTab)
          _savedContent(theme)
        else
          _postContent(theme, posts),
        if (!_loading && _error == null && _visibleCount < _total) ...[
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadingMore ? null : () => _load(more: true),
              icon: _loadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(_loadingMore ? 'Loading…' : 'Load more'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(ThemeData theme) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 14,
      spacing: 16,
      children: [
        SizedBox(
          width: constraints.maxWidth > 460
              ? constraints.maxWidth - 210
              : constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Career board',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _student
                    ? 'Explore internships and jobs shared by your alumni community.'
                    : 'Share opportunities with students and manage your posts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_alumni)
          FilledButton.icon(
            onPressed: _createPost,
            icon: const Icon(Icons.add),
            label: const Text('Post an opportunity'),
          ),
      ],
    ),
  );

  Widget _filters(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _employmentType == null,
            onSelected: (_) => _setEmployment(null),
          ),
          for (final type in CareerEmploymentType.values)
            ChoiceChip(
              label: Text(type.label),
              selected: _employmentType == type,
              onSelected: (_) => _setEmployment(type),
            ),
        ],
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final fields = [
            SizedBox(
              width: wide ? 210 : constraints.maxWidth,
              child: TextField(
                controller: _location,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.place_outlined),
                  counterText: '',
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: wide ? 210 : constraints.maxWidth,
              child: TextField(
                controller: _skill,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Skill',
                  prefixIcon: Icon(Icons.sell_outlined),
                  counterText: '',
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: wide ? 170 : constraints.maxWidth,
              child: DropdownButtonFormField<CareerWorkMode?>(
                initialValue: _workMode,
                decoration: const InputDecoration(labelText: 'Work mode'),
                items: [
                  const DropdownMenuItem<CareerWorkMode?>(
                    value: null,
                    child: Text('Any mode'),
                  ),
                  for (final mode in CareerWorkMode.values)
                    DropdownMenuItem<CareerWorkMode?>(
                      value: mode,
                      child: Text(mode.label),
                    ),
                ],
                onChanged: _setWorkMode,
              ),
            ),
            SizedBox(
              width: wide ? 190 : constraints.maxWidth,
              child: DropdownButtonFormField<CareerSort>(
                initialValue: _sort,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: const [
                  DropdownMenuItem(
                    value: CareerSort.newest,
                    child: Text('Most recent'),
                  ),
                  DropdownMenuItem(
                    value: CareerSort.deadline,
                    child: Text('Closing soon'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _sort = value;
                    _queryRevision++;
                  });
                  unawaited(_load());
                },
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _loading ? null : _applyFilters,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Apply filters'),
            ),
          ];
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: fields,
          );
        },
      ),
    ],
  );

  Widget _postContent(ThemeData theme, List<CareerPost> posts) {
    if (_error != null && posts.isEmpty) return const SizedBox.shrink();
    if (posts.isEmpty) {
      return _emptyState(
        theme,
        icon: _alumni ? Icons.work_outline : Icons.search_off_outlined,
        title: _alumni
            ? 'No opportunities yet'
            : _hasActiveFilters
            ? 'No matching opportunities'
            : 'No active opportunities yet',
        message: _alumni
            ? 'Share an internship or job opening to help students take their next step.'
            : _hasActiveFilters
            ? 'No active roles match these filters. Clear them to see all available opportunities.'
            : 'There are no active roles published right now. Check back as alumni share new opportunities.',
        action: _alumni
            ? FilledButton.icon(
                onPressed: _createPost,
                icon: const Icon(Icons.add),
                label: const Text('Post an opportunity'),
              )
            : _hasActiveFilters
            ? OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              )
            : OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
      );
    }
    if (_student && !_savedTab) {
      return _jobGrid(
        posts,
        (post) => CareerPostCard(
          post: post,
          onOpen: () => _showDetails(post),
          onApply: post.canApply && !_busyPosts.contains(post.id)
              ? () => _showDetails(post)
              : null,
          onToggleSave: _busyPosts.contains(post.id)
              ? null
              : () => _toggleSave(post),
        ),
      );
    }
    return _jobGrid(
      posts,
      (post) => CareerPostCard(
        post: post,
        onOpen: () => _showDetails(post),
        onEdit: _canEdit(post) ? () => _editPost(post) : null,
        onClose: post.status == CareerAvailability.published
            ? () => _closePost(post)
            : null,
      ),
    );
  }

  Widget _savedContent(ThemeData theme) {
    if (_error != null && _saved.isEmpty) return const SizedBox.shrink();
    if (_saved.isEmpty) {
      return _emptyState(
        theme,
        icon: Icons.bookmark_border,
        title: 'Your saved opportunities will appear here',
        message:
            'Save a post to keep it handy and add a private note for yourself.',
        action: TextButton.icon(
          onPressed: () => _switchTab(false),
          icon: const Icon(Icons.search),
          label: const Text('Browse opportunities'),
        ),
      );
    }
    return _jobGrid(_saved.map((item) => item.post).toList(), (post) {
      final saved = _saved.firstWhere((item) => item.post.id == post.id);
      return CareerPostCard(
        post: post,
        onOpen: () => _showDetails(post),
        showSavedNote: true,
        savedNote: saved.note,
        onEditNote: () => _editNote(saved),
        onApply: post.canApply ? () => _showDetails(post) : null,
        onToggleSave: _busyPosts.contains(post.id)
            ? null
            : () => _toggleSave(post),
      );
    });
  }

  Widget _jobGrid(List<CareerPost> posts, Widget Function(CareerPost) card) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 2 : 1;
          final gap = 16.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final post in posts)
                SizedBox(width: width, child: card(post)),
            ],
          );
        },
      );

  bool _canEdit(CareerPost post) {
    final deadline = post.applicationDeadline;
    return post.status == CareerAvailability.published &&
        deadline != null &&
        !DateUtils.dateOnly(deadline)
            .isBefore(DateUtils.dateOnly(DateTime.now()));
  }

  Widget _emptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
      ),
    ),
    child: Column(
      children: [
        Icon(icon, size: 38, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );

  Widget _errorPanel(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.errorContainer.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!)),
        TextButton.icon(
          onPressed: _loading ? null : () => _load(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _restricted(BuildContext context) {
    final theme = Theme.of(context);
    return _emptyState(
      theme,
      icon: Icons.lock_outline,
      title: 'Career Board access is limited',
      message: 'Students can browse and save opportunities. Alumni can publish and manage their own posts.',
    );
  }
}
