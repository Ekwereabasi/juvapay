// views/support/ticket_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

// Services
import '../../../services/support_service.dart';

class TicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final SupportService supportService;

  const TicketDetailPage({
    super.key,
    required this.ticket,
    required this.supportService,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isClosing = false;
  String _newMessage = '';
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final ticketId = widget.ticket['id'].toString();
      final messages = await widget.supportService.getTicketMessages(ticketId);
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError('Failed to load messages');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final ticketId = widget.ticket['id'].toString();
      await widget.supportService.markMessagesAsRead(ticketId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final ticketId = widget.ticket['id'].toString();
      
      _realtimeChannel = Supabase.instance.client.channel('ticket_$ticketId');
      
      _realtimeChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'support_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'ticket_id',
              value: ticketId,
            ),
            callback: (payload) {
              debugPrint('New message received: ${payload.eventType}');
              if (mounted) {
                _loadMessages();
                _markMessagesAsRead();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up realtime: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    final messageText = _messageController.text.trim();

    try {
      final ticketId = widget.ticket['id'].toString();
      await widget.supportService.sendMessage(
        ticketId: ticketId,
        message: messageText,
      );

      _messageController.clear();
      _newMessage = '';
      await _loadMessages();
      _messageFocusNode.requestFocus();
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _closeTicket() async {
    setState(() => _isClosing = true);

    try {
      final ticketId = widget.ticket['id'].toString();
      await widget.supportService.closeTicket(ticketId);
      
      _showSuccess('Ticket closed successfully');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to close ticket: $e');
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }

  Future<void> _reopenTicket() async {
    try {
      final ticketId = widget.ticket['id'].toString();
      await widget.supportService.reopenTicket(ticketId);
      
      _showSuccess('Ticket reopened');
      await _loadMessages();
    } catch (e) {
      _showError('Failed to reopen ticket: $e');
    }
  }

  Future<void> _callSupport() async {
    final phone = 'tel:+2348012345678';
    if (await canLaunchUrl(Uri.parse(phone))) {
      await launchUrl(Uri.parse(phone));
    } else {
      _showError('Could not launch phone dialer');
    }
  }

  Future<void> _openWhatsApp() async {
    final user = Supabase.instance.client.auth.currentUser;
    final message = WhatsAppSupportService.generateSupportRequest(
      name: user?.email ?? 'User',
      issue: widget.ticket['title']?.toString() ?? 'Ticket',
      orderId: widget.ticket['id']?.toString(),
      department: widget.ticket['category']?.toString() ?? 'general',
    );

    if (await canLaunchUrl(Uri.parse(message))) {
      await launchUrl(Uri.parse(message));
    } else {
      _showError('Could not launch WhatsApp');
    }
  }

  Future<void> _openEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    final subject = 'Re: Ticket #${widget.ticket['id'].toString().substring(0, 8)} - ${widget.ticket['title']}';
    final body = '''
Hello Support Team,

Regarding my ticket: ${widget.ticket['title']}
Ticket ID: ${widget.ticket['id']}
User: ${user?.email}

Additional Information:
''';

    final email = 'mailto:support@JuvaPay.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    } else {
      _showError('Could not launch email client');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final theme = Theme.of(context);
    switch (status) {
      case 'open':
        return const Color(0xFFFF9800); // Warning color
      case 'in_progress':
        return theme.primaryColor;
      case 'resolved':
        return const Color(0xFF4CAF50); // Success color
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.mark_email_unread_outlined;
      case 'in_progress':
        return Icons.hourglass_top;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'closed':
        return Icons.archive_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'Just now';

    try {
      final date = DateTime.parse(time);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  String _formatDateTime(String? time) {
    if (time == null || time.isEmpty) return '';

    try {
      final date = DateTime.parse(time);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final status = widget.ticket['status']?.toString() ?? 'open';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket #${widget.ticket['id'].toString().substring(0, 8)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.ticket['title']?.toString() ?? 'No Title',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.hintColor),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Chat on WhatsApp'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'email',
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Send Email'),
                      ],
                    ),
                  ),
                  if (status == 'open' || status == 'in_progress')
                    PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          const Text('Mark as Resolved'),
                        ],
                      ),
                    ),
                  if (status == 'closed' || status == 'resolved')
                    PopupMenuItem(
                      value: 'reopen',
                      child: Row(
                        children: [
                          Icon(Icons.restore, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          const Text('Reopen Ticket'),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'whatsapp':
                      _openWhatsApp();
                      break;
                    case 'email':
                      _openEmail();
                      break;
                    case 'close':
                      _closeTicket();
                      break;
                    case 'reopen':
                      _reopenTicket();
                      break;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildTag(
                text: (widget.ticket['category'] ?? 'general').toString().toUpperCase(),
                color: Colors.blue,
              ),
              _buildTag(
                text: (widget.ticket['priority'] ?? 'medium').toString().toUpperCase(),
                color: widget.ticket['priority'] == 'urgent' ? Colors.red : Colors.orange,
              ),
              _buildTag(
                text: status.toUpperCase(),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(
                'Created: ${_formatDateTime(widget.ticket['created_at']?.toString())}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.hintColor,
                ),
              ),
              if (widget.ticket['updated_at'] != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.update_outlined, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${_formatTime(widget.ticket['updated_at']?.toString())}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ],
          ),
          if (widget.ticket['description'] != null && widget.ticket['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.ticket['description'].toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final isUser = message['sender_type'] == 'user';
    final isSystem = message['sender_type'] == 'system';
    final messageText = message['message']?.toString() ?? '';
    final timestamp = message['created_at']?.toString() ?? '';
    final isRead = message['is_read'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && !isSystem)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  Icons.support_agent,
                  size: 16,
                  color: Colors.green.shade600,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isSystem && !isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      'Support Agent',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSystem
                        ? Colors.amber.shade50
                        : isUser
                            ? theme.primaryColor
                            : theme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 12 : 4),
                      topRight: Radius.circular(isUser ? 4 : 12),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSystem)
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'System',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        messageText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isSystem
                              ? Colors.amber.shade900
                              : isUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isSystem
                                  ? Colors.amber.shade700
                                  : isUser
                                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                      : theme.hintColor,
                            ),
                          ),
                          if (isUser && isRead) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.done_all, size: 12, color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.person_outline, size: 16, color: theme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    final status = widget.ticket['status']?.toString() ?? 'open';
    final isActive = status == 'open' || status == 'in_progress';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _callSupport,
              icon: const Icon(Icons.phone_outlined, size: 16, color: Colors.green),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.green.shade300),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(FontAwesomeIcons.whatsapp, size: 16, color: Color(0xFF25D366)),
              label: const Text('WhatsApp'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: const Color(0xFF25D366).withOpacity(0.3)),
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isClosing ? null : _closeTicket,
                icon: _isClosing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check, size: 16),
                label: _isClosing ? const Text('Closing...') : const Text('Resolve'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline, color: theme.primaryColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Start the conversation',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to get help with your issue',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _messageFocusNode.requestFocus();
              },
              icon: const Icon(Icons.message_outlined, size: 18),
              label: const Text('Type a message'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        final isUser = index % 3 == 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.cardColor,
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUser ? theme.cardColor : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.ticket['status']?.toString() ?? 'open';
    final isActive = status == 'open' || status == 'in_progress';

    return Scaffold(
      backgroundColor: theme.cardColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            Navigator.pop(context, _messages.isNotEmpty);
          },
        ),
        title: Text(
          'Ticket Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.download_outlined, color: theme.hintColor),
              onPressed: () {
                // TODO: Implement export conversation
              },
              tooltip: 'Export Conversation',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: theme.primaryColor),
                      ),
                    ),
                  )
                else if (_messages.isEmpty)
                  SliverFillRemaining(child: _buildEmptyChat())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildMessageBubble(_messages[index]),
                        childCount: _messages.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isActive) ...[
            _buildQuickActions(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _messageFocusNode,
                              onChanged: (value) => setState(() => _newMessage = value.trim()),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: GoogleFonts.inter(color: theme.hintColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 3,
                              minLines: 1,
                              style: TextStyle(color: theme.colorScheme.onSurface),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          if (_newMessage.isNotEmpty)
                            IconButton(
                              onPressed: _isSending ? null : _sendMessage,
                              icon: _isSending
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.primaryColor,
                                      ),
                                    )
                                  : Icon(Icons.send_rounded, color: theme.primaryColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Center(
                child: Text(
                  'This ticket is ${status.toUpperCase()}. To reopen, use the menu in the header.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}