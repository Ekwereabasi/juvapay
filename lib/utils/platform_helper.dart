// utils/platform_helper.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlatformHelper {
  // Singleton instance
  static final PlatformHelper _instance = PlatformHelper._internal();
  factory PlatformHelper() => _instance;
  PlatformHelper._internal();

  // Platform categories
  static const List<String> socialMediaPlatforms = [
    'whatsapp',
    'facebook',
    'instagram',
    'x',
    'twitter',
    'tiktok',
    'telegram',
    'linkedin',
    'snapchat',
    'pinterest',
    'reddit',
  ];

  static const List<String> videoStreamingPlatforms = [
    'youtube',
    'twitch',
    'netflix',
    'spotify',
    'soundcloud',
    'audiomack',
    'apple_music',
    'deezer',
  ];

  static const List<String> appStorePlatforms = [
    'playstore',
    'google_play',
    'appstore',
    'apple_store',
    'microsoft_store',
  ];

  static const List<String> messagingPlatforms = [
    'whatsapp',
    'telegram',
    'discord',
    'signal',
    'wechat',
    'viber',
  ];

  // Get platform icon
  static IconData getPlatformIcon(String platform) {
    final platformLower = platform.trim().toLowerCase();

    // Social Media
    if (platformLower.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
    if (platformLower.contains('facebook')) return FontAwesomeIcons.facebookF;
    if (platformLower.contains('instagram')) return FontAwesomeIcons.instagram;
    if (platformLower.contains('tiktok')) return FontAwesomeIcons.tiktok;
    if (platformLower.contains('telegram')) return FontAwesomeIcons.telegram;
    if (platformLower.contains('linkedin')) return FontAwesomeIcons.linkedinIn;
    if (platformLower.contains('snapchat')) return FontAwesomeIcons.snapchat;
    if (platformLower.contains('pinterest')) return FontAwesomeIcons.pinterest;
    if (platformLower.contains('reddit')) return FontAwesomeIcons.reddit;
    if (platformLower.contains('discord')) return FontAwesomeIcons.discord;
    if (platformLower.contains('medium')) return FontAwesomeIcons.medium;

    // X (formerly Twitter) - handle both old and new names
    if (platformLower == 'x' ||
        platformLower.contains('twitter') ||
        platformLower == 'x-twitter') {
      return FontAwesomeIcons.xTwitter;
    }

    // Video & Streaming
    if (platformLower.contains('youtube')) return FontAwesomeIcons.youtube;
    if (platformLower.contains('twitch')) return FontAwesomeIcons.twitch;
    if (platformLower.contains('netflix')) return FontAwesomeIcons.tv;
    if (platformLower.contains('spotify')) return FontAwesomeIcons.spotify;
    if (platformLower.contains('soundcloud'))
      return FontAwesomeIcons.soundcloud;
    if (platformLower.contains('audiomack')) return FontAwesomeIcons.music;

    // Apple platforms
    if (platformLower.contains('apple_music') ||
        platformLower.contains('apple music') ||
        platformLower.contains('apple-music')) {
      return FontAwesomeIcons.apple;
    }

    // App Stores
    if (platformLower.contains('playstore') ||
        platformLower.contains('google_play') ||
        platformLower.contains('play store')) {
      return FontAwesomeIcons.googlePlay;
    }
    if (platformLower.contains('appstore') ||
        platformLower.contains('apple_store') ||
        platformLower.contains('app store')) {
      return FontAwesomeIcons.appStoreIos;
    }
    if (platformLower.contains('microsoft') ||
        platformLower.contains('windows_store')) {
      return FontAwesomeIcons.microsoft;
    }

    // Other Platforms
    if (platformLower.contains('deezer')) return FontAwesomeIcons.music;
    if (platformLower.contains('quora')) return FontAwesomeIcons.quora;
    if (platformLower.contains('github')) return FontAwesomeIcons.github;
    if (platformLower.contains('amazon')) return FontAwesomeIcons.amazon;
    if (platformLower.contains('dropbox')) return FontAwesomeIcons.dropbox;
    if (platformLower.contains('google')) return FontAwesomeIcons.google;
    if (platformLower.contains('paypal')) return FontAwesomeIcons.paypal;
    if (platformLower.contains('skype')) return FontAwesomeIcons.skype;
    if (platformLower.contains('slack')) return FontAwesomeIcons.slack;
    if (platformLower.contains('stackoverflow'))
      return FontAwesomeIcons.stackOverflow;
    if (platformLower.contains('trello')) return FontAwesomeIcons.trello;
    if (platformLower.contains('vimeo')) return FontAwesomeIcons.vimeo;
    if (platformLower.contains('weibo')) return FontAwesomeIcons.weibo;

    // Default for unknown platforms
    return FontAwesomeIcons.globe;
  }

  // Get platform color
  static Color getPlatformColor(String platform) {
    final platformLower = platform.trim().toLowerCase();

    // Social Media Colors
    if (platformLower.contains('whatsapp')) return const Color(0xFF25D366);
    if (platformLower.contains('facebook')) return const Color(0xFF1877F2);
    if (platformLower.contains('instagram')) {
      return const Color(0xFFE1306C); // Instagram pink
    }
    if (platformLower.contains('tiktok')) return Colors.black;
    if (platformLower.contains('telegram')) return const Color(0xFF0088CC);
    if (platformLower.contains('linkedin')) return const Color(0xFF0A66C2);
    if (platformLower.contains('snapchat')) return const Color(0xFFFFFC00);
    if (platformLower.contains('pinterest')) return const Color(0xFFE60023);
    if (platformLower.contains('reddit')) return const Color(0xFFFF4500);
    if (platformLower.contains('discord')) return const Color(0xFF5865F2);
    if (platformLower.contains('medium')) return Colors.black;

    // X (formerly Twitter)
    if (platformLower == 'x' ||
        platformLower.contains('twitter') ||
        platformLower == 'x-twitter') {
      return Colors.black;
    }

    // Video & Streaming Colors
    if (platformLower.contains('youtube')) return const Color(0xFFFF0000);
    if (platformLower.contains('twitch')) return const Color(0xFF9146FF);
    if (platformLower.contains('netflix')) return const Color(0xFFE50914);
    if (platformLower.contains('spotify')) return const Color(0xFF1DB954);
    if (platformLower.contains('soundcloud')) return const Color(0xFFFF7700);
    if (platformLower.contains('audiomack')) return const Color(0xFFFFA500);

    // Apple platforms
    if (platformLower.contains('apple_music') ||
        platformLower.contains('apple music') ||
        platformLower.contains('apple-music')) {
      return Colors.black;
    }

    // App Store Colors
    if (platformLower.contains('playstore') ||
        platformLower.contains('google_play') ||
        platformLower.contains('play store')) {
      return const Color(0xFF4285F4);
    }
    if (platformLower.contains('appstore') ||
        platformLower.contains('apple_store') ||
        platformLower.contains('app store')) {
      return Colors.black;
    }
    if (platformLower.contains('microsoft') ||
        platformLower.contains('windows_store')) {
      return const Color(0xFF0078D4);
    }

    // Other Platforms
    if (platformLower.contains('deezer')) return const Color(0xFF00C7F2);
    if (platformLower.contains('amazon')) return const Color(0xFFFF9900);
    if (platformLower.contains('google')) return const Color(0xFF4285F4);
    if (platformLower.contains('github')) return Colors.black;

    // Default color
    return Colors.blueGrey;
  }

  // Get platform display name
  static String getPlatformDisplayName(String platform) {
    final platformLower = platform.trim().toLowerCase();

    // Social Media
    if (platformLower.contains('whatsapp')) return 'WhatsApp';
    if (platformLower.contains('facebook')) return 'Facebook';
    if (platformLower.contains('instagram')) return 'Instagram';
    if (platformLower.contains('tiktok')) return 'TikTok';
    if (platformLower.contains('telegram')) return 'Telegram';
    if (platformLower.contains('linkedin')) return 'LinkedIn';
    if (platformLower.contains('snapchat')) return 'Snapchat';
    if (platformLower.contains('pinterest')) return 'Pinterest';
    if (platformLower.contains('reddit')) return 'Reddit';
    if (platformLower.contains('discord')) return 'Discord';
    if (platformLower.contains('medium')) return 'Medium';

    // X (formerly Twitter)
    if (platformLower == 'x' ||
        platformLower.contains('x-twitter') ||
        (platformLower.contains('twitter') &&
            !platformLower.contains('x-twitter'))) {
      return 'X';
    }

    // Video & Streaming
    if (platformLower.contains('youtube')) return 'YouTube';
    if (platformLower.contains('twitch')) return 'Twitch';
    if (platformLower.contains('netflix')) return 'Netflix';
    if (platformLower.contains('spotify')) return 'Spotify';
    if (platformLower.contains('soundcloud')) return 'SoundCloud';
    if (platformLower.contains('audiomack')) return 'Audiomack';
    if (platformLower.contains('apple_music') ||
        platformLower.contains('apple music') ||
        platformLower.contains('apple-music')) {
      return 'Apple Music';
    }
    if (platformLower.contains('deezer')) return 'Deezer';

    // App Stores
    if (platformLower.contains('playstore') ||
        platformLower.contains('google_play') ||
        platformLower.contains('play store')) {
      return 'Google Play Store';
    }
    if (platformLower.contains('appstore') ||
        platformLower.contains('apple_store') ||
        platformLower.contains('app store')) {
      return 'Apple App Store';
    }
    if (platformLower.contains('microsoft') ||
        platformLower.contains('windows_store')) {
      return 'Microsoft Store';
    }

    // Other Platforms
    if (platformLower.contains('quora')) return 'Quora';
    if (platformLower.contains('github')) return 'GitHub';
    if (platformLower.contains('amazon')) return 'Amazon';
    if (platformLower.contains('dropbox')) return 'Dropbox';
    if (platformLower.contains('google')) return 'Google';
    if (platformLower.contains('paypal')) return 'PayPal';

    // Return formatted version of the platform name
    if (platform.isNotEmpty) {
      // Handle snake_case and kebab-case
      String formatted = platform.replaceAll('_', ' ').replaceAll('-', ' ');
      formatted = formatted
          .split(' ')
          .map(
            (word) =>
                word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                    : '',
          )
          .join(' ');
      return formatted;
    }

    return 'Social Media';
  }

  // Get platform category
  static String getPlatformCategory(String platform) {
    final platformLower = platform.trim().toLowerCase();

    if (socialMediaPlatforms.contains(platformLower)) return 'social_media';
    if (videoStreamingPlatforms.contains(platformLower))
      return 'video_streaming';
    if (appStorePlatforms.contains(platformLower)) return 'app_store';
    if (messagingPlatforms.contains(platformLower)) return 'messaging';

    return 'other';
  }

  // Check if platform is valid
  static bool isValidPlatform(String platform) {
    final platformLower = platform.trim().toLowerCase();

    return socialMediaPlatforms.contains(platformLower) ||
        videoStreamingPlatforms.contains(platformLower) ||
        appStorePlatforms.contains(platformLower) ||
        messagingPlatforms.contains(platformLower);
  }

  // Get all available platforms
  static List<String> getAllPlatforms() {
    return [
      ...socialMediaPlatforms,
      ...videoStreamingPlatforms,
      ...appStorePlatforms,
      ...messagingPlatforms,
    ]..sort((a, b) => a.compareTo(b));
  }

  // Get platforms by category
  static List<String> getPlatformsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'social_media':
      case 'social':
        return List.from(socialMediaPlatforms);
      case 'video':
      case 'streaming':
      case 'video_streaming':
        return List.from(videoStreamingPlatforms);
      case 'app_store':
      case 'store':
        return List.from(appStorePlatforms);
      case 'messaging':
        return List.from(messagingPlatforms);
      default:
        return List.from(getAllPlatforms());
    }
  }

  // Get platform widget for UI
  static Widget getPlatformWidget({
    required String platform,
    double iconSize = 24.0,
    bool showLabel = false,
    TextStyle? labelStyle,
    bool circleBackground = false,
  }) {
    final iconData = getPlatformIcon(platform);
    final color = getPlatformColor(platform);
    final displayName = getPlatformDisplayName(platform);

    Widget iconWidget = Icon(iconData, size: iconSize, color: Colors.white);

    if (circleBackground) {
      iconWidget = Container(
        width: iconSize * 1.5,
        height: iconSize * 1.5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: iconWidget),
      );
    }

    if (showLabel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(displayName, style: labelStyle ?? const TextStyle(fontSize: 12)),
        ],
      );
    }

    return iconWidget;
  }

  // Get platform chip widget
  static Widget getPlatformChip({
    required String platform,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected
                  ? getPlatformColor(platform)
                  : getPlatformColor(platform).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected
                    ? getPlatformColor(platform)
                    : getPlatformColor(platform).withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getPlatformIcon(platform),
              size: 16,
              color: selected ? Colors.white : getPlatformColor(platform),
            ),
            const SizedBox(width: 6),
            Text(
              getPlatformDisplayName(platform),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : getPlatformColor(platform),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get platform options for dropdown
  static List<DropdownMenuItem<String>> getPlatformDropdownItems() {
    return getAllPlatforms().map((platform) {
      return DropdownMenuItem<String>(
        value: platform,
        child: Row(
          children: [
            Icon(
              getPlatformIcon(platform),
              size: 20,
              color: getPlatformColor(platform),
            ),
            const SizedBox(width: 10),
            Text(getPlatformDisplayName(platform)),
          ],
        ),
      );
    }).toList();
  }

  // Get platform metadata
  static Map<String, dynamic> getPlatformMetadata(String platform) {
    return {
      'icon': getPlatformIcon(platform),
      'color': getPlatformColor(platform),
      'display_name': getPlatformDisplayName(platform),
      'category': getPlatformCategory(platform),
      'is_valid': isValidPlatform(platform),
    };
  }

  // Validate platform for task type
  static bool validatePlatformForTask(String platform, String taskType) {
    final platformLower = platform.trim().toLowerCase();
    final taskTypeLower = taskType.trim().toLowerCase();

    if (taskTypeLower.contains('advert')) {
      // Advert tasks work on most platforms
      return socialMediaPlatforms.contains(platformLower) ||
          videoStreamingPlatforms.contains(platformLower);
    }

    if (taskTypeLower.contains('engagement')) {
      // Engagement tasks work on social media
      return socialMediaPlatforms.contains(platformLower);
    }

    if (taskTypeLower.contains('app')) {
      // App promotion tasks
      return appStorePlatforms.contains(platformLower);
    }

    if (taskTypeLower.contains('music') || taskTypeLower.contains('audio')) {
      // Music/Audio tasks
      return videoStreamingPlatforms.contains(platformLower) ||
          platformLower.contains('audiomack') ||
          platformLower.contains('spotify') ||
          platformLower.contains('soundcloud') ||
          platformLower.contains('apple_music') ||
          platformLower.contains('deezer');
    }

    return true;
  }
}
