// models/marketplace_models.dart
import 'dart:convert';

int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      return [value];
    }
  }
  return const [];
}

class MarketplaceProduct {
  final int id;
  final String userId;
  final String title;
  final int quantity;
  final double price;
  final String description;
  final List<String> availableSizes;
  final List<String> availableColors;
  final String? returnPolicy;
  final String mainCategory;
  final String? subCategory1;
  final String? subCategory2;
  final int? stateId;
  final int? lgaId;
  final String status;
  final bool isBanned;
  final String? bannedReason;
  final DateTime? bannedAt;
  final DateTime createdAt;
  final double? oldPrice;
  final String? brand;
  final int viewsCount;
  final int likesCount;
  final List<ProductImage> images;
  final Profile seller; // Changed from ProductSeller? to Profile
  final bool isActive;

  MarketplaceProduct({
    required this.id,
    required this.userId,
    required this.title,
    required this.quantity,
    required this.price,
    required this.description,
    required this.availableSizes,
    required this.availableColors,
    this.returnPolicy,
    required this.mainCategory,
    this.subCategory1,
    this.subCategory2,
    this.stateId,
    this.lgaId,
    required this.status,
    required this.isBanned,
    this.bannedReason,
    this.bannedAt,
    required this.createdAt,
    this.oldPrice,
    this.brand,
    required this.viewsCount,
    required this.likesCount,
    required this.images,
    required this.seller, // Changed to required
  }) : isActive = status == 'ACTIVE' && !isBanned;

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    // Parse images
    final imagesList = json['marketplace_product_images'] as List? ?? [];
    final images =
        imagesList
            .map((img) => ProductImage.fromJson(img))
            .cast<ProductImage>()
            .toList();

    // Parse seller if available - assuming 'profiles' key exists
    Profile seller;
    if (json['profiles'] != null) {
      seller = Profile.fromJson(json['profiles']);
    } else {
      // Create a default seller profile if not found
      seller = Profile(
        id: json['user_id'] as String? ?? '',
        fullName: 'Anonymous Seller',
        phoneNumber: null,
        email: null,
        avatarUrl: null,
        username: null,
      );
    }

    return MarketplaceProduct(
      id: _parseInt(json['id']),
      userId: (json['user_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      quantity: _parseInt(json['quantity'], defaultValue: 1),
      price: _parseDouble(json['price']),
      description: (json['description'] ?? '').toString(),
      availableSizes: _parseStringList(json['available_sizes']),
      availableColors: _parseStringList(json['available_colors']),
      returnPolicy: json['return_policy'] as String?,
      mainCategory: (json['main_category'] ?? '').toString(),
      subCategory1: json['sub_category_1'] as String?,
      subCategory2: json['sub_category_2'] as String?,
      stateId: json['state_id'] == null ? null : _parseInt(json['state_id']),
      lgaId: json['lga_id'] == null ? null : _parseInt(json['lga_id']),
      status: (json['status'] as String?) ?? 'ACTIVE',
      isBanned: json['is_banned'] == true,
      bannedReason: json['banned_reason'] as String?,
      bannedAt:
          json['banned_at'] != null
              ? _parseDateTime(json['banned_at'])
              : null,
      createdAt: _parseDateTime(json['created_at']),
      oldPrice: json['old_price'] == null
          ? null
          : _parseDouble(json['old_price']),
      brand: json['brand'] as String?,
      viewsCount: _parseInt(json['views_count']),
      likesCount: _parseInt(json['likes_count']),
      images: images,
      seller: seller,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'quantity': quantity,
      'price': price,
      'description': description,
      'available_sizes': availableSizes,
      'available_colors': availableColors,
      'return_policy': returnPolicy,
      'main_category': mainCategory,
      'sub_category_1': subCategory1,
      'sub_category_2': subCategory2,
      'state_id': stateId,
      'lga_id': lgaId,
      'status': status,
      'is_banned': isBanned,
      'banned_reason': bannedReason,
      'banned_at': bannedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'old_price': oldPrice,
      'brand': brand,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'marketplace_product_images': images.map((img) => img.toJson()).toList(),
      'profiles': seller.toJson(),
    };
  }

  double? get discountPercent {
    if (oldPrice != null && oldPrice! > price && oldPrice! > 0) {
      return ((oldPrice! - price) / oldPrice!) * 100;
    }
    return null;
  }

  String get formattedDiscount {
    final discount = discountPercent;
    return discount != null ? '${discount.toInt()}% OFF' : '';
  }

  bool get hasDiscount => discountPercent != null;
}

class ProductImage {
  final int id;
  final int productId;
  final String imageUrl;
  final DateTime createdAt;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      imageUrl: (json['image_url'] ?? '').toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Changed from ProductSeller to Profile to match your existing code
class Profile {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? username;

  Profile({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.username,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Anonymous Seller',
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'avatar_url': avatarUrl,
      'username': username,
    };
  }
}

// Keep ProductSeller as alias for backward compatibility if needed
class ProductSeller {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? username;

  ProductSeller({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.username,
  });

  factory ProductSeller.fromJson(Map<String, dynamic> json) {
    return ProductSeller(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Anonymous Seller',
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'avatar_url': avatarUrl,
      'username': username,
    };
  }
}

class ProductReport {
  final int id;
  final int productId;
  final String reporterId;
  final String reason;
  final String? details;
  final String status;
  final DateTime createdAt;

  ProductReport({
    required this.id,
    required this.productId,
    required this.reporterId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
  });

  factory ProductReport.fromJson(Map<String, dynamic> json) {
    return ProductReport(
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      reporterId: (json['reporter_id'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      details: json['details'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'reporter_id': reporterId,
      'reason': reason,
      'details': details,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MarketplaceStats {
  final int totalProducts;
  final int activeProducts;
  final int totalViews;
  final int totalLikes;
  final double totalValue;

  MarketplaceStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalViews,
    required this.totalLikes,
    required this.totalValue,
  });

  factory MarketplaceStats.fromJson(Map<String, dynamic> json) {
    return MarketplaceStats(
      totalProducts: _parseInt(json['total_products']),
      activeProducts: _parseInt(json['active_products']),
      totalViews: _parseInt(json['total_views']),
      totalLikes: _parseInt(json['total_likes']),
      totalValue: _parseDouble(json['total_value']),
    );
  }
}
