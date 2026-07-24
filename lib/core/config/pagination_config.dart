/// Configuration for pagination feature
///
/// This allows enabling/disabling pagination based on document size
/// to balance performance and functionality.
class PaginationConfig {
  PaginationConfig._();

  /// Enable pagination for documents with more than this many blocks
  ///
  /// For smaller documents, we use the traditional full-load approach
  /// to maintain reordering functionality. For larger documents, we use
  /// pagination for better memory performance.
  static const int enablePaginationThreshold = 100;

  /// Page size for paginated loading
  static const int defaultPageSize = 30;

  /// Distance from bottom (in pixels) to trigger loading next page
  static const double loadMoreThreshold = 200.0;

  /// Whether to enable pagination globally (feature flag)
  ///
  /// Set to false to disable pagination entirely and use traditional approach.
  /// Useful for debugging or gradual rollout.
  static const bool isPaginationEnabled = true;

  /// Check if pagination should be used for a document with given block count
  static bool shouldUsePagination(int totalBlocks) {
    return isPaginationEnabled && totalBlocks > enablePaginationThreshold;
  }
}
