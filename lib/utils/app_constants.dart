class AppConstants {
  // App Info
  static const String appName = 'JuvaPay';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Security
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int sessionTimeoutMinutes = 30;
  static const int tokenExpiryHours = 24;

  // Deep Links
  static const String deepLinkScheme = 'juvapay';
  static const String resetPasswordPath = 'reset-password';
  static const String verifyEmailPath = 'verify-email';

  // API
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
}
