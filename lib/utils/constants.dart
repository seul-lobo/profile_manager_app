class Constants {
  // Firestore collections
  static const String usersCollection = 'users';

  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String documentsPath = 'documents';

  // File extensions
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> documentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  // UI constants
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  // Padding and margins
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;

  // Border radius
  static const double borderRadius = 12.0;

  // Max file size (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
}
