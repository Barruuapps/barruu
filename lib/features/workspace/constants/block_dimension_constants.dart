/// Shared dimension constants used across block widgets.
///
/// Centralising these values prevents drift between writer and reader
/// implementations and makes responsive tweaks a one-line change.
class BlockDimensionConstants {
  BlockDimensionConstants._();

  // ── Responsive breakpoints ──────────────────────────────────────────────
  /// Minimum screen width (dp) to switch from mobile to wide/tablet layout.
  static const double mobileBreakpoint = 600.0;

  // ── Container heights ───────────────────────────────────────────────────
  /// Legacy maximum height used for table and PDF blocks (kept for reference).
  static const double legacyMaxBlockHeight = 400.0;

  /// Row-card preview width used in the Rows block editor.
  static const double rowPreviewWidth = 280.0;

  // ── Touch targets ────────────────────────────────────────────────────────
  /// Minimum touch-target size per Apple HIG / Material guidelines (44 dp).
  static const double minTouchTarget = 44.0;

  // ── Spacing / padding ────────────────────────────────────────────────────
  /// Horizontal padding around chat avatars.
  static const double chatAvatarPadding = 8.0;

  // ── Snackbar ─────────────────────────────────────────────────────────────
  /// Duration (seconds) the undo snackbar is shown after a deletion.
  static const Duration undoSnackbarDuration = Duration(seconds: 4);
}
