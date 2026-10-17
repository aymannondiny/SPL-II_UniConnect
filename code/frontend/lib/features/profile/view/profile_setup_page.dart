import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/model/current_account.dart';
import 'package:uniconnect/features/profile/controller/profile_controller.dart';
import 'package:uniconnect/features/profile/view/profile_draft.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_about_section.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_academic_section.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_preferences.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_identity_card.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({
    required this.account,
    required this.controller,
    required this.onSaved,
    this.onCancel,
    super.key,
  });
  final CurrentAccount account;
  final ProfileController controller;
  final VoidCallback onSaved;
  final VoidCallback? onCancel;
  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _form = GlobalKey<FormState>();
  late final ProfileDraft _draft = ProfileDraft(
    widget.account.fullName,
    widget.controller.profile,
  );
  late String _visibility = widget.controller.visibility;
  bool get _alumni => widget.account.platformRole == 'ALUMNI';
  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        alignment: .15,
        duration: const Duration(milliseconds: 200),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final saved = await widget.controller.save(
      widget.account.platformRole,
      _draft.payload(_alumni),
      _visibility,
    );
    if (mounted && saved) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.controller.profile != null;
    final catalog = widget.controller.catalog!.withCurrentProfile(
      widget.controller.profile,
    );
    final about = ProfileAboutSection(draft: _draft);
    final academics = ProfileAcademicSection(
      draft: _draft,
      catalog: catalog,
      alumni: _alumni,
      onChanged: () => setState(() {}),
      onReload: widget.controller.reloadCatalog,
    );
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? 'My profile' : 'Make yourself at home.',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            editing
                ? 'Keep your details up to date and choose what you share.'
                : 'Set up your ${_alumni ? 'alumni' : 'student'} profile to join the UniConnect community.',
          ),
          const SizedBox(height: 24),
          ProfileIdentityCard(
            name: widget.account.fullName,
            role: widget.account.platformRole,
            programme: widget.controller.profile?.academicLabel,
          ),
          const SizedBox(height: 20),
          AbsorbPointer(
            absorbing:
                widget.controller.saving || widget.controller.catalogLoading,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 850
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: about),
                            const SizedBox(width: 20),
                            Expanded(child: academics),
                          ],
                        )
                      : Column(
                          children: [
                            about,
                            const SizedBox(height: 20),
                            academics,
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Availability and privacy',
                  child: ProfilePreferences(
                    student: !_alumni,
                    projects: _draft.projects,
                    mentorship: _draft.mentorship,
                    visibility: _visibility,
                    onProjects: (v) => setState(() => _draft.projects = v),
                    onMentorship: (v) => setState(() => _draft.mentorship = v),
                    onVisibility: (v) => setState(() => _visibility = v),
                  ),
                ),
              ],
            ),
          ),
          if (widget.controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  widget.controller.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (widget.onCancel != null)
                OutlinedButton(
                  onPressed: widget.controller.saving ? null : widget.onCancel,
                  child: const Text('Back to home'),
                ),
              FilledButton.icon(
                onPressed:
                    widget.controller.saving ||
                        widget.controller.catalogLoading ||
                        catalog.degrees.isEmpty
                    ? null
                    : _save,
                icon: widget.controller.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(
                  widget.controller.saving
                      ? 'Saving changes…'
                      : editing
                      ? 'Save changes'
                      : 'Save and continue',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
