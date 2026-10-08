import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sign_token.dart';

/// Persists the shared "Transkripsi AI" so it survives model switches,
/// leaving/re-entering the screen, and app restarts. Cleared only by RESET.
abstract interface class SignTranscriptStore {
  Future<List<SignToken>> load();
  Future<void> save(List<SignToken> tokens);
}

class SharedPrefsSignTranscriptStore implements SignTranscriptStore {
  static const String kStorageKey = 'sign_language.transcript_tokens.v1';
  static const int kMaxTokens = 500;

  const SharedPrefsSignTranscriptStore();

  @override
  Future<List<SignToken>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kStorageKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(SignToken.tryFromJson)
          .whereType<SignToken>()
          .toList(growable: false);
    } catch (e) {
      debugPrint('[SIGN_TRANSCRIPT] load skipped: $e');
      return const [];
    }
  }

  @override
  Future<void> save(List<SignToken> tokens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (tokens.isEmpty) {
        await prefs.remove(kStorageKey);
        return;
      }
      final bounded = tokens.length > kMaxTokens
          ? tokens.sublist(tokens.length - kMaxTokens)
          : tokens;
      await prefs.setString(
        kStorageKey,
        jsonEncode(bounded.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[SIGN_TRANSCRIPT] save skipped: $e');
    }
  }
}

/// In-memory store (tests / previews).
class InMemorySignTranscriptStore implements SignTranscriptStore {
  List<SignToken> saved;

  InMemorySignTranscriptStore([List<SignToken>? initial])
    : saved = List.of(initial ?? const []);

  @override
  Future<List<SignToken>> load() async => List.of(saved);

  @override
  Future<void> save(List<SignToken> tokens) async {
    saved = List.of(tokens);
  }
}
