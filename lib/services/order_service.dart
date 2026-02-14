// services/order_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _platformColumn = 'platform';
  static const String _ordersTable = 'advertiser_orders';

  String _normalizeStatus(String? status) {
    final value = status?.toLowerCase() ?? 'pending';
    if (value == 'paid' || value == 'processing') return 'active';
    if (value == 'refunded') return 'cancelled';
    return value;
  }

  List<String>? _statusFilterValues(String? status) {
    if (status == null || status.isEmpty || status == 'all') return null;
    switch (status.toLowerCase()) {
      case 'active':
        return ['paid', 'processing'];
      case 'cancelled':
        return ['cancelled', 'refunded'];
      default:
        return [status];
    }
  }

  Map<String, dynamic> _mergeTaskCatalog(Map<String, dynamic> order) {
    final taskCatalog = order['task_catalog'] as Map<String, dynamic>?;
    if (taskCatalog == null) return order;

    return {
      ...order,
      'task_title': taskCatalog['title'] ?? order['task_title'],
      'task_category': taskCatalog['category'] ?? order['task_category'],
      'task_description':
          taskCatalog['description'] ?? order['task_description'],
    };
  }

  Map<String, dynamic> _mergeMetadata(Map<String, dynamic> order) {
    final metadata = order['metadata'];
    if (metadata is! Map) return order;
    return {
      ...order,
      if (order['gender'] == null && metadata['gender'] != null)
        'gender': metadata['gender'],
      if (order['religion'] == null && metadata['religion'] != null)
        'religion': metadata['religion'],
      if (order['state_name'] == null && metadata['state'] != null)
        'state_name': metadata['state'],
      if (order['lga_name'] == null && metadata['lga'] != null)
        'lga_name': metadata['lga'],
    };
  }

  Map<String, dynamic> _normalizeOrder(Map<String, dynamic> order) {
    final platform =
        (order['selected_platform'] ?? order[_platformColumn])?.toString();
    return {
      ..._mergeMetadata(_mergeTaskCatalog(order)),
      if (platform != null && platform.isNotEmpty)
        'selected_platform': platform,
      if (order['total_price'] == null && order['total_amount'] != null)
        'total_price': order['total_amount'],
      if (order['caption'] == null && order['ad_content'] != null)
        'caption': order['ad_content'],
      if (order['media_url'] == null && order['ad_image_url'] != null)
        'media_url': order['ad_image_url'],
      if ((order['media_urls'] == null || order['media_urls'] is! List) &&
          order['ad_image_url'] != null)
        'media_urls': [order['ad_image_url']],
      if (order['status'] != null)
        'status': _normalizeStatus(order['status']?.toString()),
    };
  }

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

      final statusValues = _statusFilterValues(status);

      // METHOD 1: Direct query without variable assignment
      final response = await _supabase
          .from(_ordersTable)
          .select('''
            *,
            task_catalog:task_catalog (
              title,
              category,
              description
            ),
            financial_transactions!transaction_id (
              id,
              amount,
              transaction_type,
              status,
              created_at
            )
          ''')
          .eq('advertiser_id', user.id)
          .maybeIn('status', statusValues)
          .maybeEq(
            _platformColumn,
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
          .from(_ordersTable)
          .select('id')
          .eq('advertiser_id', user.id)
          .maybeIn('status', statusValues)
          .maybeEq(
            _platformColumn,
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
              ..._normalizeOrder(order),
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
              .from(_ordersTable)
              .select('''
            *,
            task_catalog:task_catalog (
              title,
              category,
              description
            ),
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
              .eq('advertiser_id', user.id)
              .single();

      return _normalizeOrder(Map<String, dynamic>.from(response));
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
          .from(_ordersTable)
          .select()
          .eq('advertiser_id', user.id);

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
        final status = _normalizeStatus(orderMap['status'] as String?);
        final createdAt = DateTime.parse(orderMap['created_at'] as String);
        final totalPrice =
            (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;

        // Count by status
        switch (status.toLowerCase()) {
          case 'active':
            activeCount++;
            totalSpent += totalPrice;
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
      // Preferred path: server-side cancellation + wallet refund.
      try {
        final rpcResponse = await _supabase.rpc(
          'cancel_and_refund_order',
          params: {'p_order_id': orderId, 'p_reason': 'Order cancelled by user'},
        );

        Map<String, dynamic>? resultRow;
        if (rpcResponse is List && rpcResponse.isNotEmpty) {
          resultRow = Map<String, dynamic>.from(rpcResponse.first as Map);
        } else if (rpcResponse is Map<String, dynamic>) {
          resultRow = rpcResponse;
        }

        if (resultRow != null) {
          final success = resultRow['success'] == true;
          final message =
              resultRow['message']?.toString() ??
              (success ? 'Order cancelled successfully' : 'Failed to cancel');
          final refundAmount = (resultRow['refund_amount'] as num?)?.toDouble();
          return {
            'success': success,
            'message':
                refundAmount != null && refundAmount > 0
                    ? '$message (Refund: ₦${refundAmount.toStringAsFixed(2)})'
                    : message,
            'refund_amount': refundAmount ?? 0.0,
          };
        }
      } catch (_) {
        // Fall through to legacy direct-table path below.
      }

      // Check if order exists and belongs to user
      final orderResponse =
          await _supabase
              .from(_ordersTable)
              .select()
              .eq('id', orderId)
              .eq('advertiser_id', user.id)
              .single();

      final order = Map<String, dynamic>.from(orderResponse);

      final normalizedStatus = _normalizeStatus(order['status']?.toString());
      if (normalizedStatus != 'pending' && normalizedStatus != 'active') {
        return {
          'success': false,
          'message': 'Order cannot be cancelled at this stage',
        };
      }

      // Update order status
      final response =
          await _supabase
              .from(_ordersTable)
              .update({
                'status': 'cancelled',
                'cancelled_at': DateTime.now().toIso8601String(),
              })
              .eq('id', orderId)
              .eq('advertiser_id', user.id)
              .select();

      return {
        'success': true,
        'message':
            'Order cancelled successfully. Refund requires cancel_and_refund_order RPC.',
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
          .from(_ordersTable)
          .select(_platformColumn)
          .eq('advertiser_id', user.id);

      final List<dynamic> responseList = response as List;
      final platforms =
          responseList
              .map((item) => item[_platformColumn] as String?)
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
          .from(_ordersTable)
          .select('''
            *,
            task_catalog:task_catalog (
              title,
              category,
              description
            ),
            financial_transactions!transaction_id (
              id,
              amount,
              transaction_type,
              status,
              created_at
            )
          ''')
          .eq('advertiser_id', user.id)
          .or(
            'task_catalog.title.ilike.%$query%,ad_content.ilike.%$query%,target_username.ilike.%$query%,id.eq.$query',
          )
          .order('created_at', ascending: false)
          .limit(20);

      final orders =
          List<Map<String, dynamic>>.from(
            response as List,
          ).map(_normalizeOrder).toList();

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
      final statusValues = _statusFilterValues(status);
      // Build query in one chain
      final response = await _supabase
          .from(_ordersTable)
          .select('*, task_catalog:task_catalog (title, category, description)')
          .eq('advertiser_id', user.id)
          .maybeIn('status', statusValues)
          .maybeEq(
            _platformColumn,
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
        final merged = _normalizeOrder(orderMap);
        final id = orderMap['id'] as String;
        final title =
            (merged['task_title'] as String? ?? 'Unknown')
                .replaceAll(',', ' ');
        final platformValue =
            (merged['selected_platform'] ?? merged[_platformColumn])
                ?.toString() ??
            '';
        final quantity = orderMap['quantity'] as int;
        final unitPrice = (orderMap['unit_price'] as num).toDouble();
        final totalPrice =
            (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
        final status = _normalizeStatus(orderMap['status'] as String?);
        final createdAt =
            DateTime.parse(orderMap['created_at'] as String).toString();

        csv +=
            '$id,"$title",$platformValue,$quantity,₦$unitPrice,₦$totalPrice,$status,$createdAt\n';
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

  PostgrestFilterBuilder maybeIn(String column, List<dynamic>? values) {
    if (values != null && values.isNotEmpty) {
      return filter(column, 'in', values);
    }
    return this;
  }
}
