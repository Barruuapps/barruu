import 'package:barruu/features/workspace/constants/meta_file.dart';

class DocumentPage {
  final String id;
  final String title;
  final int order;
  final DateTime createdAt;
  final String? parentPageId; // null for drawer pages, set for nested pages
  final String? icon; // optional icon name, null means no icon
  final bool
  isTabPage; // true for tab pages (shown in AppBar tabs), false for drawer pages
  final String?
  tabDisplayName; // optional custom display name for tab bar (independent of page title)

  DocumentPage({
    required this.id,
    required this.title,
    required this.order,
    required this.createdAt,
    this.parentPageId,
    this.icon,
    this.isTabPage = false,
    this.tabDisplayName,
  });

  DocumentPage copyWith({
    String? id,
    String? title,
    int? order,
    DateTime? createdAt,
    String? parentPageId,
    String? icon,
    bool clearIcon = false,
    bool? isTabPage,
    String? tabDisplayName,
    bool clearTabDisplayName = false,
  }) {
    return DocumentPage(
      id: id ?? this.id,
      title: title ?? this.title,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      parentPageId: parentPageId ?? this.parentPageId,
      icon: clearIcon ? null : (icon ?? this.icon),
      isTabPage: isTabPage ?? this.isTabPage,
      tabDisplayName: clearTabDisplayName
          ? null
          : (tabDisplayName ?? this.tabDisplayName),
    );
  }

  /// Returns true if this is a drawer page (root page, not tab page)
  bool get isDrawerPage => parentPageId == null && !isTabPage;

  /// Returns true if this is a nested page (child page)
  bool get isNestedPage => parentPageId != null;

  /// Returns the display title, using 'Untitled Screen' if title is empty
  String get displayTitle =>
      title.trim().isEmpty ? PageConstants.untitledPageTitle : title;

  /// Returns the tab display name for use in tab bar
  /// Falls back to displayTitle if no custom tab name is set
  String get tabTitle {
    if (tabDisplayName != null && tabDisplayName!.trim().isNotEmpty) {
      return tabDisplayName!;
    }
    return displayTitle;
  }

  /// Returns true if the page has a custom icon
  bool get hasIcon => icon != null && icon!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      PageConstants.pageIdKey: id,
      PageConstants.pageTitleKey: title,
      PageConstants.pageOrderKey: order,
      PageConstants.pageCreatedAtKey: createdAt.toIso8601String(),
      PageConstants.pageParentIdKey: parentPageId,
      PageConstants.pageIconKey: icon,
      PageConstants.pageIsTabPageKey: isTabPage,
      PageConstants.pageTabDisplayNameKey: tabDisplayName,
    };
  }

  factory DocumentPage.fromJson(Map<String, dynamic> json) {
    return DocumentPage(
      id: json[PageConstants.pageIdKey] as String,
      title: json[PageConstants.pageTitleKey] as String,
      order: json[PageConstants.pageOrderKey] as int,
      createdAt: DateTime.parse(json[PageConstants.pageCreatedAtKey] as String),
      parentPageId: json[PageConstants.pageParentIdKey] as String?,
      icon: json[PageConstants.pageIconKey] as String?,
      isTabPage: json[PageConstants.pageIsTabPageKey] as bool? ?? false,
      tabDisplayName: json[PageConstants.pageTabDisplayNameKey] as String?,
    );
  }

  @override
  String toString() => 'DocumentPage(id: $id, title: $title, order: $order)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentPage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
