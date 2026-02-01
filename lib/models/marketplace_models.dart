// models/marketplace_models.dart
import 'dart:convert';

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
  final DateTime createdAt;
  final double? oldPrice;
  final String? brand;
  final int viewsCount;
  final int likesCount;
  final List<ProductImage> images;
  final ProductSeller? seller;
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
    required this.createdAt,
    this.oldPrice,
    this.brand,
    required this.viewsCount,
    required this.likesCount,
    required this.images,
    this.seller,
  }) : isActive = status == 'ACTIVE';

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    // Parse images
    final imagesList = json['marketplace_product_images'] as List? ?? [];
    final images =
        imagesList
            .map((img) => ProductImage.fromJson(img))
            .cast<ProductImage>()
            .toList();

    // Parse seller if available
    ProductSeller? seller;
    if (json['profiles'] != null) {
      seller = ProductSeller.fromJson(json['profiles']);
    }

    return MarketplaceProduct(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      title: json['title'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      availableSizes: List<String>.from(json['available_sizes'] ?? []),
      availableColors: List<String>.from(json['available_colors'] ?? []),
      returnPolicy: json['return_policy'] as String?,
      mainCategory: json['main_category'] as String,
      subCategory1: json['sub_category_1'] as String?,
      subCategory2: json['sub_category_2'] as String?,
      stateId: (json['state_id'] as num?)?.toInt(),
      lgaId: (json['lga_id'] as num?)?.toInt(),
      status: (json['status'] as String?) ?? 'ACTIVE',
      createdAt: DateTime.parse(json['created_at'] as String),
      oldPrice: (json['old_price'] as num?)?.toDouble(),
      brand: json['brand'] as String?,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
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
      'created_at': createdAt.toIso8601String(),
      'old_price': oldPrice,
      'brand': brand,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'marketplace_product_images': images.map((img) => img.toJson()).toList(),
      if (seller != null) 'profiles': seller!.toJson(),
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
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      reporterId: json['reporter_id'] as String,
      reason: json['reason'] as String,
      details: json['details'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
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
      totalProducts: (json['total_products'] as num).toInt(),
      activeProducts: (json['active_products'] as num).toInt(),
      totalViews: (json['total_views'] as num).toInt(),
      totalLikes: (json['total_likes'] as num).toInt(),
      totalValue: (json['total_value'] as num).toDouble(),
    );
  }
}
