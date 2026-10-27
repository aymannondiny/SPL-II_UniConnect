import 'package:uniconnect/features/career/data/career_application_resolver.dart';

import 'dart:async';

import 'package:uniconnect/features/career/view/widgets/career_board_tabs.dart';
import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/career/data/career_repository.dart';
import 'package:uniconnect/features/career/model/career_models.dart';
import 'package:uniconnect/features/career/view/career_post_form_dialog.dart';
import 'package:uniconnect/features/career/view/widgets/career_post_card.dart';
import 'package:uniconnect/features/career/view/widgets/career_post_details_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

part 'career_board_actions.dart';
part 'career_board_filters.dart';
part 'career_board_results.dart';

class CareerBoardPage extends StatefulWidget {
  const CareerBoardPage({
    required this.repository,
    required this.role,
    this.currentUserId,
    this.active = true,
    super.key,
  });

  final CareerRepository repository;
  final String role;
  final int? currentUserId;
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
      } else if ((_student || _alumni) && !_savedTab) {
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

  void _update(VoidCallback action) => setState(action);

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        const SizedBox(height: 18),
        CareerBoardTabs(
          alumni: _alumni,
          secondarySelected: _savedTab,
          onChanged: _loading || _loadingMore ? null : _switchTab,
        ),
        if (!_savedTab) ...[const SizedBox(height: 20), _filters(theme)],
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
}
