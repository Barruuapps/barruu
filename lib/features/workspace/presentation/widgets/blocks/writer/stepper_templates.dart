/// Stepper template constants for consistent styling across the app
/// 
/// This file contains template definitions for stepper blocks, providing
/// various visual styles for displaying step-by-step content.
library;

/// Available stepper templates
const String kStepperTemplateStandard = 'standard';
const String kStepperTemplateNumbered = 'numbered';
const String kStepperTemplateProgress = 'progress';
const String kStepperTemplateTimeline = 'timeline';
const String kStepperTemplateMinimal = 'minimal';
const String kStepperTemplateCards = 'cards';
const String kStepperTemplateChecklist = 'checklist';
const String kStepperTemplateDots = 'dots';

/// Default stepper template
const String kDefaultStepperTemplate = kStepperTemplateStandard;

/// Stepper template display names
const Map<String, String> kStepperTemplateNames = {
  kStepperTemplateStandard: 'Standard',
  kStepperTemplateNumbered: 'Numbered',
  kStepperTemplateProgress: 'Progress',
  kStepperTemplateTimeline: 'Timeline',
  kStepperTemplateMinimal: 'Minimal',
  kStepperTemplateCards: 'Cards',
  kStepperTemplateChecklist: 'Checklist',
  kStepperTemplateDots: 'Dots',
};

/// Stepper template descriptions
const Map<String, String> kStepperTemplateDescriptions = {
  kStepperTemplateStandard: 'Classic stepper with circles and connecting lines',
  kStepperTemplateNumbered: 'Numbered steps with bold numbers',
  kStepperTemplateProgress: 'Progress bar style with percentages',
  kStepperTemplateTimeline: 'Timeline view with dates/timestamps',
  kStepperTemplateMinimal: 'Clean minimal design with simple bullets',
  kStepperTemplateCards: 'Card-based steps with shadows',
  kStepperTemplateChecklist: 'Checklist style with checkboxes',
  kStepperTemplateDots: 'Dot indicators for progress',
};
