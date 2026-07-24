import 'package:flutter/material.dart';

/// Centralized design tokens for consistent spacing, sizing, and animations
/// following an **8px soft grid system** used by Notion, Linear, and Stripe.
///
/// Usage:
/// ```dart
/// Container(
///   padding: EdgeInsets.all(DesignTokens.spacing16),
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
///   ),
///   child: AnimatedOpacity(
///     duration: DesignTokens.durationMedium,
///     curve: DesignTokens.curveStandard,
///     opacity: visible ? 1.0 : 0.0,
///     child: child,
///   ),
/// )
/// ```
class DesignTokens {
  DesignTokens._();

  // ============================================================================
  // SPACING (8px base grid — the industry standard)
  // ============================================================================

  /// 2px — ultra-tight spacing for hairline vertical gaps
  static const double spacing2 = 2.0;

  /// 4px — micro-spacing for tight elements (icon gaps, badge padding)
  static const double spacing4 = 4.0;

  /// 8px — the base unit. Use for compact padding, small gaps.
  static const double spacing8 = 8.0;

  /// 12px — half-step only when 8 feels too tight and 16 too loose.
  static const double spacing12 = 12.0;

  /// 16px — default spacing for most containers and card padding.
  static const double spacing16 = 16.0;

  /// 20px — transitional spacing, use sparingly.
  static const double spacing20 = 20.0;

  /// 24px — section spacing, card gaps, comfortable padding.
  static const double spacing24 = 24.0;

  /// 32px — major section separation, page-level padding.
  static const double spacing32 = 32.0;

  /// 40px — hero padding, large card internal spacing.
  static const double spacing40 = 40.0;

  /// 48px — page-level breathing room.
  static const double spacing48 = 48.0;

  /// 56px — comfortable for dashboard section gaps.
  static const double spacing56 = 56.0;

  /// 64px — maximum comfortable padding, hero sections.
  static const double spacing64 = 64.0;

  /// 80px — ultra-large breathing room for premium pages.
  static const double spacing80 = 80.0;

  /// 96px — used for large premium hero areas.
  static const double spacing96 = 96.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// 4px — checkboxes, small chips
  static const double radiusXSmall = 4.0;

  /// 6px — compact cards, inline chips
  static const double radiusSmall = 6.0;

  /// 8px — standard cards, inputs, buttons
  static const double radiusMedium = 8.0;

  /// 12px — larger cards, dialogs, sheets
  static const double radiusLarge = 12.0;

  /// 16px — prominent cards, hero containers
  static const double radiusXLarge = 16.0;

  /// 20px — special presentation containers
  static const double radius2XLarge = 20.0;

  /// 24px — hero cards, feature showcases
  static const double radius3XLarge = 24.0;

  /// Full circle — avatars, circular buttons
  static const double radiusFull = 9999.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// 100ms — micro-interactions (hover, focus, ripple)
  static const Duration durationXFast = Duration(milliseconds: 100);

  /// 150ms — quick transitions (tooltip, badge appear)
  static const Duration durationFast = Duration(milliseconds: 150);

  /// 200ms — standard UI feedback (button press, toggle)
  static const Duration duration200 = Duration(milliseconds: 200);

  /// 250ms — default animation duration (most transitions)
  static const Duration durationMedium = Duration(milliseconds: 250);

  /// 300ms — smooth page-level transitions
  static const Duration duration300 = Duration(milliseconds: 300);

  /// 350ms — emphasized transitions (dialogs, sheets)
  static const Duration durationSlow = Duration(milliseconds: 350);

  /// 500ms — special effects, onboarding animations
  static const Duration durationXSlow = Duration(milliseconds: 500);

  /// 750ms — page reveals, hero animations
  static const Duration durationGlacial = Duration(milliseconds: 750);

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================

  /// Standard — easeInOut, good default for most animations
  static const Curve curveStandard = Curves.easeInOut;

  /// Emphasized — easeOutCubic, for important entrances
  static const Curve curveEmphasized = Curves.easeOutCubic;

  /// Decelerated — easeOut, elements entering the screen
  static const Curve curveDecelerate = Curves.easeOut;

  /// Accelerated — easeIn, elements exiting the screen
  static const Curve curveAccelerate = Curves.easeIn;

  /// Spring — elasticOut, playful bouncy animations
  static const Curve curveSpring = Curves.elasticOut;

  /// Bounce — bounceOut, attention-grabbing
  static const Curve curveBounce = Curves.bounceOut;

  // ============================================================================
  // ELEVATION (Material Design 3)
  // ============================================================================

  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation8 = 8.0;
  static const double elevation12 = 12.0;
  static const double elevation16 = 16.0;
  static const double elevation24 = 24.0;

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// 12px — inline icons within text
  static const double iconXSmall = 12.0;

  /// 16px — compact icons (list trailing, badges)
  static const double iconSmall = 16.0;

  /// 20px — sidebar icons, compact buttons
  static const double iconCompact = 20.0;

  /// 24px — standard icon size (app bar, buttons)
  static const double iconMedium = 24.0;

  /// 28px — slightly larger for sidebar primary
  static const double iconLarge = 28.0;

  /// 32px — prominent icons
  static const double iconXLarge = 32.0;

  /// 40px — hero icons, empty state illustrations
  static const double icon2XLarge = 40.0;

  /// 48px — large hero icons
  static const double icon3XLarge = 48.0;

  /// 64px — empty state primary illustration
  static const double iconHero = 64.0;

  // ============================================================================
  // TYPOGRAPHY — Design tokens for font weights
  // ============================================================================

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightExtraBold = FontWeight.w800;

  /// Comfortable line-height multiplier for body text (1.6)
  static const double lineHeightBody = 1.6;

  /// Tight line-height for headings (1.25)
  static const double lineHeightHeading = 1.25;

  /// Compact line-height for labels/captions (1.35)
  static const double lineHeightLabel = 1.35;

  // ============================================================================
  // COMPONENT SIZING
  // ============================================================================

  /// Standard button height
  static const double buttonHeightMedium = 40.0;

  /// Large button height
  static const double buttonHeightLarge = 48.0;

  /// Standard input height
  static const double inputHeightMedium = 44.0;

  /// Sidebar collapsed width
  static const double sidebarCollapsedWidth = 56.0;

  /// Sidebar expanded width
  static const double sidebarExpandedWidth = 260.0;

  /// Right sidebar width
  static const double rightSidebarWidth = 300.0;

  /// Minimum panel width (resizable)
  static const double panelMinWidth = 200.0;

  /// Maximum panel width (resizable)
  static const double panelMaxWidth = 500.0;

  /// Card minimum width for grid items
  static const double cardMinWidth = 240.0;

  /// Card maximum width for centering
  static const double cardMaxWidth = 400.0;

  /// Content max-width for comfortable reading (like Notion)
  static const double contentMaxWidth = 740.0;

  /// Wide content max-width for dashboards
  static const double contentWideMaxWidth = 1200.0;

  // ============================================================================
  // OPACITY
  // ============================================================================

  static const double opacityDisabled = 0.38;
  static const double opacityInactive = 0.45;
  static const double opacitySubtle = 0.60;
  static const double opacityMedium = 0.80;
  static const double opacityVisible = 0.87;
  static const double opacityFull = 1.0;

  // ============================================================================
  // Z-INDEX
  // ============================================================================

  static const int zIndexBase = 0;
  static const int zIndexDropdown = 1000;
  static const int zIndexSticky = 1020;
  static const int zIndexFixed = 1030;
  static const int zIndexModalBackdrop = 1040;
  static const int zIndexModal = 1050;
  static const int zIndexPopover = 1060;
  static const int zIndexTooltip = 1070;

  // ============================================================================
  // BREAKPOINTS (Responsive design)
  // ============================================================================

  /// < 640px — phones
  static const double breakpointXS = 640.0;

  /// < 768px — tablets portrait
  static const double breakpointSM = 768.0;

  /// < 1024px — tablets landscape, small laptops
  static const double breakpointMD = 1024.0;

  /// < 1440px — desktops
  static const double breakpointLG = 1440.0;

  /// >= 1440px — large desktops
  static const double breakpointXL = 1440.0;

  // ============================================================================
  // DESKTOP-SPECIFIC
  // ============================================================================

  /// Hover animation duration for desktop interactions
  static const Duration durationHover = Duration(milliseconds: 150);

  /// Hover scale transform (subtle zoom)
  static const double hoverScale = 1.02;

  /// Focus ring width
  static const double focusRingWidth = 2.0;

  /// Minimum click target size for accessibility
  static const double minTouchTarget = 44.0;

  /// Command palette max height
  static const double commandPaletteMaxHeight = 480.0;

  /// Command palette max width
  static const double commandPaletteMaxWidth = 600.0;
}