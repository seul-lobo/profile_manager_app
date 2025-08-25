class Constants {
  //firestore collections
  static const String usersCollection = 'users';
  static const String documentsCollection = 'documents';

  //storage paths
  static const String profileImagesPath = 'profile_images';
  static const String documentsPath = 'documents';

  //file extensions
  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> documentExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
    'txt'
  ];

  //UI constants
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  //padding and margins
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;

  //border radius
  static const double borderRadius = 12.0;

  //max file size (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  //image constraints
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 85;
}
