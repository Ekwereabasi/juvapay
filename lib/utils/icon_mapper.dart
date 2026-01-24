// utils/icon_mapper.dart
import 'package:flutter/material.dart';

class IconMapper {
  // Safe mapping for common icon codes/names
  static const Map<String, IconData> _iconMap = {
    // Task categories
    'advert': Icons.campaign,
    'engagement': Icons.thumb_up,
    'follow': Icons.person_add,
    'like': Icons.favorite,
    'comment': Icons.comment,
    'share': Icons.share,
    'video': Icons.video_library,
    'music': Icons.music_note,
    'app': Icons.download,
    'review': Icons.star,
    'social': Icons.people,

    // Common Material Icons by hex code
    'e616': Icons.work, // Default work icon
    'e0c8': Icons.account_balance,
    'e0e1': Icons.attach_money,
    'e0e0': Icons.money,
    'e0be': Icons.shopping_cart,
    'e0cd': Icons.credit_card,
    'e8b8': Icons.settings,
    'e8b6': Icons.send,
    'e8b9': Icons.share,
    'e5d4': Icons.home,
    'e5d2': Icons.menu,
  };

  // Get icon by key with safe fallbacks
  static IconData getIconByKey(String iconKey, {String? fallbackCategory}) {
    // Try direct match
    if (_iconMap.containsKey(iconKey)) {
      return _iconMap[iconKey]!;
    }

    // Try without '0x' prefix if it's a hex code
    if (iconKey.startsWith('0x')) {
      final hexKey = iconKey.substring(2);
      if (_iconMap.containsKey(hexKey)) {
        return _iconMap[hexKey]!;
      }
    }

    // Return fallback
    return Icons.work;
  }
}
