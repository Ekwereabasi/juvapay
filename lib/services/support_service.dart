// services/support_service.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  final SupabaseClient _supabase;

  SupportService() : _supabase = Supabase.instance.client;

  // ========== TICKET METHODS ==========

  // Create a new support ticket
  Future<Map<String, dynamic>> createSupportTicket({
    required String title,
    required String description,
    required String category,
    String priority = 'medium',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response =
          await _supabase
              .from('support_tickets')
              .insert({
                'user_id': user.id,
                'title': title,
                'description': description,
                'category': category,
                'priority': priority,
                'status': 'open',
              })
              .select()
              .single();

      // Send initial system message
      await _supabase.from('support_messages').insert({
        'ticket_id': response['id'],
        'sender_id': user.id,
        'sender_type': 'system',
        'message':
            'Ticket created successfully. Our support team will respond shortly.',
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      rethrow;
    }
  }

  // Get user's support tickets with proper joins
  Future<List<Map<String, dynamic>>> getUserTickets() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('support_tickets')
          .select('''
            *,
            support_messages (
              id,
              message,
              sender_type,
              created_at,
              is_read
            ),
            support_agents (
              full_name,
              department,
              rating,
              email
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user tickets: $e');
      return [];
    }
  }

  // Get specific ticket by ID
  Future<Map<String, dynamic>?> getTicketById(String ticketId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase
              .from('support_tickets')
              .select('''
            *,
            support_messages (
              id,
              message,
              sender_type,
              created_at,
              is_read,
              attachments
            ),
            support_agents (
              full_name,
              department,
              email,
              rating
            )
          ''')
              .eq('id', ticketId)
              .eq('user_id', user.id)
              .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching ticket by ID: $e');
      return null;
    }
  }

  // Send message in a ticket
  Future<void> sendMessage({
    required String ticketId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('support_messages').insert({
        'ticket_id': ticketId,
        'sender_id': user.id,
        'sender_type': 'user',
        'message': message,
        'attachments': attachments ?? [],
        'is_read': false,
      });

      // Update ticket updated_at
      await _supabase
          .from('support_tickets')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a specific ticket
  Future<List<Map<String, dynamic>>> getTicketMessages(String ticketId) async {
    try {
      final response = await _supabase
          .from('support_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching ticket messages: $e');
      return [];
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String ticketId) async {
    try {
      await _supabase
          .from('support_messages')
          .update({'is_read': true})
          .eq('ticket_id', ticketId)
          .neq('sender_type', 'user');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Close a ticket
  Future<void> closeTicket(String ticketId) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({
            'status': 'closed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Error closing ticket: $e');
      rethrow;
    }
  }

  // Reopen a ticket
  Future<void> reopenTicket(String ticketId) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({
            'status': 'open',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Error reopening ticket: $e');
      rethrow;
    }
  }

  // ========== FAQ METHODS ==========

  // Get FAQs with optional category filter - FIXED VERSION
  Future<List<Map<String, dynamic>>> getFAQs({String category = 'all'}) async {
    try {
      // Start building the query
      var query = _supabase.from('faqs').select().eq('is_published', true);

      // Apply category filter if not 'all'
      if (category != 'all') {
        query = query.eq('category', category);
      }

      // Add ordering and execute the query
      final response = await query.order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      return [];
    }
  }

  // Get FAQ categories - FIXED VERSION
  Future<List<String>> getFAQCategories() async {
    try {
      // Get distinct categories from published FAQs
      final response = await _supabase
          .from('faqs')
          .select('category')
          .eq('is_published', true)
          .order('category', ascending: true);

      // Extract unique categories
      final categories =
          response
              .map<String>((item) => item['category'] as String)
              .toSet()
              .toList();

      // Add 'all' option at the beginning
      return ['all', ...categories];
    } catch (e) {
      debugPrint('Error fetching FAQ categories: $e');
      return ['all', 'general', 'billing', 'technical', 'account', 'tasks'];
    }
  }

  // Mark FAQ as helpful/unhelpful
  Future<void> rateFAQ({required String faqId, required bool isHelpful}) async {
    try {
      final columnName = isHelpful ? 'helpful_count' : 'unhelpful_count';

      final currentResponse =
          await _supabase
              .from('faqs')
              .select(columnName)
              .eq('id', faqId)
              .single();

      final currentCount = currentResponse[columnName] as int? ?? 0;
      final newCount = currentCount + 1;

      await _supabase
          .from('faqs')
          .update({columnName: newCount})
          .eq('id', faqId);
    } catch (e) {
      debugPrint('Error rating FAQ: $e');
    }
  }

  // ========== STATISTICS & ANALYTICS ==========

  Future<Map<String, dynamic>> getTicketStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return _defaultStats();

      final response = await _supabase
          .from('support_tickets')
          .select('status')
          .eq('user_id', user.id);

      final tickets = List<Map<String, dynamic>>.from(response);
      return _calculateStats(tickets);
    } catch (e) {
      debugPrint('Error fetching ticket stats: $e');
      return _defaultStats();
    }
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> tickets) {
    final total = tickets.length;
    final open = tickets.where((t) => t['status'] == 'open').length;
    final inProgress =
        tickets.where((t) => t['status'] == 'in_progress').length;
    final resolved = tickets.where((t) => t['status'] == 'resolved').length;
    final closed = tickets.where((t) => t['status'] == 'closed').length;

    return {
      'total': total,
      'open': open,
      'in_progress': inProgress,
      'resolved': resolved,
      'closed': closed,
      'response_rate': total > 0 ? ((total - open) / total * 100).toInt() : 100,
    };
  }

  Map<String, dynamic> _defaultStats() => {
    'total': 0,
    'open': 0,
    'in_progress': 0,
    'resolved': 0,
    'closed': 0,
    'response_rate': 100,
  };

  Future<int> getUnreadMessagesCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final ticketsResponse = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('user_id', user.id);

      if (ticketsResponse.isEmpty) return 0;

      final ticketIds =
          ticketsResponse
              .map<String>((ticket) => ticket['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();

      int totalUnread = 0;
      for (final ticketId in ticketIds) {
        final messagesResponse = await _supabase
            .from('support_messages')
            .select('id')
            .eq('ticket_id', ticketId)
            .eq('is_read', false)
            .neq('sender_type', 'user');

        totalUnread += messagesResponse.length;
      }

      return totalUnread;
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
    }
  }

  // ========== SUPPORT AGENTS ==========

  Future<List<Map<String, dynamic>>> getSupportAgents() async {
    try {
      final response = await _supabase
          .from('support_agents')
          .select()
          .eq('is_available', true)
          .order('current_tickets_count', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching support agents: $e');
      return [];
    }
  }

  // ========== REALTIME METHODS ==========

  // Fixed with structured PostgresChangeFilter
  RealtimeChannel setupTicketRealtimeSubscription(String ticketId) {
    return _supabase
        .channel('ticket_$ticketId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ticket_id',
            value: ticketId,
          ),
          callback: (payload) {
            debugPrint('New message received for ticket $ticketId');
          },
        )
        .subscribe();
  }

  // Helper method for loading all data
  Future<Map<String, dynamic>> loadAllData() async {
    try {
      final results = await Future.wait([
        getFAQs(category: 'all'),
        getUserTickets(),
        getTicketStats(),
        getFAQCategories(),
        getUnreadMessagesCount(),
      ]);

      return {
        'faqs': results[0] as List<Map<String, dynamic>>,
        'tickets': results[1] as List<Map<String, dynamic>>,
        'stats': results[2] as Map<String, dynamic>,
        'categories': results[3] as List<String>,
        'unreadCount': results[4] as int,
      };
    } catch (e) {
      debugPrint('Error loading all support data: $e');
      return {
        'faqs': [],
        'tickets': [],
        'stats': _defaultStats(),
        'categories': [
          'all',
          'general',
          'billing',
          'technical',
          'account',
          'tasks',
        ],
        'unreadCount': 0,
      };
    }
  }
}

// WhatsApp service for direct contact
class WhatsAppSupportService {
  static const Map<String, String> departmentNumbers = {
    'technical': '+2348012345678',
    'billing': '+2348012345679',
    'general': '+2348012345680',
    'sales': '+2348012345681',
  };

  static String generateWhatsAppLink({
    required String message,
    String? phone,
    String department = 'general',
  }) {
    final phoneNumber =
        phone ?? departmentNumbers[department] ?? departmentNumbers['general']!;
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$phoneNumber?text=$encodedMessage';
  }

  static String generateSupportRequest({
    required String name,
    required String issue,
    String? orderId,
    String department = 'general',
  }) {
    final message =
        'Hello JuvaPay Support,\n\nName: $name\nIssue: $issue\n${orderId != null ? 'Order ID: $orderId\n' : ''}\nDepartment: $department\n\nPlease assist me with this issue.';
    return generateWhatsAppLink(message: message, department: department);
  }
}
