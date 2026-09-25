import 'package:flutter/material.dart';

import '../models/sign_language_model.dart';
import 'sign_language_screen.dart';

export 'sign_language_screen.dart';

/// Backward-compatible alias for [SignLanguageScreen].
/// Ensures existing routes, tests, and deep links continue to function without breaking changes.
class BisindoScreen extends StatelessWidget {
  final SignLanguageModel initialModel;

  const BisindoScreen({super.key, this.initialModel = SignLanguageModel.sibi});

  @override
  Widget build(BuildContext context) {
    return SignLanguageScreen(initialModel: initialModel);
  }
}
