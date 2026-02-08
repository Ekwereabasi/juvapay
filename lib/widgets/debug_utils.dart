// utils/debug_utils.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugUtils {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Main debugging method to check Marketplace data and structure
  static Future<void> debugMarketplace() async {
    try {
      print('=== MARKETPLACE DEBUG START ===');

      // 1. Check table structure
      // .select() returns List<Map<String, dynamic>> by default
      final List<Map<String, dynamic>> tableInfo = await _supabase
          .from('marketplace_products')
          .select()
          .limit(1);

      if (tableInfo.isNotEmpty) {
        print('Table structure sample: ${tableInfo.first.keys.toList()}');
      } else {
        print('Table structure: No data found in marketplace_products.');
      }

      // 2. Count total active products
      // FIX: Chaining .count() returns a PostgrestResponse object
      // containing both .data and .count
      final response = await _supabase
          .from('marketplace_products')
          .select()
          .eq('status', 'ACTIVE')
          .count(CountOption.exact);

      print('Total active products count: ${response.count}');

      // 3. Get 5 products with images (Relational Join)
      final List<Map<String, dynamic>> productsWithImages = await _supabase
          .from('marketplace_products')
          .select('''
            id, title, price, status,
            marketplace_product_images(image_url)
          ''')
          .eq('status', 'ACTIVE')
          .limit(5);

      print('Sample products with images:');
      for (var product in productsWithImages) {
        final title = product['title'] ?? 'No Title';
        final price = product['price'] ?? '0';
        final images = product['marketplace_product_images'] as List?;

        print('  - $title: ₦$price');
        print('    Images found: ${images?.length ?? 0}');
      }

      // 4. Check unique categories
      final catData = await _supabase
          .from('marketplace_products')
          .select('category');

      final uniqueCategories =
          catData
              .map((p) => p['category']?.toString() ?? 'Unknown')
              .toSet()
              .toList();

      print('Available categories: $uniqueCategories');
      print('=== MARKETPLACE DEBUG END ===');
    } catch (e, stackTrace) {
      print('Debug error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// A simpler version that avoids the PostgrestResponse object entirely
  static Future<void> debugMarketplaceSimple() async {
    try {
      print('=== SIMPLE MARKETPLACE DEBUG ===');

      // Just get the data as a list
      final List<Map<String, dynamic>> allActive = await _supabase
          .from('marketplace_products')
          .select('id')
          .eq('status', 'ACTIVE');

      print('Active product count (via list length): ${allActive.length}');

      final List<Map<String, dynamic>> sampleData = await _supabase
          .from('marketplace_products')
          .select('id, title, price, category, created_at')
          .eq('status', 'ACTIVE')
          .order('created_at', ascending: false)
          .limit(3);

      for (var product in sampleData) {
        print(
          'Product: ${product['title']} | Category: ${product['category']}',
        );
      }

      print('=== END SIMPLE DEBUG ===');
    } catch (e) {
      print('Simple debug error: $e');
    }
  }
}
