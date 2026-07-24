class MetaFile {
  static const String fileName = 'meta.json';
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String tagsKey = 'tags';
  static const String coverKey = 'cover';
  static const String coverOriginalNameKey = 'coverOriginalName';
  static const String createdAtKey = 'createdAt';
  static const String updatedAtKey = 'updatedAt';
  static const String authorKey = 'author';
  static const String currentPageIdKey = 'currentPageId';
  static const String permissionLevelKey = 'permissionLevel';
  static const String allowedUsersKey = 'allowedUsers';
  static const String minibookThemeKey =
      'minibookTheme'; // Content creator's theme choice

  /// Format version written to every exported .bipy so both apps can detect
  /// and handle future breaking changes without silently corrupting data.
  /// Version 2 = multi-page SQLite format with pages.json.
  static const String formatVersionKey = 'formatVersion';
  static const int currentFormatVersion = 2;

  // Social metadata fields for publishing (Phase 2)
  static const String authorIdKey = 'authorId'; // Firebase Auth UID
  static const String visibilityKey =
      'visibility'; // 'private', 'public', 'followers'
  static const String publishedKey = 'published'; // true/false
  static const String publishedAtKey = 'publishedAt'; // ISO 8601 string or null

  // Engagement counters (denormalized for performance)
  static const String viewsKey = 'views';
  static const String likesKey = 'likes';
  static const String commentsKey = 'comments';
  static const String sharesKey = 'shares';

  // Default values
  static const String defaultVisibility = 'private';
  static const bool defaultPublished = false;
  static const int defaultViews = 0;
  static const int defaultLikes = 0;
  static const int defaultComments = 0;
  static const int defaultShares = 0;
}

class BlockConstants {
  static const String fileName = 'book.db';
  static const String tableName = 'block';
  static const String idKey = 'id';
  static const String contentKey = 'content';
  static const String blockTypeKey = 'block_type';
  static const String styleKey = 'style';
  static const String positionKey = 'position';

  // Database version for schema migrations
  static const int databaseVersion = 2;

  /// Returns the SQL statement to create the block table schema
  static String get createTableSql =>
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $idKey INTEGER PRIMARY KEY AUTOINCREMENT,
      $contentKey TEXT DEFAULT '{}',
      $blockTypeKey TEXT DEFAULT 'paragraph',
      $styleKey TEXT DEFAULT '{}',
      $positionKey INTEGER DEFAULT 0
    )
  ''';

  /// Returns the SQL statement to create an index on the position column
  /// This optimizes queries that use ORDER BY position
  static String get createPositionIndexSql =>
      '''
    CREATE INDEX IF NOT EXISTS idx_${tableName}_$positionKey 
    ON $tableName($positionKey ASC)
  ''';

  /// Returns the SQL statement to create a composite index for common query patterns
  /// This optimizes queries that filter by block type and order by position
  static String get createTypePositionIndexSql =>
      '''
    CREATE INDEX IF NOT EXISTS idx_${tableName}_${blockTypeKey}_$positionKey 
    ON $tableName($blockTypeKey, $positionKey ASC)
  ''';

  /// Returns all index creation SQL statements
  static List<String> get allIndexesSql => [
    createPositionIndexSql,
    createTypePositionIndexSql,
  ];
}

class PageConstants {
  static const String pagesFileName = 'pages.json';
  static const String pagesKey = 'pages';
  static const String pageIdKey = 'id';
  static const String pageTitleKey = 'title';
  static const String pageOrderKey = 'order';
  static const String pageCreatedAtKey = 'createdAt';
  static const String pageParentIdKey = 'parentPageId';
  static const String pageIconKey = 'icon';
  static const String pageIsTabPageKey = 'isTabPage';
  static const String pageTabDisplayNameKey = 'tabDisplayName';
  static String getPageFileName(String pageId) => 'page_$pageId.db';
  static const String defaultPageId = 'page_1';
  static const String defaultPageTitle = 'Page 1';
  static const String untitledPageTitle = 'Untitled Screen';
}

class AppFile {
  static const String extension = 'bipy';
  static const String shareMessage =
      'Check out this document exported from Barruu!';
  static const String libraryDirName = 'library';
  static const String imageFolder = 'media/images';
  static const String videoFolder = 'media/videos';
  static const String audioFolder = 'media/audios';
  static const String coverFileName = 'cover.jpg';
}
