import 'package:flutter/material.dart';

/// Все цвета приложения в одном месте.
abstract final class AppColors {
  // ─── Фоны ───────────────────────────────────────────────────────────────────

  /// Самый тёмный фон, основной цвет приложения
  static const Color bgBase = Color(0xFF121316);

  /// Верх градиента в модалках
  static const Color bgSurface = Color(0xFF1E1F23);

  /// Карточки в настройках
  static const Color bgCard = Color(0xFF18191D);

  /// Контейнеры иконок в настройках, разделители
  static const Color bgElevated = Color(0xFF262930);

  /// Нижний бар
  static const Color bgBar = Color(0xFF0F1012);

  /// Слайдер / трек / разделители settings
  static const Color bgDivider = Color(0xFF2A2D35);

  // ─── Текст ──────────────────────────────────────────────────────────────────

  /// Основной текст
  static const Color textPrimary = Colors.white;

  /// Вторичный серый текст (подзаголовки в модалках)
  static const Color textSecondary = Color(0xFF8E939D);

  /// Третичный серый (мелкие подписи, счётчики)
  static const Color textTertiary = Color(0xFF6B7280);

  /// Четвёртый уровень (крестики, placeholder-иконки)
  static const Color textMuted = Color(0xFF9CA3AF);

  // ─── Акценты ────────────────────────────────────────────────────────────────

  /// Зелёный — доступно, ЧС
  static const Color accentGreen = Color(0xFF10B981);

  /// Красный — заблокировано, ошибка, БС
  static const Color accentRed = Color(0xFFEF4444);

  /// Жёлтый — предупреждение, VPN
  static const Color accentYellow = Color(0xFFF59E0B);

  /// Синий — информация, отчёт
  static const Color accentBlue = Color(0xFF3B82F6);

  // ─── Оверлеи (белый с прозрачностью) ────────────────────────────────────────

  /// Рамки модалок, баров
  static Color borderSubtle  = Colors.white.withValues(alpha: 0.08);
  static Color borderDefault = Colors.white.withValues(alpha: 0.10);
  static Color borderStrong  = Colors.white.withValues(alpha: 0.12);

  /// Фоны кнопок / контейнеров поверх поверхности
  static Color overlayFaint  = Colors.white.withValues(alpha: 0.03);
  static Color overlayLight  = Colors.white.withValues(alpha: 0.06);

  /// Скроллбар
  static Color scrollThumb   = Colors.white.withValues(alpha: 0.15);

  // ─── Градиенты ──────────────────────────────────────────────────────────────

  /// Стандартный градиент модалок (сверху вниз)
  static const LinearGradient modalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgSurface, bgBase],
  );
}
