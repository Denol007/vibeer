import 'package:flutter/material.dart';

/// Event categories for organizing and filtering events
enum EventCategory {
  /// Sports and fitness activities (🏃)
  sports,

  /// Food and dining experiences (🍕)
  food,

  /// Entertainment and fun (🎉)
  entertainment,

  /// Educational activities and workshops (📚)
  education,

  /// Travel and exploration (✈️)
  travel,

  /// Gaming and esports (🎮)
  games,

  /// Music concerts and performances (🎵)
  music,

  /// Creative and artistic activities (🎨)
  creative,

  /// Other activities not in main categories
  other;

  /// Get display name in Russian
  String get displayName {
    switch (this) {
      case EventCategory.sports:
        return 'Спорт';
      case EventCategory.food:
        return 'Еда';
      case EventCategory.entertainment:
        return 'Развлечения';
      case EventCategory.education:
        return 'Обучение';
      case EventCategory.travel:
        return 'Путешествия';
      case EventCategory.games:
        return 'Игры';
      case EventCategory.music:
        return 'Музыка';
      case EventCategory.creative:
        return 'Творчество';
      case EventCategory.other:
        return 'Другое';
    }
  }

  /// Get emoji icon for category
  String get emoji {
    switch (this) {
      case EventCategory.sports:
        return '🏃';
      case EventCategory.food:
        return '🍕';
      case EventCategory.entertainment:
        return '🎉';
      case EventCategory.education:
        return '📚';
      case EventCategory.travel:
        return '✈️';
      case EventCategory.games:
        return '🎮';
      case EventCategory.music:
        return '🎵';
      case EventCategory.creative:
        return '🎨';
      case EventCategory.other:
        return '❓';
    }
  }

  /// Get Flutter icon for category
  IconData get icon {
    switch (this) {
      case EventCategory.sports:
        return Icons.sports_soccer;
      case EventCategory.food:
        return Icons.restaurant;
      case EventCategory.entertainment:
        return Icons.celebration;
      case EventCategory.education:
        return Icons.school;
      case EventCategory.travel:
        return Icons.flight;
      case EventCategory.games:
        return Icons.sports_esports;
      case EventCategory.music:
        return Icons.music_note;
      case EventCategory.creative:
        return Icons.palette;
      case EventCategory.other:
        return Icons.more_horiz;
    }
  }

  /// Get primary color for category
  Color get color {
    switch (this) {
      case EventCategory.sports:
        return const Color(0xFF2196F3); // Blue
      case EventCategory.food:
        return const Color(0xFFFF9800); // Orange
      case EventCategory.entertainment:
        return const Color(0xFFE91E63); // Pink
      case EventCategory.education:
        return const Color(0xFF4CAF50); // Green
      case EventCategory.travel:
        return const Color(0xFF9C27B0); // Purple
      case EventCategory.games:
        return const Color(0xFFF44336); // Red
      case EventCategory.music:
        return const Color(0xFF00BCD4); // Cyan
      case EventCategory.creative:
        return const Color(0xFFFF5722); // Deep Orange
      case EventCategory.other:
        return const Color(0xFF757575); // Grey
    }
  }

  /// Get light background color for category
  Color get lightColor {
    return color.withValues(alpha: 0.1);
  }

  /// Parse from string value (for Firestore deserialization)
  static EventCategory fromString(String value) {
    return EventCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => EventCategory.other,
    );
  }

  /// Convert to string for Firestore serialization
  String toFirestore() => name;

  /// Get all categories except 'other' for selection UI
  static List<EventCategory> get mainCategories {
    return EventCategory.values.where((c) => c != EventCategory.other).toList();
  }
}
