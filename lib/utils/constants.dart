class Constants {
  //firestore collections
  static const String usersCollection = 'users';

  //storage paths
  static const String profileImagesPath = 'profile_images';
  static const String documentsPath = 'documents';
  static const String documentsCollection = 'documents';

  //file extensions
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> documentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  //UI constants
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  //padding and margins
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;

  //border radius
  static const double borderRadius = 12.0;

  //max file size (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
}
