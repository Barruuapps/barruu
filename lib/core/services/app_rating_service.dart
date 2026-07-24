import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for AppRatingService (local-first stub)
final appRatingServiceProvider = Provider<AppRatingService>((ref) {
  return AppRatingService();
});

/// Local-first rating stub — disabled in local-only mode.
class AppRatingService {
  AppRatingService();

  Future<double?> rateApp({
    required String appId,
    required String userId,
    required double rating,
  }) async {
    logger.w('Ratings not available in local-first mode');
    return null;
  }

  Future<double?> getUserRating({
    required String appId,
    required String userId,
  }) async {
    return null;
  }
}