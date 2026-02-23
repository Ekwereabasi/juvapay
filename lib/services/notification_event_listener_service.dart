import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:juvapay/models/enums.dart';
import 'package:juvapay/services/supabase_service.dart';

class NotificationEventListenerService {
  NotificationEventListenerService(this._supabase)
    : _notificationService = SupabaseNotificationService(_supabase);

  final SupabaseClient _supabase;
  final SupabaseNotificationService _notificationService;

  final List<RealtimeChannel> _channels = [];
  final Set<String> _eventKeys = <String>{};
  final Set<String> _ownedTicketIds = <String>{};

  String? _activeUserId;
  StreamSubscription<AuthState>? _authSubscription;

  void initialize() {
    _authSubscription ??= _supabase.auth.onAuthStateChange.listen((event) async {
      final userId = event.session?.user.id;
      if (userId == null) {
        await stop();
        return;
      }

      if (userId == _activeUserId) return;
      await start(userId);
    });

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      unawaited(start(currentUserId));
    }
  }

  Future<void> start(String userId) async {
    await stop(clearAuthListener: false);
    _activeUserId = userId;
    await _refreshOwnedTickets(userId);
    _subscribeTaskAssignments(userId);
    _subscribeAdvertiserOrders(userId);
    _subscribeSupportTickets(userId);
    _subscribeSupportMessages(userId);
    _subscribeMarketplaceProducts(userId);
    _subscribeFinancialTransactions(userId);
    _subscribeAnnouncements(userId);
  }

  Future<void> stop({bool clearAuthListener = true}) async {
    for (final channel in _channels) {
      try {
        await channel.unsubscribe();
      } catch (_) {}
    }
    _channels.clear();
    _eventKeys.clear();
    _ownedTicketIds.clear();
    _activeUserId = null;

    if (clearAuthListener) {
      await _authSubscription?.cancel();
      _authSubscription = null;
    }
  }

  void _subscribeTaskAssignments(String userId) {
    final channel = _supabase.channel('notification_task_assignments_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'task_assignments',
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty) return;
            if (!_belongsToUser(row, userId)) return;

            final status = _lower(_firstText(row, const ['status']));
            if (status == 'assigned') {
              final title = _firstText(row, const ['task_title']) ?? 'New Task Assigned';
              _notifyOnce(
                eventKey:
                    'task_assigned_${_firstText(row, const ['id']) ?? DateTime.now().millisecondsSinceEpoch}',
                userId: userId,
                title: 'New Task Assigned',
                message: '$title has been assigned to you.',
                type: NotificationType.task,
                priority: NotificationPriority.high,
                referenceId: _firstText(row, const ['id']),
                referenceType: 'task_assignment',
                metadata: {'source': 'task_assignments', 'status': status},
              );
            } else if (status == 'rejected') {
              final title = _firstText(row, const ['task_title']) ?? 'A task';
              _notifyOnce(
                eventKey:
                    'task_rejected_${_firstText(row, const ['id']) ?? DateTime.now().millisecondsSinceEpoch}',
                userId: userId,
                title: 'Task Rejected',
                message: '$title was rejected. Please review and try again.',
                type: NotificationType.task,
                priority: NotificationPriority.high,
                referenceId: _firstText(row, const ['id']),
                referenceType: 'task_assignment',
                metadata: {'source': 'task_assignments', 'status': status},
              );
            }
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  void _subscribeAdvertiserOrders(String userId) {
    final channel = _supabase.channel('notification_orders_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'advertiser_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'advertiser_id',
            value: userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty) return;

            final status = _normalizeOrderStatus(_firstText(row, const ['status']));
            if (status != 'completed') return;

            final taskTitle = _firstText(row, const ['task_title', 'title']) ?? 'Your order';
            _notifyOnce(
              eventKey:
                  'order_completed_${_firstText(row, const ['id']) ?? DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              title: 'Order Completed',
              message: '$taskTitle has been completed successfully.',
              type: NotificationType.order,
              priority: NotificationPriority.high,
              referenceId: _firstText(row, const ['id']),
              referenceType: 'advertiser_order',
              metadata: {'source': 'advertiser_orders', 'status': status},
            );
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  void _subscribeSupportTickets(String userId) {
    final channel = _supabase.channel('notification_support_tickets_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final ticketId = _firstText(row, const ['id']);
            if (ticketId != null && ticketId.isNotEmpty) {
              _ownedTicketIds.add(ticketId);
            }
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  void _subscribeSupportMessages(String userId) {
    final channel = _supabase.channel('notification_support_messages_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          callback: (payload) async {
            final row = payload.newRecord;
            if (row.isEmpty) return;

            final senderType = _lower(_firstText(row, const ['sender_type']));
            if (senderType == 'user') return;

            final ticketId = _firstText(row, const ['ticket_id']);
            if (ticketId == null || ticketId.isEmpty) return;

            if (!_ownedTicketIds.contains(ticketId)) {
              final isOwned = await _isTicketOwnedByUser(ticketId, userId);
              if (!isOwned) return;
              _ownedTicketIds.add(ticketId);
            }

            _notifyOnce(
              eventKey: 'ticket_response_${ticketId}_${_firstText(row, const ['id']) ?? DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              title: 'Ticket Response',
              message: 'Support has responded to your ticket.',
              type: NotificationType.support,
              priority: NotificationPriority.high,
              referenceId: ticketId,
              referenceType: 'support_ticket',
              metadata: {'source': 'support_messages'},
            );
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  void _subscribeMarketplaceProducts(String userId) {
    final channel = _supabase.channel('notification_products_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'marketplace_products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty) return;

            final isBanned = _asBool(row['is_banned']);
            if (!isBanned) return;

            final title = _firstText(row, const ['title']) ?? 'Your product';
            final reason = _firstText(row, const ['banned_reason']);
            final message =
                reason == null || reason.isEmpty
                    ? '$title was banned by an admin.'
                    : '$title was banned: $reason';

            _notifyOnce(
              eventKey:
                  'product_banned_${_firstText(row, const ['id']) ?? DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              title: 'Product Banned',
              message: message,
              type: NotificationType.system,
              priority: NotificationPriority.urgent,
              referenceId: _firstText(row, const ['id']),
              referenceType: 'marketplace_product',
              metadata: {'source': 'marketplace_products'},
            );
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  void _subscribeFinancialTransactions(String userId) {
    final channel = _supabase.channel('notification_transactions_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'financial_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty) return;

            final status = _upper(_firstText(row, const ['status']));
            final type = _upper(_firstText(row, const ['transaction_type']));
            if (status != 'COMPLETED') return;
            if (type != 'TASK_EARNING' && type != 'BONUS') return;

            final amountRaw = row['amount'];
            final amount =
                amountRaw is num ? amountRaw.toDouble() : double.tryParse('$amountRaw') ?? 0.0;
            _notifyOnce(
              eventKey:
                  'payout_completed_${_firstText(row, const ['id']) ?? DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              title: 'Payout Received',
              message: 'A payout of N${amount.toStringAsFixed(2)} has been credited to your wallet.',
              type: NotificationType.wallet,
              priority: NotificationPriority.high,
              referenceId: _firstText(row, const ['id']),
              referenceType: 'financial_transaction',
              metadata: {'source': 'financial_transactions', 'transaction_type': type},
            );
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  void _subscribeAnnouncements(String userId) {
    final channel = _supabase.channel('notification_announcements_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty) return;

            final title = _firstText(row, const ['title']) ?? 'General Announcement';
            final body =
                _firstText(row, const ['message', 'content', 'body']) ??
                'A new announcement has been posted.';
            _notifyOnce(
              eventKey:
                  'announcement_${_firstText(row, const ['id']) ?? DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              title: title,
              message: body,
              type: NotificationType.promotion,
              priority: NotificationPriority.medium,
              referenceId: _firstText(row, const ['id']),
              referenceType: 'announcement',
              metadata: {'source': 'announcements'},
            );
          },
        )
        .subscribe();
    _channels.add(channel);
  }

  Future<void> _notifyOnce({
    required String eventKey,
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    required NotificationPriority priority,
    String? referenceId,
    String? referenceType,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (eventKey.isEmpty || _eventKeys.contains(eventKey)) return;
    _eventKeys.add(eventKey);

    try {
      await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        channels: const [NotificationChannel.inApp, NotificationChannel.push],
        referenceId: referenceId,
        referenceType: referenceType,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Failed to create event notification ($eventKey): $e');
    }
  }

  Future<void> _refreshOwnedTickets(String userId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('user_id', userId);

      _ownedTicketIds
        ..clear()
        ..addAll(
          response
              .map<String>((row) => (row['id'] ?? '').toString())
              .where((id) => id.isNotEmpty),
        );
    } catch (e) {
      debugPrint('Failed to load support ticket ids: $e');
    }
  }

  Future<bool> _isTicketOwnedByUser(String ticketId, String userId) async {
    try {
      final row = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('id', ticketId)
          .eq('user_id', userId)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  bool _belongsToUser(Map<String, dynamic> row, String userId) {
    final ids = <String?>[
      _firstText(row, const ['worker_id']),
      _firstText(row, const ['user_id']),
      _firstText(row, const ['assigned_to']),
      _firstText(row, const ['worker_user_id']),
    ];
    return ids.any((id) => id != null && id == userId);
  }

  String? _firstText(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  String _normalizeOrderStatus(String? status) {
    final normalized = _lower(status);
    if (normalized == 'paid' || normalized == 'processing') return 'active';
    if (normalized == 'refunded') return 'cancelled';
    return normalized;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return '$value'.toLowerCase() == 'true';
  }

  String _lower(String? value) => value?.toLowerCase().trim() ?? '';
  String _upper(String? value) => value?.toUpperCase().trim() ?? '';
}
