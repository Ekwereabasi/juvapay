// utils/task_helper.dart
import 'package:flutter/material.dart';
import 'platform_helper.dart';

class TaskHelper {
  // Task categories as const
  static const List<String> taskCategories = const [
    'advert',
    'engagement',
    'social',
    'video',
    'music',
    'app',
    'review',
    'comment',
    'follow',
    'like',
    'share',
  ];

  // Task type platforms - defined as final with explicit types
  static final Map<String, List<String>> taskTypePlatforms = {
    'advert': const ['facebook', 'instagram', 'twitter', 'youtube'],
    'engagement': const ['facebook', 'instagram', 'twitter'],
    'follow': const ['facebook', 'instagram', 'twitter'],
    'like': const ['facebook', 'instagram', 'twitter'],
    'comment': const ['facebook', 'instagram', 'twitter'],
    'share': const ['facebook', 'instagram', 'twitter'],
    'app_download': const ['playstore', 'appstore'],
    'app_review': const ['playstore', 'appstore'],
    'music_stream': const ['spotify', 'apple_music', 'soundcloud'],
    'video_view': const ['youtube', 'twitch'],
  };

  // Get task category icon - all returns are const IconData
  static IconData getTaskCategoryIcon(String category) {
    final categoryLower = category.trim().toLowerCase();

    switch (categoryLower) {
      case 'advert':
      case 'advertising':
      case 'promotion':
        return Icons.campaign;
      case 'engagement':
      case 'social':
      case 'social_media':
        return Icons.thumb_up;
      case 'follow':
      case 'follower':
        return Icons.person_add;
      case 'like':
        return Icons.favorite;
      case 'comment':
      case 'feedback':
        return Icons.comment;
      case 'share':
      case 'repost':
        return Icons.share;
      case 'video':
      case 'streaming':
        return Icons.video_library;
      case 'music':
      case 'audio':
        return Icons.music_note;
      case 'app':
      case 'download':
        return Icons.download;
      case 'review':
      case 'rating':
        return Icons.star;
      case 'message':
      case 'messaging':
        return Icons.message;
      default:
        return Icons.task;
    }
  }

  // Get task category color
  static Color getTaskCategoryColor(String category) {
    final categoryLower = category.trim().toLowerCase();

    switch (categoryLower) {
      case 'advert':
      case 'advertising':
        return Colors.blue;
      case 'engagement':
      case 'social':
        return Colors.green;
      case 'follow':
        return Colors.pink;
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.teal;
      case 'share':
        return Colors.orange;
      case 'video':
      case 'streaming':
        return Colors.red;
      case 'music':
      case 'audio':
        return Colors.purple;
      case 'app':
      case 'download':
        return Colors.amber;
      case 'review':
      case 'rating':
        return Colors.yellow.shade700;
      case 'message':
      case 'messaging':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  // Get task category display name
  static String getTaskCategoryDisplayName(String category) {
    final categoryLower = category.trim().toLowerCase();

    switch (categoryLower) {
      case 'advert':
        return 'Advert Task';
      case 'engagement':
        return 'Engagement Task';
      case 'follow':
        return 'Follow Task';
      case 'like':
        return 'Like Task';
      case 'comment':
        return 'Comment Task';
      case 'share':
        return 'Share Task';
      case 'video':
        return 'Video Task';
      case 'music':
        return 'Music Task';
      case 'app':
        return 'App Promotion';
      case 'review':
        return 'Review Task';
      default:
        if (category.isNotEmpty) {
          return '${category[0].toUpperCase()}${category.substring(1)} Task';
        }
        return 'Task';
    }
  }

  // Get supported platforms for task category
  static List<String> getSupportedPlatforms(String taskCategory) {
    final categoryLower = taskCategory.trim().toLowerCase();

    if (taskTypePlatforms.containsKey(categoryLower)) {
      return List.from(taskTypePlatforms[categoryLower]!);
    }

    // Default to all platforms
    return PlatformHelper.getAllPlatforms();
  }

  // Validate task for platform
  static bool validateTaskForPlatform(String taskType, String platform) {
    final platforms = getSupportedPlatforms(taskType);
    return platforms.contains(platform);
  }

  // Get task requirements by type
  static Map<String, dynamic> getTaskRequirements(String taskType) {
    final typeLower = taskType.trim().toLowerCase();

    final requirements = {
      'media_required': false,
      'link_required': false,
      'text_required': false,
      'quantity_min': 1,
      'quantity_max': 1000,
      'duration_min': 1, // hours
      'duration_max': 168, // hours (7 days)
    };

    switch (typeLower) {
      case 'advert':
        return {
          ...requirements,
          'media_required': true,
          'text_required': true,
          'duration_min': 24,
          'duration_max': 168,
        };
      case 'engagement':
      case 'follow':
      case 'like':
      case 'comment':
      case 'share':
        return {
          ...requirements,
          'link_required': true,
          'quantity_min': 10,
          'quantity_max': 10000,
        };
      case 'app_download':
      case 'app_review':
        return {
          ...requirements,
          'link_required': true,
          'quantity_min': 50,
          'quantity_max': 5000,
        };
      case 'music_stream':
      case 'video_view':
        return {
          ...requirements,
          'link_required': true,
          'duration_min': 1,
          'duration_max': 24,
          'quantity_min': 100,
          'quantity_max': 10000,
        };
      default:
        return requirements;
    }
  }

  // Get task pricing suggestions
  static Map<String, dynamic> getTaskPricingSuggestions(String taskType) {
    final typeLower = taskType.trim().toLowerCase();

    switch (typeLower) {
      case 'advert':
        return {
          'min_price': 100.0,
          'max_price': 10000.0,
          'suggested_price': 500.0,
          'price_unit': 'per post',
          'bulk_discount': true,
        };
      case 'follow':
        return {
          'min_price': 5.0,
          'max_price': 50.0,
          'suggested_price': 10.0,
          'price_unit': 'per follower',
          'bulk_discount': true,
        };
      case 'like':
        return {
          'min_price': 3.0,
          'max_price': 30.0,
          'suggested_price': 8.0,
          'price_unit': 'per like',
          'bulk_discount': true,
        };
      case 'comment':
        return {
          'min_price': 10.0,
          'max_price': 100.0,
          'suggested_price': 30.0,
          'price_unit': 'per comment',
          'bulk_discount': true,
        };
      case 'share':
        return {
          'min_price': 20.0,
          'max_price': 200.0,
          'suggested_price': 50.0,
          'price_unit': 'per share',
          'bulk_discount': true,
        };
      case 'app_download':
        return {
          'min_price': 50.0,
          'max_price': 500.0,
          'suggested_price': 150.0,
          'price_unit': 'per download',
          'bulk_discount': true,
        };
      case 'app_review':
        return {
          'min_price': 100.0,
          'max_price': 1000.0,
          'suggested_price': 300.0,
          'price_unit': 'per review',
          'bulk_discount': true,
        };
      default:
        return {
          'min_price': 1.0,
          'max_price': 1000.0,
          'suggested_price': 100.0,
          'price_unit': 'per action',
          'bulk_discount': false,
        };
    }
  }

  // Get task description template
  static String getTaskDescriptionTemplate(String taskType, String platform) {
    final platformName = PlatformHelper.getPlatformDisplayName(platform);

    switch (taskType.toLowerCase()) {
      case 'advert':
        return 'Post my advert on $platformName. The advert will be displayed to your followers and should remain visible for the specified duration.';
      case 'follow':
        return 'Follow my account/page on $platformName. Must be a genuine follow from an active account.';
      case 'like':
        return 'Like my post on $platformName. Must be a genuine like from an active account.';
      case 'comment':
        return 'Leave a meaningful comment on my post on $platformName. Comments should be relevant and not spammy.';
      case 'share':
        return 'Share my content on $platformName. Share should be visible to your followers.';
      case 'app_download':
        return 'Download and install my app from the $platformName. Must use the app for at least 5 minutes.';
      case 'app_review':
        return 'Download my app from $platformName and leave a positive review. Review should be detailed and honest.';
      default:
        return 'Complete the specified task on $platformName as per the requirements.';
    }
  }

  // Get task completion time estimate
  static String getTaskCompletionTime(String taskType, int quantity) {
    switch (taskType.toLowerCase()) {
      case 'advert':
        return '24-48 hours';
      case 'follow':
      case 'like':
      case 'comment':
      case 'share':
        if (quantity <= 100) return '12-24 hours';
        if (quantity <= 1000) return '24-48 hours';
        return '48-72 hours';
      case 'app_download':
      case 'app_review':
        return '24-72 hours';
      default:
        return '24-48 hours';
    }
  }

  // Get all task types
  static List<String> getAllTaskTypes() {
    return taskTypePlatforms.keys.toList();
  }

  // Get task type display name
  static String getTaskTypeDisplayName(String taskType) {
    final typeLower = taskType.trim().toLowerCase();

    switch (typeLower) {
      case 'app_download':
        return 'App Download';
      case 'app_review':
        return 'App Review';
      case 'music_stream':
        return 'Music Stream';
      case 'video_view':
        return 'Video View';
      default:
        return getTaskCategoryDisplayName(taskType);
    }
  }

  // Check if task type is valid
  static bool isValidTaskType(String taskType) {
    return taskTypePlatforms.containsKey(taskType.trim().toLowerCase()) ||
        taskCategories.contains(taskType.trim().toLowerCase());
  }

  // Get task type by category
  static List<String> getTaskTypesByCategory(String category) {
    final categoryLower = category.trim().toLowerCase();
    final List<String> taskTypes = [];

    // Check for direct matches
    if (taskTypePlatforms.containsKey(categoryLower)) {
      taskTypes.add(categoryLower);
    }

    // Add related task types
    switch (categoryLower) {
      case 'advert':
        taskTypes.addAll(['advert', 'promotion']);
        break;
      case 'engagement':
        taskTypes.addAll(['follow', 'like', 'comment', 'share']);
        break;
      case 'social':
        taskTypes.addAll(['follow', 'like', 'comment', 'share']);
        break;
      case 'video':
        taskTypes.addAll(['video_view', 'streaming']);
        break;
      case 'music':
        taskTypes.addAll(['music_stream']);
        break;
      case 'app':
        taskTypes.addAll(['app_download', 'app_review']);
        break;
    }

    return taskTypes.toSet().toList(); // Remove duplicates
  }
}
