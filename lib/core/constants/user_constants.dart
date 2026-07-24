/// Constants related to user profiles, account types, professions, interests, and categories
library;

/// Account types available in the platform
class AccountType {
  /// Regular user - can read content, follow others, like and comment
  static const String regular = 'regular';
  
  /// Professional account - experts with knowledge who can post content
  /// Must select a profession
  static const String professional = 'professional';
  
  /// Organization account - companies, news outlets, institutions
  static const String organization = 'organization';
  
  /// List of all account types
  static const List<String> all = [regular, professional, organization];
  
  /// Display names for account types
  static const Map<String, String> displayNames = {
    regular: 'Regular User',
    professional: 'Professional',
    organization: 'Organization',
  };
  
  /// Descriptions for account types
  static const Map<String, String> descriptions = {
    regular: 'Read and engage with content based on your interests',
    professional: 'Share your expertise and knowledge with others',
    organization: 'Represent your company, news outlet, or institution',
  };
}

/// Common professions for professional accounts
class Professions {
  static const String doctor = 'Doctor';
  static const String scientist = 'Scientist';
  static const String engineer = 'Engineer';
  static const String researcher = 'Researcher';
  static const String journalist = 'Journalist';
  static const String teacher = 'Teacher';
  static const String professor = 'Professor';
  static const String lawyer = 'Lawyer';
  static const String accountant = 'Accountant';
  static const String architect = 'Architect';
  static const String designer = 'Designer';
  static const String developer = 'Developer';
  static const String writer = 'Writer';
  static const String artist = 'Artist';
  static const String consultant = 'Consultant';
  static const String entrepreneur = 'Entrepreneur';
  static const String other = 'Other';
  
  /// List of all professions
  static const List<String> all = [
    doctor,
    scientist,
    engineer,
    researcher,
    journalist,
    teacher,
    professor,
    lawyer,
    accountant,
    architect,
    designer,
    developer,
    writer,
    artist,
    consultant,
    entrepreneur,
    other,
  ];
}

/// Common interests for content personalization
class Interests {
  static const String science = 'Science';
  static const String technology = 'Technology';
  static const String medicine = 'Medicine';
  static const String engineering = 'Engineering';
  static const String business = 'Business';
  static const String finance = 'Finance';
  static const String law = 'Law';
  static const String education = 'Education';
  static const String art = 'Art';
  static const String design = 'Design';
  static const String music = 'Music';
  static const String sports = 'Sports';
  static const String health = 'Health';
  static const String fitness = 'Fitness';
  static const String food = 'Food';
  static const String travel = 'Travel';
  static const String photography = 'Photography';
  static const String writing = 'Writing';
  static const String gaming = 'Gaming';
  static const String news = 'News';
  static const String politics = 'Politics';
  static const String environment = 'Environment';
  static const String psychology = 'Psychology';
  static const String philosophy = 'Philosophy';
  static const String history = 'History';
  static const String literature = 'Literature';
  static const String mathematics = 'Mathematics';
  static const String physics = 'Physics';
  static const String chemistry = 'Chemistry';
  static const String biology = 'Biology';
  
  /// List of all interests — delegates to [AppCategories.all] for consistency
  /// across the app.
  static List<String> get all => AppCategories.all;
}

/// Canonical category list shared across the entire application.
///
/// This single source of truth is used in:
/// - User-profile interests selector (multi-select)
/// - Feed topic filter row
/// - App-store category filter pills
/// - Publish dialog (app category dropdown & post tag suggestions)
class AppCategories {
  static const String science = 'Science';
  static const String technology = 'Technology';
  static const String engineering = 'Engineering';
  static const String mathematics = 'Mathematics';
  static const String medicineHealth = 'Medicine & Health';
  static const String education = 'Education';
  static const String businessFinance = 'Business & Finance';
  static const String artsCulture = 'Arts & Culture';
  static const String literatureWriting = 'Literature & Writing';
  static const String history = 'History';
  static const String philosophy = 'Philosophy';
  static const String religionSpirituality = 'Religion & Spirituality';
  static const String politicsSociety = 'Politics & Society';
  static const String psychology = 'Psychology';
  static const String environmentNature = 'Environment & Nature';
  static const String sportsFitness = 'Sports & Fitness';
  static const String foodLifestyle = 'Food & Lifestyle';
  static const String travel = 'Travel';
  static const String entertainment = 'Entertainment';
  static const String selfImprovement = 'Self-Improvement';
  static const String languageLearning = 'Language Learning';
  static const String lawJustice = 'Law & Justice';

  /// Full ordered list — used wherever a category/interest picker is needed.
  static const List<String> all = [
    science,
    technology,
    engineering,
    mathematics,
    medicineHealth,
    education,
    businessFinance,
    artsCulture,
    literatureWriting,
    history,
    philosophy,
    religionSpirituality,
    politicsSociety,
    psychology,
    environmentNature,
    sportsFitness,
    foodLifestyle,
    travel,
    entertainment,
    selfImprovement,
    languageLearning,
    lawJustice,
  ];

  /// Convenience list with 'All' prepended — used in filter rows.
  static const List<String> allWithAll = ['All', ...all];
}
