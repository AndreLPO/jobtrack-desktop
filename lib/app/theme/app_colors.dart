import 'package:flutter/material.dart';

/// Paleta provisória (D-42): neutros + uma cor de destaque.
abstract final class AppColors {
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E5EA);

  static const textPrimary = Color(0xFF1F2328);
  static const textSecondary = Color(0xFF5B636E);

  static const accent = Color(0xFF2563EB);
  static const accentSubtle = Color(0xFFE8EFFD);
  static const onAccent = Color(0xFFFFFFFF);

  static const error = Color(0xFFC62828);
  static const onError = Color(0xFFFFFFFF);

  static const warningSubtle = Color(0xFFFFF4E0);
  static const warningText = Color(0xFF7A4B00);

  /// Fundo dos badges de status. O texto do status é sempre exibido; a
  /// cor só reforça (PROJECT.md §7.2).
  static const statusOpen = Color(0xFFF0F2F5);
  static const statusResponded = accentSubtle;
  static const statusClosed = Color(0xFFEDEDED);

  static const feedback = Color(0xFF1F2328);
  static const onFeedback = Color(0xFFFFFFFF);
}
