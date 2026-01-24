// views/support/support_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
import '../../../services/support_service.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage>
    with SingleTickerProviderStateMixin {
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
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load data individually to avoid type issues with Future.wait
      final faqsResult = await _supportService.getFAQs(
        category: _selectedCategory,
      );
      final ticketsResult = await _supportService.getUserTickets();
      final statsResult = await _supportService.getTicketStats();
      final categoriesResult = await _supportService.getFAQCategories();

      if (mounted) {
        setState(() {
          // Cast to proper types
          _faqs = (faqsResult as List).cast<Map<String, dynamic>>();
          _userTickets = (ticketsResult as List).cast<Map<String, dynamic>>();
          _stats = (statsResult as Map).cast<String, dynamic>();
          _categories = (categoriesResult as List).cast<String>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError('Failed to load support data: $e');
    }
  }

  void _setupRealtimeSubscription() {
    _supportService.getUnreadMessagesCount().then((count) {
      // You can show a badge or notification here
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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

      // Reload data
      await _loadData();

      // Switch to tickets tab
      _tabController.animateTo(1);

      // Close dialog
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to create ticket: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreatingTicket = false);
      }
    }
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create Support Ticket'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Brief description of your issue',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedTicketCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text('General Inquiry'),
                      ),
                      DropdownMenuItem(
                        value: 'technical',
                        child: Text('Technical Issue'),
                      ),
                      DropdownMenuItem(
                        value: 'billing',
                        child: Text('Billing/Payment'),
                      ),
                      DropdownMenuItem(
                        value: 'account',
                        child: Text('Account Issue'),
                      ),
                      DropdownMenuItem(
                        value: 'refund',
                        child: Text('Refund Request'),
                      ),
                      DropdownMenuItem(value: 'bug', child: Text('Bug Report')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTicketCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPriority = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Detailed description of your issue',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    maxLength: 1000,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isCreatingTicket ? null : _createNewTicket,
                child:
                    _isCreatingTicket
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Create Ticket'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Support Stats',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Chip(
                  label: Text(
                    '${_stats['response_rate'] ?? 100}% Response Rate',
                    style: TextStyle(color: Colors.green),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildStatItem('Total', _stats['total'] ?? 0, Colors.blue),
                _buildStatItem('Open', _stats['open'] ?? 0, Colors.orange),
                _buildStatItem(
                  'In Progress',
                  _stats['in_progress'] ?? 0,
                  Colors.purple,
                ),
                _buildStatItem(
                  'Resolved',
                  _stats['resolved'] ?? 0,
                  Colors.green,
                ),
                _buildStatItem('Closed', _stats['closed'] ?? 0, Colors.grey),
                _buildStatItem('Avg. Response', '2h', Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOptions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Options',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildContactCard(
                  icon: FontAwesomeIcons.whatsapp,
                  title: 'WhatsApp',
                  subtitle: 'Instant chat support',
                  color: const Color(0xFF25D366),
                  onTap: () => _launchWhatsApp(),
                ),
                _buildContactCard(
                  icon: FontAwesomeIcons.envelope,
                  title: 'Email',
                  subtitle: 'support@JuvaPay.com',
                  color: Colors.blue,
                  onTap: () => _launchEmail(),
                ),
                _buildContactCard(
                  icon: FontAwesomeIcons.phone,
                  title: 'Phone',
                  subtitle: '+234 801 234 5678',
                  color: Colors.green,
                  onTap: () => _launchPhoneCall(),
                ),
                _buildContactCard(
                  icon: FontAwesomeIcons.telegram,
                  title: 'Telegram',
                  subtitle: '@JuvaPay_support',
                  color: const Color(0xFF0088CC),
                  onTap: () => _launchTelegram(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
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
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final filteredFaqs =
        _searchQuery.isEmpty
            ? _faqs
            : _faqs.where((faq) {
              final question = faq['question'].toString().toLowerCase();
              final answer = faq['answer'].toString().toLowerCase();
              final query = _searchQuery.toLowerCase();
              return question.contains(query) || answer.contains(query);
            }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search FAQs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                _categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.toUpperCase()),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                        _loadData();
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color:
                            _selectedCategory == category
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (filteredFaqs.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('No FAQs found'),
              ],
            ),
          )
        else
          ...filteredFaqs.map((faq) => _buildFAQItem(faq)),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['answer'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _rateFAQ(faq['id'].toString(), true),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: Text('Helpful (${faq['helpful_count'] ?? 0})'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _rateFAQ(faq['id'].toString(), false),
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: Text(
                        'Not Helpful (${faq['unhelpful_count'] ?? 0})',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
    if (_userTickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No support tickets yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first ticket to get help',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _userTickets.length,
      itemBuilder: (context, index) {
        final ticket = _userTickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    // Safely extract messages
    final messagesRaw = ticket['support_messages'];
    List<Map<String, dynamic>> messages = [];
    if (messagesRaw is List) {
      messages = messagesRaw.cast<Map<String, dynamic>>();
    }

    final lastMessage = messages.isNotEmpty ? messages.last : null;

    // Safely extract agent
    Map<String, dynamic>? agent;
    final agentsRaw = ticket['support_agents'];
    if (agentsRaw is List && agentsRaw.isNotEmpty) {
      final agentData = agentsRaw[0];
      if (agentData is Map) {
        agent = Map<String, dynamic>.from(agentData);
      }
    }

    Color statusColor;
    switch (ticket['status']) {
      case 'open':
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket['title']?.toString() ?? 'No Title',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    (ticket['status']?.toString() ?? 'unknown').toUpperCase(),
                    style: TextStyle(fontSize: 10, color: statusColor),
                  ),
                  backgroundColor: statusColor.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  (ticket['category']?.toString() ?? 'general').toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Icon(Icons.priority_high, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  (ticket['priority']?.toString() ?? 'medium').toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (agent != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(Icons.person, size: 14, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent['full_name']?.toString() ?? 'Support Agent',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        agent['department']?.toString() ?? 'General Support',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            if (lastMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          lastMessage['sender_type'] == 'user'
                              ? Icons.person
                              : Icons.support_agent,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lastMessage['sender_type'] == 'user'
                              ? 'You'
                              : 'Support',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(lastMessage['created_at']?.toString()),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage['message']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTicketDetails(ticket),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('View Conversation'),
                  ),
                ),
                const SizedBox(width: 8),
                if (ticket['status'] == 'open' ||
                    ticket['status'] == 'in_progress')
                  IconButton(
                    onPressed: () => _closeTicket(ticket['id'].toString()),
                    icon: const Icon(Icons.check, size: 20),
                    tooltip: 'Mark as resolved',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _rateFAQ(String faqId, bool isHelpful) async {
    try {
      await _supportService.rateFAQ(faqId: faqId, isHelpful: isHelpful);
      _showSuccess(
        isHelpful
            ? 'Thanks for your feedback!'
            : 'Sorry it wasn'
                't helpful',
      );
      await _loadData();
    } catch (e) {
      _showError('Failed to submit feedback: $e');
    }
  }

  void _viewTicketDetails(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TicketDetailPage(ticket: ticket)),
    );
  }

  void _closeTicket(String ticketId) async {
    try {
      await _supportService.closeTicket(ticketId);
      _showSuccess('Ticket closed successfully');
      await _loadData();
    } catch (e) {
      _showError('Failed to close ticket: $e');
    }
  }

  void _launchWhatsApp() async {
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

  void _launchEmail() async {
    final email =
        'mailto:support@JuvaPay.com?subject=Support%20Request&body=Hello%20Support%20Team,';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    } else {
      _showError('Could not launch email client');
    }
  }

  void _launchPhoneCall() async {
    final phone = 'tel:+2348012345678';
    if (await canLaunchUrl(Uri.parse(phone))) {
      await launchUrl(Uri.parse(phone));
    } else {
      _showError('Could not launch phone dialer');
    }
  }

  void _launchTelegram() async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTicketDialog,
            tooltip: 'Create New Ticket',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.help), text: 'FAQ'),
            Tab(icon: Icon(Icons.support_agent), text: 'My Tickets'),
            Tab(icon: Icon(Icons.contact_support), text: 'Contact'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 20),
                        _buildFAQSection(),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 20),
                        _buildTicketsList(),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 20),
                        _buildContactOptions(),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Business Hours',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const ListTile(
                                  leading: Icon(
                                    Icons.access_time,
                                    color: Colors.blue,
                                  ),
                                  title: Text('Monday - Friday'),
                                  subtitle: Text('9:00 AM - 6:00 PM (WAT)'),
                                ),
                                const ListTile(
                                  leading: Icon(
                                    Icons.access_time,
                                    color: Colors.blue,
                                  ),
                                  title: Text('Saturday'),
                                  subtitle: Text('10:00 AM - 4:00 PM (WAT)'),
                                ),
                                const ListTile(
                                  leading: Icon(
                                    Icons.access_time,
                                    color: Colors.blue,
                                  ),
                                  title: Text('Sunday'),
                                  subtitle: Text('Emergency Support Only'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      floatingActionButton:
          _tabController.index == 1
              ? FloatingActionButton.extended(
                onPressed: _showCreateTicketDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Ticket'),
              )
              : null,
    );
  }
}

// Ticket Detail Page
class TicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailPage({super.key, required this.ticket});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final SupportService _supportService = SupportService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
  }

  Future<void> _loadMessages() async {
    try {
      // Get ticket messages directly from the ticket data or fetch fresh
      final messagesRaw = widget.ticket['support_messages'];
      if (messagesRaw is List) {
        setState(() {
          _messages = messagesRaw.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        // Fallback: try to fetch from service
        final ticketId = widget.ticket['id'].toString();
        final response = await _supportService.getTicketMessages(ticketId);
        setState(() {
          _messages = response;
          _isLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    final ticketId = widget.ticket['id'].toString();
    await _supportService.markMessagesAsRead(ticketId);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    try {
      final ticketId = widget.ticket['id'].toString();
      await _supportService.sendMessage(
        ticketId: ticketId,
        message: _messageController.text,
      );

      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket['title']?.toString() ?? 'Ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              final phone = 'tel:+2348012345678';
              launchUrl(Uri.parse(phone));
            },
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.whatsapp),
            onPressed: () {
              final message = WhatsAppSupportService.generateSupportRequest(
                name:
                    Supabase.instance.client.auth.currentUser?.email ?? 'User',
                issue: widget.ticket['title']?.toString() ?? 'Ticket',
                department: widget.ticket['category']?.toString() ?? 'general',
              );
              launchUrl(Uri.parse(message));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message['sender_type'] == 'user';
                        return _buildMessageBubble(message, isUser, theme);
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isUser,
    ThemeData theme,
  ) {
    final senderType = message['sender_type']?.toString() ?? 'user';
    final messageText = message['message']?.toString() ?? '';
    final timestamp = message['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(
                senderType == 'system' ? Icons.info : Icons.support_agent,
                size: 16,
                color: Colors.blue,
              ),
            ),
          Expanded(
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? theme.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser)
                      Text(
                        senderType == 'system' ? 'System' : 'Support',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUser ? Colors.white : Colors.blue,
                        ),
                      ),
                    Text(
                      messageText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: const Icon(Icons.person, size: 16, color: Colors.blue),
            ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';

    try {
      final date = DateTime.parse(time);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
