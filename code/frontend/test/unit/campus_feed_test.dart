import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/club/controller/campus_feed.dart';
import 'package:uniconnect/features/club/model/club_page.dart';

void main() {
  test('obsolete responses cannot replace a newer search', () async {
    final old = Completer<ClubPage<String>>();
    var calls = 0;
    final feed = CampusFeed<String>(
      (_) =>
          calls++ == 0 ? old.future : Future.value(const ClubPage(['new'], 1)),
    );
    final previous = feed.load();
    await feed.load();
    old.complete(const ClubPage(['old'], 1));
    await previous;
    expect(feed.items, ['new']);
    expect(feed.loading, isFalse);
    feed.dispose();
  });

  test('load-more failures retain rows and retry the same page', () async {
    var fail = true;
    final pages = <int>[];
    final feed = CampusFeed<String>((page) async {
      pages.add(page);
      if (page == 0) return const ClubPage(['first'], 2);
      if (fail) throw const AuthFailure('Offline');
      return const ClubPage(['second'], 2);
    });
    await feed.load();
    await feed.load(reset: false);
    expect(feed.items, ['first']);
    expect(feed.error, 'Offline');
    fail = false;
    await feed.load(reset: false);
    expect(pages, [0, 1, 1]);
    expect(feed.items, ['first', 'second']);
    expect(feed.hasMore, isFalse);
    feed.dispose();
  });

  test('late requests after disposal do not notify', () async {
    final response = Completer<ClubPage<String>>();
    final feed = CampusFeed<String>((_) => response.future);
    final request = feed.load();
    feed.dispose();
    response.complete(const ClubPage(['late'], 1));
    await request;
  });
}
