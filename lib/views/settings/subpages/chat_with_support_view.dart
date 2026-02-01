// views/support/support_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
import '../../../services/support_service.dart';
import '../../../utils/app_themes.dart'; // Add this import
import 'ticket_detail_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final SupportService _supportService = SupportService();
  late TabController _tabController;

  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _userTickets = [];
  Map<String, dynamic> _stats = {};
  String _selectedCategory = 'all';
  List<String> _categories = [];
  bool _isLoading = true;
  bool _isCreatingTicket = false;
  String _searchQuery = '';
  int _unreadMessages = 0;
  Set<String> _userTicketIds = {};
  RealtimeChannel? _realtimeChannel;

  // New ticket form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedPriority = 'medium';
  String _selectedTicketCategory = 'general';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load data in parallel
      final results = await Future.wait([
        _supportService.getFAQs(category: _selectedCategory),
        _supportService.getUserTickets(),
        _supportService.getTicketStats(),
        _supportService.getFAQCategories(),
        _supportService.getUnreadMessagesCount(),
      ], eagerError: true);

      if (mounted) {
        setState(() {
          _faqs = results[0] as List<Map<String, dynamic>>;
          _userTickets = results[1] as List<Map<String, dynamic>>;
          _stats = results[2] as Map<String, dynamic>;
          _categories = results[3] as List<String>;
          _unreadMessages = results[4] as int;
          _userTicketIds = _userTickets
              .map((ticket) => ticket['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load support data');
      }
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Cancel existing subscription
      _realtimeChannel?.unsubscribe();

      // Create new channel for support updates
      _realtimeChannel = Supabase.instance.client.channel('support_updates_${user.id}');

      // Subscribe to ticket updates
      _realtimeChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'support_tickets',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              debugPrint('Ticket update received: ${payload.eventType}');
              if (mounted) _loadData();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'support_messages',
            callback: (payload) {
              // Check if this message belongs to any of user's tickets
              if (payload.newRecord != null) {
                final ticketId = payload.newRecord['ticket_id']?.toString();
                if (_userTicketIds.contains(ticketId)) {
                  debugPrint('Message update for user ticket: $ticketId');
                  if (mounted) _loadData();
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up realtime: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _createNewTicket() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isCreatingTicket = true);

    try {
      await _supportService.createSupportTicket(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedTicketCategory,
        priority: _selectedPriority,
      );

      _showSuccess('Support ticket created successfully!');
      _titleController.clear();
      _descriptionController.clear();

      await _loadData();
      _tabController.animateTo(1);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to create ticket: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreatingTicket = false);
      }
    }
  }

  void _showCreateTicketDialog() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'New Support Ticket',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Brief description of your issue',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.all(16),
                          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                          hintStyle: TextStyle(color: theme.hintColor),
                        ),
                        maxLength: 100,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.cardColor,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            value: _selectedTicketCategory,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'general', child: Text('General Inquiry')),
                              DropdownMenuItem(value: 'technical', child: Text('Technical Issue')),
                              DropdownMenuItem(value: 'billing', child: Text('Billing/Payment')),
                              DropdownMenuItem(value: 'account', child: Text('Account Issue')),
                              DropdownMenuItem(value: 'refund', child: Text('Refund Request')),
                              DropdownMenuItem(value: 'bug', child: Text('Bug Report')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedTicketCategory = value);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            style: GoogleFonts.inter(fontSize: 15, color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.cardColor,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPriority = value);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            style: GoogleFonts.inter(fontSize: 15, color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Detailed description of your issue',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.all(16),
                          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                          hintStyle: TextStyle(color: theme.hintColor),
                        ),
                        maxLines: 5,
                        maxLength: 1000,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCreatingTicket ? null : _createNewTicket,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: theme.primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                        ),
                        child: _isCreatingTicket
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Create Ticket',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Support Analytics',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Badge(
                  backgroundColor: Colors.white,
                  textColor: theme.primaryColor,
                  label: Text('${_stats['response_rate'] ?? 100}%'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatItem('Total', _stats['total'] ?? 0, Icons.inbox, Colors.white),
                _buildStatItem('Open', _stats['open'] ?? 0, Icons.mark_email_unread, Colors.amber),
                _buildStatItem('Progress', _stats['in_progress'] ?? 0, Icons.hourglass_bottom, Colors.blue),
                _buildStatItem('Resolved', _stats['resolved'] ?? 0, Icons.check_circle, Colors.green),
                _buildStatItem('Closed', _stats['closed'] ?? 0, Icons.archive, Colors.grey),
                _buildStatItem('Avg Time', '2h', Icons.access_time, Colors.cyan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOptions() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.contacts, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Contact Options',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildContactCard(
                      icon: FontAwesomeIcons.whatsapp,
                      title: 'WhatsApp',
                      subtitle: 'Instant Chat',
                      color: const Color(0xFF25D366),
                      onTap: _launchWhatsApp,
                    ),
                    _buildContactCard(
                      icon: FontAwesomeIcons.envelope,
                      title: 'Email',
                      subtitle: '24/7 Support',
                      color: Colors.blue,
                      onTap: _launchEmail,
                    ),
                    _buildContactCard(
                      icon: FontAwesomeIcons.phone,
                      title: 'Call Us',
                      subtitle: 'Quick Response',
                      color: Colors.green,
                      onTap: _launchPhoneCall,
                    ),
                    _buildContactCard(
                      icon: FontAwesomeIcons.telegram,
                      title: 'Telegram',
                      subtitle: 'Live Chat',
                      color: const Color(0xFF0088CC),
                      onTap: _launchTelegram,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Business Hours',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBusinessHourItem(
                  'Monday - Friday',
                  '9:00 AM - 6:00 PM (WAT)',
                  Icons.calendar_today,
                ),
                _buildBusinessHourItem(
                  'Saturday',
                  '10:00 AM - 4:00 PM (WAT)',
                  Icons.calendar_today,
                ),
                _buildBusinessHourItem(
                  'Sunday',
                  'Emergency Support Only',
                  Icons.calendar_today,
                  isEmergency: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHourItem(String title, String subtitle, IconData icon, {bool isEmergency = false}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isEmergency ? Colors.red.shade50 : Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEmergency ? Colors.red : Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isEmergency ? Colors.red : theme.hintColor,
        ),
      ),
      trailing: isEmergency
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '24/7',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final theme = Theme.of(context);
    final filteredFaqs = _searchQuery.isEmpty
        ? _faqs
        : _faqs.where((faq) {
            final question = faq['question']?.toString().toLowerCase() ?? '';
            final answer = faq['answer']?.toString().toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return question.contains(query) || answer.contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search FAQs...',
              hintStyle: GoogleFonts.inter(color: theme.hintColor),
              prefixIcon: Icon(Icons.search, color: theme.hintColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    category == 'all' ? 'All' : category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                    _loadData();
                  },
                  selectedColor: theme.primaryColor,
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (filteredFaqs.isEmpty)
          _buildEmptyState(
            icon: Icons.search_off,
            title: 'No FAQs Found',
            subtitle: 'Try a different search term or category',
          )
        else
          ...filteredFaqs.map((faq) => _buildFAQItem(faq)),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: Colors.white, size: 18),
          ),
          title: Text(
            faq['question']?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      faq['answer']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rateFAQ(faq['id'].toString(), true),
                          icon: const Icon(Icons.thumb_up, size: 16),
                          label: Text('Helpful (${faq['helpful_count'] ?? 0})'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rateFAQ(faq['id'].toString(), false),
                          icon: const Icon(Icons.thumb_down, size: 16),
                          label: Text('Not Helpful (${faq['unhelpful_count'] ?? 0})'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    final theme = Theme.of(context);
    if (_userTickets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.support_agent,
        title: 'No Tickets Yet',
        subtitle: 'Create your first support ticket to get help',
        actionText: 'Create Ticket',
        onAction: _showCreateTicketDialog,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userTickets.length,
      itemBuilder: (context, index) => _buildTicketCard(_userTickets[index]),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final theme = Theme.of(context);
    final messagesRaw = ticket['support_messages'];
    List<Map<String, dynamic>> messages = [];
    if (messagesRaw is List) {
      messages = messagesRaw.cast<Map<String, dynamic>>();
    }

    final lastMessage = messages.isNotEmpty ? messages.last : null;
    final unreadCount = messages.where((m) => m['is_read'] == false && m['sender_type'] != 'user').length;

    Map<String, dynamic>? agent;
    final agentsRaw = ticket['support_agents'];
    if (agentsRaw is List && agentsRaw.isNotEmpty) {
      final agentData = agentsRaw[0];
      if (agentData is Map) {
        agent = Map<String, dynamic>.from(agentData);
      }
    }

    Color statusColor;
    IconData statusIcon;
    switch (ticket['status']) {
      case 'open':
        statusColor = const Color(0xFFFF9800); // Warning color
        statusIcon = Icons.mark_email_unread;
        break;
      case 'in_progress':
        statusColor = theme.primaryColor;
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'resolved':
        statusColor = const Color(0xFF4CAF50); // Success color
        statusIcon = Icons.check_circle;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusIcon = Icons.archive;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ticket['title']?.toString() ?? 'No Title',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(
                              (ticket['category']?.toString() ?? 'general').toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                            backgroundColor: Colors.blue.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Chip(
                            label: Text(
                              (ticket['priority']?.toString() ?? 'medium').toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: ticket['priority'] == 'urgent' ? Colors.white : null,
                              ),
                            ),
                            backgroundColor: ticket['priority'] == 'urgent'
                                ? Colors.red
                                : ticket['priority'] == 'high'
                                    ? Colors.orange.shade50
                                    : Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  Badge(
                    label: Text(unreadCount.toString()),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  ),
              ],
            ),
            if (agent != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned to ${agent['full_name']}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            agent['department']?.toString() ?? 'General Support',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      agent['rating']?.toStringAsFixed(1) ?? '5.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (lastMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: lastMessage['sender_type'] == 'user'
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          child: Icon(
                            lastMessage['sender_type'] == 'user'
                                ? Icons.person
                                : Icons.support_agent,
                            size: 12,
                            color: lastMessage['sender_type'] == 'user'
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lastMessage['sender_type'] == 'user' ? 'You' : 'Support',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(lastMessage['created_at']?.toString()),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lastMessage['message']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTicketDetails(ticket),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('View Conversation'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (ticket['status'] == 'open' || ticket['status'] == 'in_progress')
                  ElevatedButton.icon(
                    onPressed: () => _closeTicket(ticket['id'].toString()),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rateFAQ(String faqId, bool isHelpful) async {
    try {
      await _supportService.rateFAQ(faqId: faqId, isHelpful: isHelpful);
      _showSuccess(isHelpful ? 'Thanks for your feedback!' : 'Feedback received');
      await _loadData();
    } catch (e) {
      _showError('Failed to submit feedback');
    }
  }

  void _viewTicketDetails(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailPage(
          ticket: ticket,
          supportService: _supportService,
        ),
      ),
    );
  }

  Future<void> _closeTicket(String ticketId) async {
    try {
      await _supportService.closeTicket(ticketId);
      _showSuccess('Ticket marked as resolved');
      await _loadData();
    } catch (e) {
      _showError('Failed to close ticket');
    }
  }

  Future<void> _launchWhatsApp() async {
    final user = Supabase.instance.client.auth.currentUser;
    final message = WhatsAppSupportService.generateSupportRequest(
      name: user?.email ?? 'User',
      issue: 'General inquiry',
      department: 'general',
    );

    if (await canLaunchUrl(Uri.parse(message))) {
      await launchUrl(Uri.parse(message));
    } else {
      _showError('Could not launch WhatsApp');
    }
  }

  Future<void> _launchEmail() async {
    final email = 'mailto:support@JuvaPay.com?subject=Support%20Request&body=';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    } else {
      _showError('Could not launch email client');
    }
  }

  Future<void> _launchPhoneCall() async {
    final phone = 'tel:+2348012345678';
    if (await canLaunchUrl(Uri.parse(phone))) {
      await launchUrl(Uri.parse(phone));
    } else {
      _showError('Could not launch phone dialer');
    }
  }

  Future<void> _launchTelegram() async {
    final telegram = 'https://t.me/JuvaPay_support';
    if (await canLaunchUrl(Uri.parse(telegram))) {
      await launchUrl(Uri.parse(telegram));
    } else {
      _showError('Could not launch Telegram');
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

  Widget _buildLoadingShimmer() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
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
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Support Center',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_unreadMessages > 0)
            Badge(
              label: Text(_unreadMessages.toString()),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
                onPressed: () {},
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.primaryColor),
            onPressed: _showCreateTicketDialog,
            tooltip: 'Create New Ticket',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.hintColor,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(icon: Icon(Icons.help), text: 'FAQ'),
            Tab(icon: Icon(Icons.support_agent), text: 'My Tickets'),
            Tab(icon: Icon(Icons.contact_support), text: 'Contact'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        _buildFAQSection(),
                      ],
                    ),
                  ),
                ),
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        _buildTicketsList(),
                      ],
                    ),
                  ),
                ),
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: _buildContactOptions(),
                  ),
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showCreateTicketDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Ticket'),
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
            )
          : null,
    );
  }
}