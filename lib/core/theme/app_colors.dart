import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFF6366F1);        // Indigo
  static const Color brandLight = Color(0xFF818CF8);
  static const Color brandDark = Color(0xFF4F46E5);
  static const Color brandSurface = Color(0xFF1E1B4B);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Google colors
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleBlue = Color(0xFF4285F4);

  // Microsoft / OneDrive colors
  static const Color microsoftBlue = Color(0xFF0078D4);
  static const Color oneDriveBlue = Color(0xFF0062AD);

  // Chart colors
  static const List<Color> chartPalette = [
    Color(0xFF6366F1),  // Indigo
    Color(0xFF06B6D4),  // Cyan
    Color(0xFF10B981),  // Emerald
    Color(0xFFF59E0B),  // Amber
    Color(0xFFEF4444),  // Red
    Color(0xFF8B5CF6),  // Violet
    Color(0xFFEC4899),  // Pink
    Color(0xFF14B8A6),  // Teal
  ];

  // Dark theme
  static const Color darkBackground = Color(0xFF0F0F18);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkBorder = Color(0xFF2A2A4A);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light theme
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
}
