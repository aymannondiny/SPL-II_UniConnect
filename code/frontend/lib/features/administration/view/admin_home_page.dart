import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/features/administration/data/admin_dashboard_repository.dart';
import 'package:uniconnect/features/administration/model/admin_dashboard_summary.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/home/view/widgets/feature_card.dart';
import 'package:uniconnect/features/home/view/widgets/campus_features.dart';
import 'package:uniconnect/core/theme/app_theme.dart';
import 'package:uniconnect/features/administration/view/engineering_admin_home_page.dart';

/// Administration landing page links to real workflows, without invented counts.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    required this.name,
    required this.onFeature,
    required this.summaryRepository,
    super.key,
  });
  final String name;
  final ValueChanged<String> onFeature;
  final AdminDashboardRepository summaryRepository;

  static const _areas = [
    CampusFeature(
      'Report queue',
      'Review submitted reports and record supported moderation outcomes.',
      Icons.flag_outlined,
      'Moderation',
      featured: true,
    ),
    CampusFeature(
      'Account management',
      'Find accounts, inspect details, suspend or restore access.',
      Icons.manage_accounts_outlined,
      'Accounts',
    ),
    CampusFeature(
      'Club requests',
      'Review student requests to establish a university club.',
      Icons.playlist_add_check_outlined,
      'Clubs',
    ),
    CampusFeature(
      'Club administration',
      'Create clubs, appoint administrators and manage club publishing.',
      Icons.account_balance_outlined,
      'Clubs',
      featured: true,
    ),
    CampusFeature(
      'Academic catalog',
      'Maintain departments, programmes and degree options.',
      Icons.menu_book_outlined,
      'Catalog',
    ),
  ];

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  AdminDashboardSummary? _summary;
  String? _summaryError;
  bool _summaryLoading = false;
  bool _requestedSummary = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (EngineeringTheme.active(context) && !_requestedSummary) {
      _requestedSummary = true;
      unawaited(_loadSummary());
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    try {
      final result = await widget.summaryRepository.summary();
      if (!mounted) return;
      setState(() => _summary = result);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() => _summaryError = error.message);
    } on Object {
      if (!mounted) return;
      setState(
        () => _summaryError =
            'Administrator statistics are unavailable. Please retry.',
      );
    } finally {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (EngineeringTheme.active(context)) {
      return EngineeringAdminHomePage(
        name: widget.name,
        onFeature: widget.onFeature,
        summary: _summary,
        summaryLoading: _summaryLoading,
        summaryError: _summaryError,
        onRetrySummary: _loadSummary,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Administration overview',
          subtitle: 'Manage the university community',
          child: Text(
            'Review reports, manage account access and keep campus information up to date.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final area in AdminHomePage._areas)
                  SizedBox(
                    width: width,
                    child: FeatureCard(
                      feature: area,
                      compact: columns == 1,
                      onTap: () => widget.onFeature(area.title),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
