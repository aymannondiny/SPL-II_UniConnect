import 'package:uniconnect/features/administration/view/administration_section_picker.dart';
import 'package:uniconnect/features/administration/data/account_moderation_repository.dart';
import 'package:uniconnect/features/administration/view/account_moderation_page.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';
import 'package:uniconnect/features/reporting/view/reports_page.dart';
import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/administration/data/admin_catalog_repository.dart';
import 'package:uniconnect/features/administration/data/admin_club_repository.dart';
import 'package:uniconnect/features/administration/model/admin_academic_catalog.dart';
import 'package:uniconnect/features/administration/view/club_admin_workspace.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

part 'academic_option_dialog.dart';
part 'academic_catalog_widgets.dart';
part 'academic_catalog_rows.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({
    required this.repository,
    required this.clubRepository,
    this.accountRepository,
    this.reportRepository,
    this.currentUserId,
    this.initialSection = 0,
    this.showSectionPicker = true,
    super.key,
  });
  final AdminCatalogRepository repository;
  final AdminClubRepository clubRepository;
  final AccountModerationRepository? accountRepository;
  final ReportRepository? reportRepository;
  final int? currentUserId;
  final int initialSection;
  final bool showSectionPicker;

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  AdminAcademicCatalog? _catalog;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _selectedTab = 0;
  late int _section = widget.initialSection;

  @override
  void initState() {
    super.initState();
    if (_section == 0) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await widget.repository.list();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failure.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load the academic catalog. Please retry.';
        _loading = false;
      });
    }
  }

  Future<void> _edit({Object? item}) async {
    final catalog = _catalog;
    if (catalog == null || _saving) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          AcademicOptionDialog(tab: _selectedTab, catalog: catalog, item: item),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      switch (_selectedTab) {
        case 0:
          final department = item as AdminDepartment?;
          await widget.repository.saveDepartment(
            result['name'] as String,
            result['code'] as String,
            id: department?.id,
          );
          break;
        case 1:
          final programme = item as AdminProgramme?;
          await widget.repository.saveProgramme(
            result['name'] as String,
            result['code'] as String,
            result['departmentId'] as int,
            id: programme?.id,
          );
          break;
        case 2:
          final degree = item as AdminDegree?;
          await widget.repository.saveDegree(
            programmeId: result['programmeId'] as int,
            level: result['degreeLevel'] as String,
            durationYears: result['durationYears'] as int,
            minimumYear: result['minimumYear'] as int,
            maximumYear: result['maximumYear'] as int,
            active: result['active'] as bool,
            id: degree?.id,
          );
          break;
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? 'Catalog entry added.' : 'Changes saved.',
          ),
        ),
      );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save this catalog entry.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = _catalog;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.showSectionPicker
                      ? 'Administration'
                      : [
                          'Academic catalog',
                          'Club administration',
                          'Club requests',
                          'Account management',
                          'Report queue',
                        ][_section],
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage academic options, clubs, accounts and reports.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_section == 0)
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (widget.showSectionPicker)
          AdministrationSectionPicker(
            selected: _section,
            accountsEnabled: widget.accountRepository != null,
            reportsEnabled: widget.reportRepository != null,
            onChanged: (value) {
              setState(() => _section = value);
              if (value == 0 && _catalog == null) _load();
            },
          ),
        const SizedBox(height: 18),
        if (_section == 3 && widget.accountRepository != null)
          AccountModerationPage(repository: widget.accountRepository!)
        else if (_section == 4 && widget.reportRepository != null)
          ReportsPage(
            repository: widget.reportRepository!,
            administration: true,
            currentUserId: widget.currentUserId,
          )
        else if (_section == 1)
          AdminClubWorkspace(repository: widget.clubRepository)
        else if (_section == 2)
          AdminClubRequests(repository: widget.clubRepository)
        else ...[
          if (_loading && catalog == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && catalog == null)
            SectionCard(
              title: 'Academic catalog',
              child: _EmptyCatalog(
                message: _error!,
                action: TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
            )
          else if (catalog != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 720
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth >= 460
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                final activeDegrees = catalog.degrees
                    .where((degree) => degree.active)
                    .length;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        label: 'Departments',
                        value: '${catalog.departments.length}',
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        label: 'Programmes',
                        value: '${catalog.programmes.length}',
                        icon: Icons.menu_book_outlined,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        label: 'Active degree options',
                        value: activeDegrees.toString(),
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Academic catalog',
              subtitle: 'Changes are saved to the UniConnect academic catalog.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Departments')),
                      ButtonSegment(value: 1, label: Text('Programmes')),
                      ButtonSegment(value: 2, label: Text('Degrees')),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: _saving
                        ? null
                        : (value) => setState(() => _selectedTab = value.first),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _edit(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(switch (_selectedTab) {
                        0 => 'Add department',
                        1 => 'Add programme',
                        _ => 'Add degree',
                      }),
                    ),
                  ),
                  if (_saving)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    const SizedBox(height: 2),
                  _catalogItems(catalog),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}
