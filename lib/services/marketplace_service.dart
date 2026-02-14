// services/marketplace_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace_models.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _storageBucket = 'marketplace-images';
  static const String _productSelectWithProfiles = '''
          *,
          marketplace_product_images(*),
          profiles!marketplace_products_user_id_fkey(*)
        ''';
  static const String _productSelectWithoutProfiles = '''
          *,
          marketplace_product_images(*)
        ''';

  // ==========================================
  // 1. PRODUCT MANAGEMENT
  // ==========================================

  Future<MarketplaceProduct> createProduct({
    required String title,
    required double price,
    required String description,
    required String mainCategory,
    List<String>? availableSizes,
    List<String>? availableColors,
    String? returnPolicy,
    String? subCategory1,
    String? subCategory2,
    int? stateId,
    int? lgaId,
    int quantity = 1,
    double? oldPrice,
    String? brand,
    List<File>? images,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // 1. Create product record
      final productResponse = await _supabase
          .from('marketplace_products')
          .insert({
            'user_id': user.id,
            'title': title,
            'price': price,
            'description': description,
            'main_category': mainCategory,
            'available_sizes': availableSizes,
            'available_colors': availableColors,
            'return_policy': returnPolicy,
            'sub_category_1': subCategory1,
            'sub_category_2': subCategory2,
            'state_id': stateId,
            'lga_id': lgaId,
            'quantity': quantity,
            'old_price': oldPrice,
            'brand': brand,
            'status': 'ACTIVE',
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 30));

      final productId = productResponse['id'] as int;

      // 2. Upload images if provided
      final List<ProductImage> uploadedImages = [];
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final imageUrl = await _uploadProductImage(
            productId: productId,
            imageFile: images[i],
            index: i,
          );
          uploadedImages.add(
            ProductImage(
              id: 0, // Will be set by database
              productId: productId,
              imageUrl: imageUrl,
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      // 3. Return complete product object
      return MarketplaceProduct.fromJson({
        ...productResponse,
        'marketplace_product_images':
            uploadedImages.map((img) => img.toJson()).toList(),
      });
    } on TimeoutException {
      throw Exception('Product creation timed out');
    } on PostgrestException catch (e) {
      throw Exception('Failed to create product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }
  

  Future<String> _uploadProductImage({
    required int productId,
    required File imageFile,
    required int index,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_${productId}_${timestamp}_$index.jpg';
      final filePath = '$productId/$fileName';

      // Upload to storage
      await _supabase.storage
          .from(_storageBucket)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_storageBucket)
          .getPublicUrl(filePath);

      // Save image record to database
      await _supabase.from('marketplace_product_images').insert({
        'product_id': productId,
        'image_url': publicUrl,
      });

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Updated getProducts method
  Future<List<MarketplaceProduct>> getProducts({
    String? category,
    int? stateId,
    int? lgaId,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('Fetching products with params:');
      debugPrint('  Category: $category');
      debugPrint('  State: $stateId');
      debugPrint('  LGA: $lgaId');
      debugPrint('  Search: $searchQuery');
      debugPrint('  Sort: $sortBy');
      debugPrint('  Limit: $limit, Offset: $offset');

      List<dynamic> response;
      try {
        response = await _fetchProductsRaw(
          select: _productSelectWithProfiles,
          category: category,
          stateId: stateId,
          lgaId: lgaId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          searchQuery: searchQuery,
          sortBy: sortBy,
          ascending: ascending,
          limit: limit,
          offset: offset,
        );
      } on PostgrestException catch (e) {
        debugPrint(
          'Primary product query failed, retrying without profiles: ${e.message}',
        );
        response = await _fetchProductsRaw(
          select: _productSelectWithoutProfiles,
          category: category,
          stateId: stateId,
          lgaId: lgaId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          searchQuery: searchQuery,
          sortBy: sortBy,
          ascending: ascending,
          limit: limit,
          offset: offset,
        );
      }

      debugPrint('Raw response from Supabase: ${response.length} items');

      final productsJson = List<Map<String, dynamic>>.from(response as List);

      // Hydrate seller profile if the join failed or is missing
      await Future.wait(
        productsJson.map((json) async {
          if (json['profiles'] != null) return;
          final userId = (json['user_id'] ?? '').toString();
          if (userId.isEmpty) return;
          final profile = await _fetchProfileByUserId(userId);
          if (profile != null) {
            json['profiles'] = profile;
          }
        }),
      );

      // Parse response
      final products =
          productsJson
              .map((json) {
                try {
                  return MarketplaceProduct.fromJson(json);
                } catch (e) {
                  debugPrint('Error parsing product JSON: $e');
                  debugPrint('Problematic JSON: $json');
                  return null;
                }
              })
              .where((product) => product != null)
              .cast<MarketplaceProduct>()
              .toList();

      debugPrint('Successfully parsed ${products.length} products');

      return products;
    } on TimeoutException catch (e) {
      debugPrint('Timeout loading products: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error loading products: $e');
      rethrow;
    }
  }

  Future<MarketplaceProduct?> getProductById(int productId) async {
    try {
      Map<String, dynamic>? response;
      try {
        response = await _fetchProductByIdRaw(
          select: _productSelectWithProfiles,
          productId: productId,
        );
      } on PostgrestException catch (e) {
        debugPrint(
          'Primary productById query failed, retrying without profiles: ${e.message}',
        );
        response = await _fetchProductByIdRaw(
          select: _productSelectWithoutProfiles,
          productId: productId,
        );
      }

      if (response == null) return null;

      if (response['profiles'] == null) {
        final userId = (response['user_id'] ?? '').toString();
        if (userId.isNotEmpty) {
          final profile = await _fetchProfileByUserId(userId);
          if (profile != null) {
            response['profiles'] = profile;
          }
        }
      }
      return MarketplaceProduct.fromJson(response);
    } on TimeoutException {
      throw Exception('Product request timed out');
    } catch (e) {
      debugPrint('Error getting product by ID: $e');
      return null;
    }
  }

  Future<List<dynamic>> _fetchProductsRaw({
    required String select,
    String? category,
    int? stateId,
    int? lgaId,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    required String sortBy,
    required bool ascending,
    required int limit,
    required int offset,
  }) async {
    dynamic query = _supabase
        .from('marketplace_products')
        .select(select)
        .eq('status', 'ACTIVE');
    query = query.eq('is_banned', false);

    if (category != null && category.isNotEmpty) {
      query = query.eq('main_category', category);
    }

    if (stateId != null) {
      query = query.eq('state_id', stateId);
    }

    if (lgaId != null) {
      query = query.eq('lga_id', lgaId);
    }

    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }

    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }

    switch (sortBy) {
      case 'price':
        query = query.order('price', ascending: ascending);
        break;
      case 'views':
        query = query.order('views_count', ascending: ascending);
        break;
      case 'likes':
        query = query.order('likes_count', ascending: ascending);
        break;
      default:
        query = query.order('created_at', ascending: ascending);
    }

    final response = await query
        .range(offset, offset + limit - 1)
        .timeout(const Duration(seconds: 10));

    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>?> _fetchProductByIdRaw({
    required String select,
    required int productId,
  }) async {
    final response = await _supabase
        .from('marketplace_products')
        .select(select)
        .eq('id', productId)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (response == null) return null;
    return response as Map<String, dynamic>;
  }

  Future<void> incrementProductView(int productId) async {
    try {
      await _supabase
          .rpc(
            'increment_product_view',
            params: {'product_id_input': productId},
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error incrementing product view: $e');
      // Silently fail - view counting isn't critical
    }
  }

  Future<bool> incrementProductViewUnique(int productId) async {
    try {
      final response =
          await _supabase
              .rpc(
                'increment_product_view_unique',
                params: {'product_id_input': productId},
              )
              .timeout(const Duration(seconds: 5));

      if (response is bool) return response;
      if (response is Map && response['incremented'] is bool) {
        return response['incremented'] as bool;
      }
      return false;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        // RPC missing - fall back to non-unique counter
        await incrementProductView(productId);
        return true;
      }
      debugPrint('Error incrementing unique view: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error incrementing unique view: $e');
      return false;
    }
  }

  Future<void> updateProduct({
    required int productId,
    String? title,
    double? price,
    String? description,
    String? status,
    int? quantity,
    double? oldPrice,
    String? brand,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (price != null) updates['price'] = price;
      if (description != null) updates['description'] = description;
      if (status != null) updates['status'] = status;
      if (quantity != null) updates['quantity'] = quantity;
      if (oldPrice != null) updates['old_price'] = oldPrice;
      if (brand != null) updates['brand'] = brand;

      await _supabase
          .from('marketplace_products')
          .update(updates)
          .eq('id', productId)
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(int productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('marketplace_products')
          .delete()
          .eq('id', productId)
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // ==========================================
  // 2. PRODUCT REPORTS
  // ==========================================

  Future<void> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('product_reports')
          .insert({
            'product_id': productId,
            'reporter_id': user.id,
            'reason': reason,
            'details': details,
            'status': 'pending',
          })
          .timeout(const Duration(seconds: 10));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation
        throw Exception('You have already reported this product');
      }
      throw Exception('Failed to report product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to report product: $e');
    }
  }

  // ==========================================
  // 3. ADVERT SUBSCRIPTIONS
  // ==========================================

  Future<Map<String, dynamic>> getActiveAdvertSubscription() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response =
          await _supabase
              .from('active_advert_subscriptions')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      if (response == null) {
        return {'has_subscription': false, 'is_active': false};
      }

      return {
        'has_subscription': true,
        'is_active': response['is_active'] == true,
        'latest_expiry': response['latest_expiry'],
      };
    } catch (e) {
      debugPrint('Error getting advert subscription: $e');
      return {'has_subscription': false, 'is_active': false};
    }
  }

  Future<Map<String, dynamic>> createAdvertSubscription({
    required int durationDays,
    required double amount,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final endDate = DateTime.now().add(Duration(days: durationDays));

      final response = await _supabase
          .from('advert_subscriptions')
          .insert({
            'user_id': user.id,
            'end_date': endDate.toIso8601String(),
            'amount_paid': amount,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 10));

      return response;
    } catch (e) {
      throw Exception('Failed to create advert subscription: $e');
    }
  }

  // ==========================================
  // 4. PRODUCT INTERACTIONS
  // ==========================================

  Future<void> toggleProductLike(
    int productId, {
    required bool isLiked,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      if (isLiked) {
        // Unlike
        await _supabase
            .from('product_likes')
            .delete()
            .eq('product_id', productId)
            .eq('user_id', user.id);

        try {
          await _supabase.rpc(
            'decrement_product_likes',
            params: {'product_id_input': productId},
          );
        } catch (e) {
          try {
            await _applyLikesCountDelta(productId, -1);
          } catch (updateError) {
            debugPrint('Failed to decrement likes count: $updateError');
          }
        }
      } else {
        // Like
        try {
          await _supabase.from('product_likes').insert({
            'product_id': productId,
            'user_id': user.id,
          });
        } on PostgrestException catch (e) {
          // Ignore duplicate likes to avoid bubbling errors to the UI.
          if (e.code == '23505') return;
          rethrow;
        }

        try {
          await _supabase.rpc(
            'increment_product_likes',
            params: {'product_id_input': productId},
          );
        } catch (e) {
          try {
            await _applyLikesCountDelta(productId, 1);
          } catch (updateError) {
            debugPrint('Failed to increment likes count: $updateError');
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling product like: $e');
      throw Exception('Failed to update like status');
    }
  }

  Future<bool> checkIfProductLiked(int productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response =
          await _supabase
              .from('product_likes')
              .select()
              .eq('product_id', productId)
              .eq('user_id', user.id)
              .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking product like: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _fetchProfileByUserId(String userId) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle()
              .timeout(const Duration(seconds: 5));

      if (response == null) return null;
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching profile for user $userId: $e');
      return null;
    }
  }

  Future<void> _applyLikesCountDelta(int productId, int delta) async {
    final response =
        await _supabase
            .from('marketplace_products')
            .select('likes_count')
            .eq('id', productId)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

    final current =
        response == null ? 0 : (response['likes_count'] as num? ?? 0).toInt();
    final next = current + delta;
    final safeNext = next < 0 ? 0 : next;

    await _supabase
        .from('marketplace_products')
        .update({'likes_count': safeNext})
        .eq('id', productId)
        .timeout(const Duration(seconds: 5));
  }

  // ==========================================
  // 5. MARKETPLACE STATISTICS
  // ==========================================

  Future<MarketplaceStats> getMarketplaceStats() async {
    try {
      final response = await _supabase
          .rpc('get_marketplace_stats')
          .single()
          .timeout(const Duration(seconds: 10));

      return MarketplaceStats.fromJson(response);
    } catch (e) {
      debugPrint('Error getting marketplace stats: $e');
      return MarketplaceStats(
        totalProducts: 0,
        activeProducts: 0,
        totalViews: 0,
        totalLikes: 0,
        totalValue: 0,
      );
    }
  }

  // ==========================================
  // 6. UTILITY METHODS
  // ==========================================

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('marketplace_products')
          .select('main_category')
          .not('main_category', 'is', null);

      final categories =
          (response as List)
              .map((e) => e['main_category'] as String)
              .toSet()
              .toList();

      categories.sort();
      return categories;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  Future<List<String>> getBrands() async {
    try {
      final response = await _supabase
          .from('marketplace_products')
          .select('brand')
          .not('brand', 'is', null);

      final brands =
          (response as List).map((e) => e['brand'] as String).toSet().toList();

      brands.sort();
      return brands;
    } catch (e) {
      debugPrint('Error getting brands: $e');
      return [];
    }
  }

  
  Stream<List<MarketplaceProduct>> watchUserProducts() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('marketplace_products')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id) // Keep the primary user filter if allowed
        .order('created_at', ascending: false)
        .map((snapshot) {
          // Perform the 'status' and any extra filtering here in Dart
          return snapshot
              .where((data) => data['status'] == 'ACTIVE')
              .map((data) => MarketplaceProduct.fromJson(data))
              .toList();
        });
  }

  // Helper method to format phone number for WhatsApp
  static String formatPhoneForWhatsApp(String phoneNumber) {
    // Remove all non-digit characters
    String digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // If number starts with 0, convert to 234
    if (digits.startsWith('0')) {
      digits = '234${digits.substring(1)}';
    }
    // If number starts with +234, remove the +
    else if (digits.startsWith('234')) {
      digits = digits;
    }
    // If number is 10 digits (without country code), assume it's Nigerian
    else if (digits.length == 10) {
      digits = '234${digits.substring(1)}';
    }

    return digits;
  }
}
