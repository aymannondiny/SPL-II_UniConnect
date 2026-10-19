import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/club_repository.dart';
import '../model/club.dart';
import '../model/club_announcement.dart';
import '../model/club_event.dart';
import 'campus_feed.dart';

class ClubsController extends ChangeNotifier {
  ClubsController(this.repository) {
    clubs = CampusFeed((page) => repository.clubs(search, page));
    announcements = CampusFeed(
      (page) => repository.announcements(selected?.id, page),
    );
    events = CampusFeed(
      (page) => repository.events(selected?.id, timing, page),
    );
    announcements.addListener(_scheduleBoundary);
    events.addListener(_scheduleBoundary);
  }

  final ClubRepository repository;
  late final CampusFeed<Club> clubs;
  late final CampusFeed<ClubAnnouncement> announcements;
  late final CampusFeed<ClubEvent> events;
  Club? selected;
  String search = '';
  String timing = 'ALL';
  bool active = true;
  Timer? _boundary;

  Future<void> load() async {
    await Future.wait([clubs.load(), announcements.load(), events.load()]);
  }

  void searchClubs(String value) {
    search = value.trim();
    unawaited(clubs.load());
  }

  void select(Club? club) {
    selected = club;
    if (club == null && timing == 'PAST') timing = 'ALL';
    notifyListeners();
    refreshPublications();
  }

  void filterTiming(String value) {
    if (value == 'PAST' && selected == null) return;
    timing = value;
    notifyListeners();
    unawaited(events.load());
  }

  void refreshPublications() {
    unawaited(announcements.load());
    unawaited(events.load());
  }

  void setActive(bool value) {
    active = value;
    if (value) {
      refreshPublications();
    } else {
      _boundary?.cancel();
    }
  }

  void _scheduleBoundary() {
    _boundary?.cancel();
    if (!active || announcements.loading || events.loading) return;
    final now = DateTime.now();
    final boundaries = [
      for (final item in announcements.items)
        if (item.expiresAt != null) item.expiresAt!,
      for (final item in events.items) ...[item.startsAt, item.endsAt],
    ].where((time) => time.isAfter(now)).toList()..sort();
    if (boundaries.isEmpty) return;
    _boundary = Timer(
      boundaries.first.difference(now) + const Duration(milliseconds: 100),
      refreshPublications,
    );
  }

  @override
  void dispose() {
    _boundary?.cancel();
    clubs.dispose();
    announcements.dispose();
    events.dispose();
    super.dispose();
  }
}
