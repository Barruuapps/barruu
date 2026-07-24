import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the Barruu application.
///
/// This class contains configuration for Firebase backend
/// with Cloudflare R2 storage integration for files, optimized for:
/// - 100GB file storage capacity
/// - 2M users
/// - Minimal monthly operational costs (using R2 for large files)
///
/// Security: All sensitive credentials are loaded from environment variables.
/// Never hardcode secrets in source code.
class Environment {
  // Private constructor to prevent instantiation
  Environment._();

  // ============== Local-First Configuration ==============
  // Firebase has been removed. The app operates as a local-first
  // document editor across all platforms (Android, iOS, Web, Desktop).

  /// Firebase integration is permanently disabled (local-first mode)
  static const bool enableFirebase = false;

  /// Maximum file size in bytes (100MB per file)
  /// Cloudflare R2 optimization for cost-effective storage
  static const int maxFileSizeBytes = 100 * 1024 * 1024;

  /// API timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);

  // ============== Cloudflare R2 Storage Configuration ==============
  // Using Cloudflare R2 for large file storage (cost-effective)
  // Firebase Storage is used only for small files like images
  // All credentials are loaded from .env file for security
  
  /// Cloudflare R2 endpoint
  /// Loaded from R2_ENDPOINT environment variable
  static String get r2Endpoint => 
    dotenv.env['R2_ENDPOINT'] ?? '';
  
  /// Cloudflare R2 access key ID
  /// Loaded from R2_ACCESS_KEY_ID environment variable
  static String get r2AccessKeyId => 
    dotenv.env['R2_ACCESS_KEY_ID'] ?? '';
  
  /// Cloudflare R2 secret access key
  /// Loaded from R2_SECRET_ACCESS_KEY environment variable
  static String get r2SecretAccessKey => 
    dotenv.env['R2_SECRET_ACCESS_KEY'] ?? '';
  
  /// Cloudflare R2 bucket name
  /// Loaded from R2_BUCKET_NAME environment variable, defaults to 'barrugram-production'
  static String get r2BucketName => 
    dotenv.env['R2_BUCKET_NAME'] ?? 'barrugram-production';
  
  /// Cloudflare R2 public URL (CDN URL for accessing R2 bucket contents)
  /// Loaded from R2_PUBLIC_URL environment variable
  /// This should be your custom domain or R2 public URL
  static String get r2PublicUrl => 
    dotenv.env['R2_PUBLIC_URL'] ?? '';

  /// Check if R2 storage is properly configured
  static bool get isR2Configured => 
    r2Endpoint.isNotEmpty && 
    r2AccessKeyId.isNotEmpty && 
    r2SecretAccessKey.isNotEmpty &&
    r2BucketName.isNotEmpty &&
    r2PublicUrl.isNotEmpty;

  // ============== Legacy Appwrite Configuration (Deprecated) ==============
  // Kept for backward compatibility during migration
  @Deprecated('Use enableFirebase instead')
  static const bool enableAppwrite = false;

  // ============== Stripe Configuration ==============
  // Used for subscription payment processing.
  // See STRIPE_INTEGRATION_GUIDE.md for the full setup walkthrough.
  //
  // STRIPE_PUBLISHABLE_KEY  – safe to expose in the client app (pk_live_... / pk_test_...)
  // STRIPE_SECRET_KEY       – NEVER expose in client code; store as a Cloudflare Worker secret
  // STRIPE_WEBHOOK_SECRET   – used to verify webhook signatures; store as a Cloudflare Worker secret

  /// Stripe publishable key (safe to include in the Flutter app).
  /// Set STRIPE_PUBLISHABLE_KEY in your .env file.
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  /// Base URL of your deployed Cloudflare Worker (no trailing slash).
  /// Set CLOUDFLARE_WORKER_URL in your .env file.
  /// Example: https://barrugram-payments.your-subdomain.workers.dev
  static String get cloudflareWorkerUrl =>
      dotenv.env['CLOUDFLARE_WORKER_URL'] ?? '';

  /// Whether Stripe is configured (publishable key is present).
  static bool get isStripeConfigured => stripePublishableKey.isNotEmpty;
}
