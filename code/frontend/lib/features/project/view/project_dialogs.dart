import 'package:uniconnect/features/reporting/view/report_content_button.dart';
import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/project/controller/project_finder_controller.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/model/project_models.dart';
import 'dart:async';

part 'dialogs/project_form_dialog.dart';
part 'dialogs/project_apply_dialog.dart';
part 'dialogs/project_candidates_dialog.dart';
part 'dialogs/project_manage_dialog.dart';
part 'dialogs/project_details_dialog.dart';
part 'dialogs/project_candidate_tile.dart';
part 'dialogs/project_recommendation_tile.dart';
part 'dialogs/project_dialog_widgets.dart';
part 'dialogs/project_dialog_format.dart';

String _projectErrorMessage(Object error, String fallback) =>
    error is AuthFailure ? error.message : fallback;
