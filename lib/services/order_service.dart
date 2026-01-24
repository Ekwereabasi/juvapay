// services/order_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all orders for current user with pagination - FIXED VERSION
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
    String? platform,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      // Build query with all conditions in one chain
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      // METHOD 1: Direct query without variable assignment
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            financial_transactions!transaction_id (
              id,
              amount,
              transaction_type,
              status,
              created_at
            )
          ''')
          .eq('user_id', user.id)
          .maybeEq(
            'status',
            status != null && status.isNotEmpty && status != 'all'
                ? status
                : null,
          )
          .maybeEq(
            'selected_platform',
            platform != null && platform.isNotEmpty && platform != 'all'
                ? platform
                : null,
          )
          .maybeGte('created_at', startDate?.toIso8601String())
          .maybeLte('created_at', endDate?.toIso8601String())
          .order('created_at', ascending: false)
          .range(from, to);

      // Get total count
      final countResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_id', user.id)
          .maybeEq(
            'status',
            status != null && status.isNotEmpty && status != 'all'
                ? status
                : null,
          )
          .maybeEq(
            'selected_platform',
            platform != null && platform.isNotEmpty && platform != 'all'
                ? platform
                : null,
          )
          .maybeGte('created_at', startDate?.toIso8601String())
          .maybeLte('created_at', endDate?.toIso8601String());

      final totalCount = (countResponse as List).length;
      final orders = List<Map<String, dynamic>>.from(response);

      // Parse media URLs if they exist
      final parsedOrders =
          orders.map((order) {
            final mediaUrls = order['media_urls'] as List<dynamic>?;
            final mediaStoragePaths =
                order['media_storage_paths'] as List<dynamic>?;

            return {
              ...order,
              'media_urls': mediaUrls?.cast<String>() ?? [],
              'media_storage_paths': mediaStoragePaths?.cast<String>() ?? [],
              'media_url': order['media_url'],
              'media_storage_path': order['media_storage_path'],
            };
          }).toList();

      return {
        'orders': parsedOrders,
        'total': totalCount,
        'page': page,
        'limit': limit,
        'has_more': parsedOrders.length >= limit,
      };
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final response =
          await _supabase
              .from('orders')
              .select('''
            *,
            financial_transactions!transaction_id (
              id,
              amount,
              transaction_type,
              status,
              created_at,
              description,
              reference_id
            )
          ''')
              .eq('id', orderId)
              .eq('user_id', user.id)
              .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching order details: $e');
      rethrow;
    }
  }

  // Get order statistics - simplified version
  Future<Map<String, dynamic>> getOrderStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      // Get all orders for the user
      final allOrdersResponse = await _supabase
          .from('orders')
          .select()
          .eq('user_id', user.id);

      final allOrders = allOrdersResponse as List;

      // Calculate statistics
      int activeCount = 0;
      int completedCount = 0;
      int pendingCount = 0;
      int cancelledCount = 0;
      double totalSpent = 0;
      int recentCount = 0;

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      for (var order in allOrders) {
        final orderMap = order as Map<String, dynamic>;
        final status = orderMap['status'] as String? ?? '';
        final createdAt = DateTime.parse(orderMap['created_at'] as String);
        final totalPrice = (orderMap['total_price'] as num).toDouble();

        // Count by status
        switch (status.toLowerCase()) {
          case 'active':
            activeCount++;
            break;
          case 'completed':
            completedCount++;
            totalSpent += totalPrice;
            break;
          case 'pending':
            pendingCount++;
            break;
          case 'cancelled':
            cancelledCount++;
            break;
        }

        // Count recent orders
        if (createdAt.isAfter(weekAgo)) {
          recentCount++;
        }
      }

      return {
        'total_orders': allOrders.length,
        'active_orders': activeCount,
        'completed_orders': completedCount,
        'pending_orders': pendingCount,
        'cancelled_orders': cancelledCount,
        'total_spent': totalSpent,
        'recent_orders_7_days': recentCount,
      };
    } catch (e) {
      print('Error fetching order stats: $e');
      return {
        'total_orders': 0,
        'active_orders': 0,
        'completed_orders': 0,
        'pending_orders': 0,
        'cancelled_orders': 0,
        'total_spent': 0.0,
        'recent_orders_7_days': 0,
      };
    }
  }

  // Cancel order
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      // Check if order exists and belongs to user
      final orderResponse =
          await _supabase
              .from('orders')
              .select()
              .eq('id', orderId)
              .eq('user_id', user.id)
              .single();

      final order = orderResponse as Map<String, dynamic>;

      if (order['status'] != 'pending' && order['status'] != 'active') {
        return {
          'success': false,
          'message': 'Order cannot be cancelled at this stage',
        };
      }

      // Update order status
      final response =
          await _supabase
              .from('orders')
              .update({
                'status': 'cancelled',
                'cancelled_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', orderId)
              .eq('user_id', user.id)
              .select();

      // Refund transaction if exists
      final transactionId = order['transaction_id'];
      if (transactionId != null) {
        await _supabase
            .from('financial_transactions')
            .update({
              'status': 'REFUNDED',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', transactionId);
      }

      return {
        'success': true,
        'message': 'Order cancelled successfully',
        'order': response,
      };
    } catch (e) {
      print('Error cancelling order: $e');
      return {'success': false, 'message': 'Failed to cancel order: $e'};
    }
  }

  // Get order activity log
  Future<List<Map<String, dynamic>>> getOrderActivity(String orderId) async {
    try {
      final response = await _supabase
          .from('order_activities')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching order activity: $e');
      return [];
    }
  }

  // Get platforms filter options
  Future<List<String>> getPlatformOptions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('orders')
          .select('selected_platform')
          .eq('user_id', user.id);

      final List<dynamic> responseList = response as List;
      final platforms =
          responseList
              .map((item) => item['selected_platform'] as String?)
              .where((platform) => platform != null && platform.isNotEmpty)
              .toSet()
              .toList()
              .cast<String>();

      return platforms;
    } catch (e) {
      print('Error fetching platform options: $e');
      return [];
    }
  }

  // Search orders
  Future<Map<String, dynamic>> searchOrders(String query) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            financial_transactions!transaction_id (
              id,
              amount,
              transaction_type,
              status,
              created_at
            )
          ''')
          .eq('user_id', user.id)
          .or('task_title.ilike.%$query%,caption.ilike.%$query%,id.eq.$query')
          .order('created_at', ascending: false)
          .limit(20);

      final orders = List<Map<String, dynamic>>.from(response as List);

      return {'orders': orders, 'total': orders.length, 'has_more': false};
    } catch (e) {
      print('Error searching orders: $e');
      return {'orders': [], 'total': 0, 'has_more': false};
    }
  }

  // Export orders to CSV (returns as string)
  Future<String> exportOrdersToCSV({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? platform,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      // Build query in one chain
      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .maybeEq(
            'status',
            status != null && status.isNotEmpty && status != 'all'
                ? status
                : null,
          )
          .maybeEq(
            'selected_platform',
            platform != null && platform.isNotEmpty && platform != 'all'
                ? platform
                : null,
          )
          .maybeGte('created_at', startDate?.toIso8601String())
          .maybeLte('created_at', endDate?.toIso8601String())
          .order('created_at', ascending: false);

      final orders = response as List;

      // Create CSV header
      String csv =
          'Order ID,Task Title,Platform,Quantity,Unit Price,Total Price,Status,Date Created\n';

      // Add rows
      for (var order in orders) {
        final orderMap = order as Map<String, dynamic>;
        final id = orderMap['id'] as String;
        final title = (orderMap['task_title'] as String).replaceAll(',', ' ');
        final platform = orderMap['selected_platform'] as String;
        final quantity = orderMap['quantity'] as int;
        final unitPrice = (orderMap['unit_price'] as num).toDouble();
        final totalPrice = (orderMap['total_price'] as num).toDouble();
        final status = orderMap['status'] as String;
        final createdAt =
            DateTime.parse(orderMap['created_at'] as String).toString();

        csv +=
            '$id,"$title",$platform,$quantity,₦$unitPrice,₦$totalPrice,$status,$createdAt\n';
      }

      return csv;
    } catch (e) {
      print('Error exporting orders: $e');
      throw Exception("Failed to export orders: $e");
    }
  }
}

// Helper extension methods that should work with any Supabase version
extension PostgrestFilterBuilderExtensions on PostgrestFilterBuilder {
  PostgrestFilterBuilder maybeEq(String column, dynamic value) {
    if (value != null) {
      return eq(column, value);
    }
    return this;
  }

  PostgrestFilterBuilder maybeGte(String column, dynamic value) {
    if (value != null) {
      return gte(column, value);
    }
    return this;
  }

  PostgrestFilterBuilder maybeLte(String column, dynamic value) {
    if (value != null) {
      return lte(column, value);
    }
    return this;
  }
}
