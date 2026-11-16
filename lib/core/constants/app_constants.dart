/// Global FINDORA application constants, branding and configuration defaults
class AppConstants {
  static const String appName = 'Findora';
  static const String appVersion = '2.0.0';
  static const String tagLine = 'Never Lose What Matters.';
  static const String developerName = 'Ankush';
  static const String developerCredit = 'Created & Developed by Ankush';
  static const String logoName = 'FINDORA ORBIT';

  // Storage directories
  static const String photosDirName = 'findora_photos';
  static const String thumbnailsDirName = 'findora_thumbnails';
  static const String backupDirName = 'findora_backups';

  // Thumbnail dimensions
  static const int thumbnailWidth = 480;
  static const int thumbnailQuality = 80;

  // Search thresholds
  static const double minRelevanceThreshold = 0.20;
  static const int maxSearchResults = 40;

  // Default rooms/locations
  static const List<String> defaultLocations = [
    'Study Desk',
    'Bedroom',
    'College Backpack',
    'Living Room',
    'Office Workstation',
    'Kitchen Counter',
    'Wardrobe / Closet',
    'Car Dashboard',
    'Entryway Table',
  ];

  // Frequently searched item categories
  static const List<String> popularCategories = [
    'Keys',
    'Charger',
    'Wallet',
    'College ID',
    'Headphones',
    'Glasses',
    'Backpack',
    'Smart Watch',
    'Passport / Documents',
  ];
}
