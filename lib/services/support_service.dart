// services/support_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  // Get user's support tickets
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
              department
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

  // Get FAQ categories
  Future<List<String>> getFAQCategories() async {
    try {
      final response = await _supabase
          .from('faqs')
          .select('category')
          .eq('is_published', true);

      final categories =
          response
              .map((item) => item['category'].toString())
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList();

      return ['all', ...categories]..sort();
    } catch (e) {
      debugPrint('Error fetching FAQ categories: $e');
      return ['all', 'general', 'billing', 'technical', 'account', 'tasks'];
    }
  }

  // Get FAQs by category
  Future<List<Map<String, dynamic>>> getFAQs({String category = 'all'}) async {
    try {
      var query = _supabase.from('faqs').select().eq('is_published', true);

      if (category != 'all') {
        query = query.match({'category': category});
      }

      final response = await query.order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      return [];
    }
  }

  // Mark FAQ as helpful/unhelpful - FIXED VERSION
  Future<void> rateFAQ({required String faqId, required bool isHelpful}) async {
    try {
      final columnName = isHelpful ? 'helpful_count' : 'unhelpful_count';

      // First, get the current count
      final currentResponse =
          await _supabase
              .from('faqs')
              .select(columnName)
              .eq('id', faqId)
              .single();

      final currentCount = currentResponse[columnName] as int? ?? 0;
      final newCount = currentCount + 1;

      // Update with the new count
      await _supabase
          .from('faqs')
          .update({columnName: newCount})
          .eq('id', faqId);
    } catch (e) {
      debugPrint('Error rating FAQ: $e');
    }
  }

  // Get support agents
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

  // Get ticket statistics
  Future<Map<String, dynamic>> getTicketStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('support_tickets')
          .select('status')
          .eq('user_id', user.id);

      final tickets = List<Map<String, dynamic>>.from(response);
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
        'response_rate':
            total > 0 ? ((total - open) / total * 100).toInt() : 100,
      };
    } catch (e) {
      debugPrint('Error fetching ticket stats: $e');
      return {
        'total': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
        'response_rate': 100,
      };
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

  // Check for unread messages - FIXED VERSION
  Future<int> getUnreadMessagesCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      // First, get the ticket IDs for the current user
      final ticketsResponse = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('user_id', user.id);

      if (ticketsResponse.isEmpty) return 0;

      // Extract ticket IDs
      final ticketIds =
          ticketsResponse.map((ticket) => ticket['id'].toString()).toList();

      // Build OR condition for ticket IDs
      final orConditions = ticketIds.map((id) => 'ticket_id.eq.$id').join(',');

      // Get unread messages for those tickets
      final response = await _supabase
          .from('support_messages')
          .select('id')
          .eq('is_read', false)
          .neq('sender_type', 'user')
          .or(orConditions);

      return response.length;
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
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
              email
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
}

// WhatsApp service for direct contact
class WhatsAppSupportService {
  // Phone numbers for different departments
  static const Map<String, String> departmentNumbers = {
    'technical': '+2348012345678',
    'billing': '+2348012345679',
    'general': '+2348012345680',
    'sales': '+2348012345681',
  };

  // Generate WhatsApp link
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

  // Generate WhatsApp chat with template
  static String generateSupportRequest({
    required String name,
    required String issue,
    String? orderId,
    String department = 'general',
  }) {
    final message = '''
Hello JuvaPay Support,

Name: $name
Issue: $issue
${orderId != null ? 'Order ID: $orderId\n' : ''}
Department: $department

Please assist me with this issue.
''';

    return generateWhatsAppLink(message: message, department: department);
  }

  // Generate order inquiry
  static String generateOrderInquiry({
    required String orderId,
    required String name,
    String department = 'general',
  }) {
    final message = '''
Hello JuvaPay Support,

I have an inquiry about my order.

Name: $name
Order ID: $orderId

Please provide me with an update on this order.
''';

    return generateWhatsAppLink(message: message, department: department);
  }

  // Generate payment issue message
  static String generatePaymentIssue({
    required String name,
    required String issue,
    String? transactionId,
    String department = 'billing',
  }) {
    final message = '''
Hello JuvaPay Billing Department,

I have a payment issue.

Name: $name
Issue: $issue
${transactionId != null ? 'Transaction ID: $transactionId\n' : ''}

Please help resolve this payment issue.
''';

    return generateWhatsAppLink(message: message, department: department);
  }

  // Generate general inquiry message
  static String generateGeneralInquiry({
    required String name,
    required String inquiry,
    String? email,
    String department = 'general',
  }) {
    final message = '''
Hello JuvaPay Support,

I have a general inquiry.

Name: $name
Inquiry: $inquiry
${email != null ? 'Email: $email\n' : ''}
Please assist me with this inquiry.
''';

    return generateWhatsAppLink(message: message, department: department);
  }

  // Generate account issue message
  static String generateAccountIssue({
    required String name,
    required String issue,
    String? username,
    String department = 'technical',
  }) {
    final message = '''
Hello JuvaPay Technical Support,

I have an account issue.

Name: $name
Issue: $issue
${username != null ? 'Username: $username\n' : ''}
Please help resolve this account issue.
''';

    return generateWhatsAppLink(message: message, department: department);
  }
}
