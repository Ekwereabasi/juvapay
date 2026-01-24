// views/advertise/advert_upload_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

import '../../services/task_service.dart';
import '../../models/task_models.dart';
import 'advert_upload_form.dart';
import 'engagement_form_view.dart';
import '../../views/settings/subpages/order/my_orders_view.dart';
import '../../utils/platform_helper.dart';

class AdvertUploadPage extends StatefulWidget {
  const AdvertUploadPage({super.key});

  @override
  State<AdvertUploadPage> createState() => _AdvertUploadPageState();
}

class _AdvertUploadPageState extends State<AdvertUploadPage> {
  final TaskService _taskService = TaskService();
  final List<TaskModel> _allTasks = [];
  final List<TaskModel> _filteredTasks = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  // Static fallback tasks
  final List<TaskModel> _staticTasks = [
    // ADVERT TASKS
    TaskModel(
      id: 'static_advert_1',
      createdAt: DateTime.now(),
      title: 'Get People to Post Your Adverts on their Whatsapp Status',
      price: 100.0,
      description:
          'Get real people to post your Adverts on their whatsapp status. Each person will create two separate status posts with your content and keep it live for 24 hours. Minimum 1000+ contacts per user.',
      platforms: ['whatsapp'],
      iconKey: 'whatsapp',
      category: 'advert',
      difficulty: 'medium',
      estimatedTime: 24,
      tags: ['social', 'marketing', 'viral', 'messaging'],
      sortOrder: 1,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_advert_2',
      createdAt: DateTime.now(),
      title: 'Get People to Post Your Adverts on Facebook',
      price: 150.0,
      description:
          'Get people with at least 1000 active friends or followers EACH on their Facebook Account to post your advert. The post remains for minimum 48 hours with engagement.',
      platforms: ['facebook'],
      iconKey: 'facebook',
      category: 'advert',
      difficulty: 'medium',
      estimatedTime: 48,
      tags: ['social', 'marketing', 'business', 'facebook'],
      sortOrder: 2,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_advert_3',
      createdAt: DateTime.now(),
      title: 'Get People to Post Your Adverts on Instagram',
      price: 150.0,
      description:
          'Get influencers with at least 1000 active followers EACH on their Instagram Account to post your advert as a story or feed post. 24-hour story or permanent feed post.',
      platforms: ['instagram'],
      iconKey: 'instagram',
      category: 'advert',
      difficulty: 'medium',
      estimatedTime: 24,
      tags: ['social', 'visual', 'marketing', 'instagram'],
      sortOrder: 3,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_advert_4',
      createdAt: DateTime.now(),
      title: 'Get People to Post Your Adverts on X (Twitter)',
      price: 150.0,
      description:
          'Get influencers with at least 1000 active followers EACH on their X (Twitter) Account to post your advert. Tweet includes images/videos and stays permanently.',
      platforms: ['x'],
      iconKey: 'x',
      category: 'advert',
      difficulty: 'medium',
      estimatedTime: 24,
      tags: ['social', 'marketing', 'microblogging', 'x'],
      sortOrder: 4,
      isFeatured: false,
      metadata: {},
    ),
    TaskModel(
      id: 'static_advert_5',
      createdAt: DateTime.now(),
      title: 'Get People to Post Your Adverts on Tiktok',
      price: 150.0,
      description:
          'Get verified creators with at least 1000 active followers EACH on their Tiktok Account to post your advert as a video. Video stays permanently on their profile.',
      platforms: ['tiktok'],
      iconKey: 'tiktok',
      category: 'advert',
      difficulty: 'medium',
      estimatedTime: 24,
      tags: ['video', 'marketing', 'viral', 'tiktok'],
      sortOrder: 5,
      isFeatured: false,
      metadata: {},
    ),

    // ENGAGEMENT TASKS
    TaskModel(
      id: 'static_engagement_1',
      createdAt: DateTime.now(),
      title: 'Get Real People to Follow Your Page on Social Media',
      price: 8.0,
      description:
          'Get real, active people to follow your social media pages. You can get any number of followers across Instagram, Twitter, or TikTok. All followers are genuine with active accounts.',
      platforms: ['instagram', 'x', 'tiktok'],
      iconKey: 'follow_user',
      category: 'engagement',
      difficulty: 'easy',
      estimatedTime: 24,
      tags: ['followers', 'growth', 'social', 'engagement'],
      sortOrder: 1,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_2',
      createdAt: DateTime.now(),
      title: 'Get People to Like Your Social Media Posts',
      price: 8.0,
      description:
          'Get real people to like your social media posts. Boost engagement on your content across multiple platforms. Each like comes from an active account, not bots.',
      platforms: ['facebook', 'instagram', 'x', 'tiktok'],
      iconKey: 'like_post',
      category: 'engagement',
      difficulty: 'easy',
      estimatedTime: 12,
      tags: ['likes', 'engagement', 'social', 'reaction'],
      sortOrder: 2,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_3',
      createdAt: DateTime.now(),
      title: 'Get Real People to Like and Follow Your Facebook Business Page',
      price: 8.0,
      description:
          'Get targeted followers for your Facebook Business Page. Each person will like your page and engage with your posts. Perfect for local businesses and brands.',
      platforms: ['facebook'],
      iconKey: 'facebook_blue',
      category: 'engagement',
      difficulty: 'easy',
      estimatedTime: 24,
      tags: ['facebook', 'business', 'page', 'local'],
      sortOrder: 3,
      isFeatured: false,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_4',
      createdAt: DateTime.now(),
      title: 'Get Real People to Follow Your Audiomack Channel',
      price: 20.0,
      description:
          'Get music lovers to follow your Audiomack channel. Perfect for artists, podcasters, and audio creators looking to grow their audience on the platform.',
      platforms: ['audiomack'],
      iconKey: 'audiomack',
      category: 'engagement',
      difficulty: 'medium',
      estimatedTime: 48,
      tags: ['music', 'audio', 'creators', 'audiomack'],
      sortOrder: 4,
      isFeatured: false,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_5',
      createdAt: DateTime.now(),
      title: 'Get Real People to Comment on Your Social Media Posts',
      price: 30.0,
      description:
          'Get real people to leave meaningful comments on your social media posts. We DO NOT allow fake users or generic comments. Each comment is unique and relevant.',
      platforms: ['facebook', 'instagram', 'x', 'tiktok'],
      iconKey: 'comment',
      category: 'engagement',
      difficulty: 'hard',
      estimatedTime: 24,
      tags: ['comments', 'engagement', 'discussion', 'feedback'],
      sortOrder: 5,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_6',
      createdAt: DateTime.now(),
      title: 'Get Real People to Join Your Telegram Group/Channel',
      price: 100.0,
      description:
          'Get targeted members to join your Telegram Group or Channel. Each member is verified and interested in your niche. Perfect for community building.',
      platforms: ['telegram'],
      iconKey: 'telegram',
      category: 'engagement',
      difficulty: 'medium',
      estimatedTime: 48,
      tags: ['telegram', 'community', 'messaging', 'group'],
      sortOrder: 6,
      isFeatured: false,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_7',
      createdAt: DateTime.now(),
      title: 'Get People to Download and Review your app on Apple Store',
      price: 100.0,
      description:
          'Get verified users to download and review your apps on Apple Store. Each user provides genuine reviews and ratings. Perfect for app developers.',
      platforms: ['apple'],
      iconKey: 'apple',
      category: 'engagement',
      difficulty: 'hard',
      estimatedTime: 72,
      tags: ['appstore', 'reviews', 'downloads', 'apple'],
      sortOrder: 7,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_8',
      createdAt: DateTime.now(),
      title: 'Get People to View and Comment on your Youtube Channel and Video',
      price: 50.0,
      description:
          'Get People to View and Comment on your Youtube Channel and Video. The users will watch your video, comment on the video and like the video at the same time thereby increasing your views.',
      platforms: ['youtube'],
      iconKey: 'youtube',
      category: 'engagement',
      difficulty: 'hard',
      estimatedTime: 72,
      tags: ['youtube', 'views', 'video'],
      sortOrder: 8,
      isFeatured: true,
      metadata: {},
    ),
    TaskModel(
      id: 'static_engagement_9',
      createdAt: DateTime.now(),
      title: 'Get People to Download and Review Your App on Googleplay',
      price: 50.0,
      description:
          'Get People to download and review your apps on Google Play Store. You can get any number of people to download and review your app.',
      platforms: ['google_play'],
      iconKey: 'google_play',
      category: 'engagement',
      difficulty: 'hard',
      estimatedTime: 72,
      tags: ['google_play', 'android', 'app'],
      sortOrder: 9,
      isFeatured: true,
      metadata: {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _taskService.getTasksByCategory(
        _selectedIndex == 0 ? 'advert' : 'engagement',
      );

      if (kDebugMode) {
        print('Loaded ${tasks.length} tasks from database');
      }

      setState(() {
        _allTasks.clear();
        _allTasks.addAll(tasks);
        _applyFilter();
      });

      if (tasks.isEmpty) {
        throw Exception("No tasks in DB");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tasks from DB or Empty DB: $e');
        print('Falling back to static tasks');
      }

      setState(() {
        _allTasks.clear();
        final category = _selectedIndex == 0 ? 'advert' : 'engagement';
        _allTasks.addAll(
          _staticTasks.where((task) => task.category == category).toList(),
        );
        _applyFilter();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredTasks.clear();
      _filteredTasks.addAll(_allTasks);
    } else {
      _filteredTasks.clear();
      _filteredTasks.addAll(
        _allTasks.where((task) {
          final query = _searchQuery.toLowerCase();
          final title = task.title.toLowerCase();
          final description = task.description.toLowerCase();

          return title.contains(query) || description.contains(query);
        }).toList(),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  void _onTabChanged(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _searchQuery = '';
      });
      _loadTasks();
    }
  }

  // Helper method to get platform icon with proper Apple icon
  IconData _getPlatformIcon(String platform) {
    if (platform == 'apple') {
      // Use FontAwesomeIcons.apple for Apple platform
      return FontAwesomeIcons.apple;
    }
    return PlatformHelper.getPlatformIcon(platform);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Advertise on Social Media',
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Past Orders Link
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryView(),
                    ),
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'View Past Orders',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabItem(0, 'ADVERT TASKS'),
                _buildTabItem(1, 'ENGAGEMENT TASKS'),
              ],
            ),
          ),

          // Search Bar - FIXED VERSION
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                color: colorScheme.onSurface, // Explicitly set text color
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: GoogleFonts.inter(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
          ),

          // Task Description
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
            ),
            child: Text(
              _selectedIndex == 0
                  ? "Get people with at least 1000 active followers to repost your adverts and perform social tasks on their accounts. Boost your brand visibility across multiple platforms."
                  : "Get real people to perform social media engagement tasks for you. Increase followers, likes, comments, and downloads with genuine user interactions.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.8),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // List Content
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingState(colorScheme)
                    : _filteredTasks.isEmpty
                    ? _buildEmptyState(colorScheme, textTheme)
                    : _buildTaskList(colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color:
                  isSelected
                      ? Colors.white
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(ColorScheme colorScheme, TextTheme textTheme) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _filteredTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTaskCard(_filteredTasks[index], colorScheme, textTheme);
      },
    );
  }

  Widget _buildTaskCard(
    TaskModel task,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final primaryColor = colorScheme.primary;
    final platform =
        task.platforms.isNotEmpty ? task.platforms.first : 'social';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectTask(task),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Platform Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: PlatformHelper.getPlatformColor(
                          platform,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          _getPlatformIcon(
                            platform,
                          ), // UPDATED: Using new helper method
                          size: 28,
                          color: PlatformHelper.getPlatformColor(platform),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              children: [
                                TextSpan(
                                  text: '₦${task.price.toStringAsFixed(0)}',
                                ),
                                TextSpan(
                                  text: ' per ${_getUnitType(task)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  task.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Footer Row
                Row(
                  children: [
                    // Platform Badges
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children:
                            task.platforms.map((platform) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: PlatformHelper.getPlatformColor(
                                    platform,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: PlatformHelper.getPlatformColor(
                                      platform,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getPlatformIcon(
                                        platform,
                                      ), // UPDATED: Using new helper method
                                      size: 12,
                                      color: PlatformHelper.getPlatformColor(
                                        platform,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      PlatformHelper.getPlatformDisplayName(
                                        platform,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: PlatformHelper.getPlatformColor(
                                          platform,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Select Button
                    Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectTask(task),
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: Text(
                              'SELECT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Loading tasks...',
            style: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty
                  ? 'No tasks available in this category'
                  : 'No results found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Check back later for new tasks'
                  : 'Try searching with different keywords',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectTask(TaskModel task) {
    if (task.category == 'advert') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdvertFormPage(task: task)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EngagementFormPage(task: task)),
      );
    }
  }

  String _getUnitType(TaskModel task) {
    final title = task.title.toLowerCase();
    if (title.contains('follow')) return 'Follower';
    if (title.contains('like')) return 'Like';
    if (title.contains('comment')) return 'Comment';
    if (title.contains('subscriber')) return 'Subscriber';
    if (title.contains('view')) return 'View';
    if (title.contains('download')) return 'Download';
    if (title.contains('post') || title.contains('advert')) return 'Post';
    return 'Action';
  }
}
