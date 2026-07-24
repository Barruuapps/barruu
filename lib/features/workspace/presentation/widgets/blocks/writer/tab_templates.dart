/// Tab template constants for consistent styling across the app
/// 
/// This file contains template definitions for tab blocks, providing
/// various visual styles for displaying tabbed content.

/// Available tab templates
const String kTabTemplateStandard = 'standard';
const String kTabTemplatePills = 'pills';
const String kTabTemplateUnderline = 'underline';
const String kTabTemplateBoxed = 'boxed';
const String kTabTemplateMinimal = 'minimal';
const String kTabTemplateSidebar = 'sidebar';
const String kTabTemplateVertical = 'vertical';
const String kTabTemplateSegmented = 'segmented';
const String kTabTemplateCards = 'cards';

/// Default tab template
const String kDefaultTabTemplate = kTabTemplateStandard;

/// Tab template display names
const Map<String, String> kTabTemplateNames = {
  kTabTemplateStandard: 'Standard',
  kTabTemplatePills: 'Pills',
  kTabTemplateUnderline: 'Underline',
  kTabTemplateBoxed: 'Boxed',
  kTabTemplateMinimal: 'Minimal',
  kTabTemplateSidebar: 'Sidebar',
  kTabTemplateVertical: 'Vertical',
  kTabTemplateSegmented: 'Segmented',
  kTabTemplateCards: 'Cards',
};

/// Tab template descriptions
const Map<String, String> kTabTemplateDescriptions = {
  kTabTemplateStandard: 'Classic tab bar with content below',
  kTabTemplatePills: 'Rounded pill-shaped tabs',
  kTabTemplateUnderline: 'Underlined tabs with minimal design',
  kTabTemplateBoxed: 'Boxed tabs with background',
  kTabTemplateMinimal: 'Clean minimal tab design',
  kTabTemplateSidebar: 'Sidebar navigation style',
  kTabTemplateVertical: 'Vertically stacked tabs',
  kTabTemplateSegmented: 'iOS-style segmented control',
  kTabTemplateCards: 'Card-based tab selection',
};
