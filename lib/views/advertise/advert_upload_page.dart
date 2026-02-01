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
import '../../services/supabase_auth_service.dart';

class AdvertUploadPage extends StatefulWidget {
  const AdvertUploadPage({super.key});

  @override
  State<AdvertUploadPage> createState() => _AdvertUploadPageState();
}

class _AdvertUploadPageState extends State<AdvertUploadPage> {
  final TaskService _taskService = TaskService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final List<TaskModel> _allTasks = [];
  final List<TaskModel> _filteredTasks = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  // Static fallback tasks updated with all required tasks
  final List<TaskModel> _staticTasks = [
    // ==================== ADVERT TASKS ====================
    // WhatsApp Task (Main advert task)
    TaskModel(
      id: 'static_advert_whatsapp',
      createdAt: DateTime.now(),
      category: 'advert',
      title: 'Post Your Advert on WhatsApp Status',
      price: 100.0,
      description:
          'Get real people to post your Adverts on their WhatsApp status. Each person will create status posts with your content and keep it live for 24 hours. Minimum 1000+ contacts per user.',
      platforms: ['whatsapp'],
      iconKey: 'whatsapp',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 1,
      isFeatured: true,
      tags: ['social', 'marketing', 'viral', 'messaging', 'whatsapp'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Must keep status for 24 hours',
          'Clear screenshot required',
          'Must have minimum 1000 contacts',
        ],
      },
      minQuantity: 1,
      maxQuantity: 100,
      requirements: [
        'Provide ad content/text',
        'Provide ad image (optional)',
        'Clear instructions',
      ],
      instructions: [
        'Post as status on WhatsApp',
        'Keep for 24 hours',
        'Take screenshot as proof',
      ],
    ),

    // Facebook Advert Post
    TaskModel(
      id: 'static_advert_facebook',
      createdAt: DateTime.now(),
      category: 'advert',
      title: 'Get People to Post Your Advert on Facebook',
      price: 150.0,
      description:
          'Get people with at least 1000 active friends or followers on Facebook to post your advert. The post remains for minimum 48 hours with engagement.',
      platforms: ['facebook'],
      iconKey: 'facebook',
      difficulty: 'medium',
      estimatedTime: 2880, // 48 hours
      status: 'active',
      sortOrder: 2,
      isFeatured: true,
      tags: ['social', 'marketing', 'facebook', 'advertising'],
      metadata: {
        'completion_time': '48 hours',
        'verification_required': true,
        'quality_standards': [
          'Minimum 1000 active followers',
          'Post must remain for 48 hours',
          'Engagement required',
        ],
      },
      minQuantity: 1,
      maxQuantity: 100,
      requirements: [
        'Provide ad content with images/videos',
        'Target audience details',
        'Post duration requirements',
      ],
      instructions: [
        'Create post on Facebook feed',
        'Include all provided media',
        'Engage with comments for 48 hours',
      ],
    ),

    // TikTok Advert Post
    TaskModel(
      id: 'static_advert_tiktok',
      createdAt: DateTime.now(),
      category: 'advert',
      title: 'Get People to Post Your Advert on TikTok',
      price: 150.0,
      description:
          'Get people with at least 1000 active followers on TikTok to post your advert video. The video will be posted and kept for minimum 24 hours.',
      platforms: ['tiktok'],
      iconKey: 'tiktok',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 3,
      isFeatured: true,
      tags: ['video', 'marketing', 'tiktok', 'advertising'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Minimum 1000 active followers',
          'Video must be at least 15 seconds',
          'Engagement required',
        ],
      },
      minQuantity: 1,
      maxQuantity: 100,
      requirements: [
        'Provide video ad content',
        'Target audience details',
        'Video duration requirements',
      ],
      instructions: [
        'Create video post on TikTok',
        'Include all provided media',
        'Engage with comments for 24 hours',
      ],
    ),

    // X (Twitter) Advert Post
    TaskModel(
      id: 'static_advert_x',
      createdAt: DateTime.now(),
      category: 'advert',
      title: 'Get People to Post Your Advert on X',
      price: 150.0,
      description:
          'Get people with at least 1000 active followers on X (formerly Twitter) to post your advert. The tweet will be posted and kept for minimum 48 hours.',
      platforms: ['x'],
      iconKey: 'x',
      difficulty: 'medium',
      estimatedTime: 2880, // 48 hours
      status: 'active',
      sortOrder: 4,
      isFeatured: true,
      tags: ['social', 'marketing', 'twitter', 'x', 'advertising'],
      metadata: {
        'completion_time': '48 hours',
        'verification_required': true,
        'quality_standards': [
          'Minimum 1000 active followers',
          'Tweet must include required hashtags',
          'Engagement required',
        ],
      },
      minQuantity: 1,
      maxQuantity: 100,
      requirements: [
        'Provide ad content with images',
        'Hashtag requirements',
        'Post duration requirements',
      ],
      instructions: [
        'Create tweet on X',
        'Include all provided hashtags',
        'Engage with replies for 48 hours',
      ],
    ),

    // Instagram Advert Post
    TaskModel(
      id: 'static_advert_instagram',
      createdAt: DateTime.now(),
      category: 'advert',
      title: 'Get People to Post Your Advert on Instagram',
      price: 150.0,
      description:
          'Get people with at least 1000 active followers on Instagram to post your advert. The post will be kept for minimum 48 hours with engagement.',
      platforms: ['instagram'],
      iconKey: 'instagram',
      difficulty: 'medium',
      estimatedTime: 2880, // 48 hours
      status: 'active',
      sortOrder: 5,
      isFeatured: true,
      tags: ['social', 'marketing', 'instagram', 'advertising'],
      metadata: {
        'completion_time': '48 hours',
        'verification_required': true,
        'quality_standards': [
          'Minimum 1000 active followers',
          'Post must include required hashtags',
          'Engagement required',
        ],
      },
      minQuantity: 1,
      maxQuantity: 100,
      requirements: [
        'Provide ad content with images/videos',
        'Hashtag requirements',
        'Post duration requirements',
      ],
      instructions: [
        'Create post on Instagram feed',
        'Include all provided hashtags',
        'Engage with comments for 48 hours',
      ],
    ),

    // ==================== ENGAGEMENT TASKS ====================
    // Instagram Followers
    TaskModel(
      id: 'static_engagement_follow',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get People to Follow Your Page on Instagram',
      price: 8.0,
      description:
          'Get real, active people to follow your Instagram page. All followers are genuine with active accounts, ensuring organic growth.',
      platforms: ['instagram'],
      iconKey: 'follow_user',
      difficulty: 'easy',
      estimatedTime: 60, // 1 hour
      status: 'active',
      sortOrder: 1,
      isFeatured: true,
      tags: ['followers', 'growth', 'social', 'engagement', 'instagram'],
      metadata: {
        'completion_time': '1-2 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active followers required',
          'No bot accounts',
        ],
      },
      minQuantity: 10,
      maxQuantity: 5000,
      requirements: ['Provide Instagram username', 'Account must be public'],
      instructions: [
        'Follow the target account',
        'Stay following for at least 7 days',
        'Like 3 recent posts',
      ],
    ),

    // Instagram Likes
    TaskModel(
      id: 'static_engagement_like',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get People to Like Your Instagram Post',
      price: 8.0,
      description:
          'Get real people to like your Instagram post. Increase engagement and visibility with genuine likes from active users.',
      platforms: ['instagram'],
      iconKey: 'like',
      difficulty: 'easy',
      estimatedTime: 60, // 1 hour
      status: 'active',
      sortOrder: 2,
      isFeatured: true,
      tags: ['likes', 'engagement', 'social', 'instagram'],
      metadata: {
        'completion_time': '1 hour',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active accounts required',
          'No bot accounts',
        ],
      },
      minQuantity: 10,
      maxQuantity: 5000,
      requirements: ['Provide the Instagram post link', 'Post must be public'],
      instructions: [
        'Like the specified post',
        'Stay engaged for at least 24 hours',
      ],
    ),

    // Facebook Business Page Follow & Like
    TaskModel(
      id: 'static_engagement_fb_business',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get Real People to Like and Follow Your Facebook Business Page',
      price: 8.0,
      description:
          'Get real people to like and follow your Facebook business page. Boost your page presence with genuine followers.',
      platforms: ['facebook'],
      iconKey: 'facebook',
      difficulty: 'easy',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 3,
      isFeatured: true,
      tags: ['facebook', 'business', 'page', 'follow', 'like'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active accounts required',
          'No bot accounts',
        ],
      },
      minQuantity: 10,
      maxQuantity: 5000,
      requirements: ['Provide Facebook page link', 'Page must be public'],
      instructions: [
        'Like and follow the Facebook page',
        'Stay following for at least 7 days',
      ],
    ),

    // Music Channel Followers
    TaskModel(
      id: 'static_engagement_music',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get People to Follow You on Your Music Channel',
      price: 20.0,
      description:
          'Get real people to follow your music channel on AudioMark, SoundCloud, Spotify, etc. Build your music audience.',
      platforms: ['music'],
      iconKey: 'music',
      difficulty: 'easy',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 4,
      isFeatured: true,
      tags: ['music', 'follow', 'audio', 'soundcloud', 'spotify'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active accounts required',
          'No bot accounts',
        ],
      },
      minQuantity: 10,
      maxQuantity: 5000,
      requirements: ['Provide music channel link', 'Channel must be public'],
      instructions: [
        'Follow the music channel',
        'Stay following for at least 7 days',
      ],
    ),

    // Instagram Comments
    TaskModel(
      id: 'static_engagement_comment',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get Real People to Comment on Your Instagram Post',
      price: 30.0,
      description:
          'Get real people to comment on your Instagram post. Increase engagement with meaningful comments from real users.',
      platforms: ['instagram'],
      iconKey: 'comment',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 5,
      isFeatured: true,
      tags: ['comments', 'engagement', 'social', 'instagram'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Meaningful comments required',
          'No spam comments',
        ],
      },
      minQuantity: 5,
      maxQuantity: 1000,
      requirements: [
        'Provide the Instagram post link',
        'Post must be public',
        'Provide comment guidelines',
      ],
      instructions: [
        'Comment on the specified post',
        'Use meaningful comments',
        'Follow the provided guidelines',
      ],
    ),

    // YouTube Comments
    TaskModel(
      id: 'static_engagement_yt_comment',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get Real People to Comment on Your YouTube Videos',
      price: 50.0,
      description:
          'Get real people to comment on your YouTube channel and videos. Boost engagement and video ranking.',
      platforms: ['youtube'],
      iconKey: 'youtube',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 6,
      isFeatured: true,
      tags: ['youtube', 'comments', 'engagement', 'video'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Meaningful comments required',
          'No spam comments',
        ],
      },
      minQuantity: 5,
      maxQuantity: 1000,
      requirements: [
        'Provide YouTube video link',
        'Video must be public',
        'Provide comment guidelines',
      ],
      instructions: [
        'Watch the video',
        'Leave meaningful comment',
        'Follow the provided guidelines',
      ],
    ),

    // App Review and Download
    TaskModel(
      id: 'static_engagement_app_review',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get Real People to Review and Download Your App',
      price: 50.0,
      description:
          'Get real people to download and review your app on Play Store or App Store. Boost your app ratings and visibility.',
      platforms: ['android', 'ios'],
      iconKey: 'app_store',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 7,
      isFeatured: true,
      tags: ['app', 'review', 'download', 'playstore', 'appstore'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Must download the app',
          'Provide genuine review',
        ],
      },
      minQuantity: 5,
      maxQuantity: 1000,
      requirements: [
        'Provide app store link',
        'App must be publicly available',
        'Provide review guidelines',
      ],
      instructions: [
        'Download the app',
        'Use the app for at least 10 minutes',
        'Leave a review based on guidelines',
      ],
    ),

    // Facebook Share
    TaskModel(
      id: 'static_engagement_fb_share',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get People to Share Your Facebook Post',
      price: 100.0,
      description:
          'Get real people to share your Facebook post. Increase the reach of your post significantly.',
      platforms: ['facebook'],
      iconKey: 'share',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 8,
      isFeatured: true,
      tags: ['facebook', 'share', 'post', 'viral'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active accounts required',
          'No bot accounts',
        ],
      },
      minQuantity: 5,
      maxQuantity: 500,
      requirements: ['Provide the Facebook post link', 'Post must be public'],
      instructions: [
        'Share the specified post',
        'Keep the share for at least 7 days',
      ],
    ),

    // WhatsApp Group Member
    TaskModel(
      id: 'static_engagement_whatsapp_group',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get Real People to Join Your WhatsApp Group',
      price: 100.0,
      description:
          'Get real people to join your WhatsApp group. Build an active community for your brand.',
      platforms: ['whatsapp'],
      iconKey: 'whatsapp',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 9,
      isFeatured: true,
      tags: ['whatsapp', 'group', 'community', 'chat'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active accounts required',
          'No bot accounts',
        ],
      },
      minQuantity: 5,
      maxQuantity: 500,
      requirements: [
        'Provide WhatsApp group invite link',
        'Group must be active',
      ],
      instructions: [
        'Join the WhatsApp group',
        'Stay in the group for at least 7 days',
      ],
    ),

    // Telegram Group/Channel Member
    TaskModel(
      id: 'static_engagement_telegram',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get Real People to Join Your Telegram Group/Channel',
      price: 100.0,
      description:
          'Get real people to join your Telegram group or channel. Build a community for your brand on Telegram.',
      platforms: ['telegram'],
      iconKey: 'telegram',
      difficulty: 'medium',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 10,
      isFeatured: true,
      tags: ['telegram', 'group', 'channel', 'community'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active accounts required',
          'No bot accounts',
        ],
      },
      minQuantity: 5,
      maxQuantity: 500,
      requirements: [
        'Provide Telegram group/channel invite link',
        'Group/channel must be active',
      ],
      instructions: [
        'Join the Telegram group/channel',
        'Stay in the group/channel for at least 7 days',
      ],
    ),

    // YouTube Subscribers
    TaskModel(
      id: 'static_engagement_yt_subscriber',
      createdAt: DateTime.now(),
      category: 'engagement',
      title: 'Get People to Subscribe to Your YouTube Channel',
      price: 50.0,
      description:
          'Get real people to subscribe to your YouTube channel. Boost your subscriber count and channel authority.',
      platforms: ['youtube'],
      iconKey: 'youtube',
      difficulty: 'easy',
      estimatedTime: 1440, // 24 hours
      status: 'active',
      sortOrder: 11,
      isFeatured: true,
      tags: ['youtube', 'subscribe', 'channel', 'video'],
      metadata: {
        'completion_time': '24 hours',
        'verification_required': true,
        'quality_standards': [
          'Real accounts only',
          'Active accounts required',
          'No bot accounts',
        ],
      },
      minQuantity: 10,
      maxQuantity: 5000,
      requirements: ['Provide YouTube channel link', 'Channel must be public'],
      instructions: [
        'Subscribe to the YouTube channel',
        'Stay subscribed for at least 7 days',
      ],
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
          final tags = task.tags.map((t) => t.toLowerCase()).toList();

          return title.contains(query) ||
              description.contains(query) ||
              tags.any((tag) => tag.contains(query));
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
      return FontAwesomeIcons.apple;
    }
    if (platform == 'music') {
      return FontAwesomeIcons.music;
    }
    if (platform == 'app_store') {
      return FontAwesomeIcons.appStore;
    }
    if (platform == 'follow_user') {
      return FontAwesomeIcons.userPlus;
    }
    if (platform == 'like') {
      return FontAwesomeIcons.thumbsUp;
    }
    if (platform == 'comment') {
      return FontAwesomeIcons.comment;
    }
    if (platform == 'share') {
      return FontAwesomeIcons.share;
    }
    return PlatformHelper.getPlatformIcon(platform);
  }

  // Helper method to get platform color for custom platforms
  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'music':
        return Colors.purple;
      case 'app_store':
        return Colors.blue;
      case 'follow_user':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.orange;
      case 'share':
        return Colors.green;
      default:
        return PlatformHelper.getPlatformColor(platform);
    }
  }

  // Helper method to get platform display name for custom platforms
  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'music':
        return 'Music';
      case 'app_store':
        return 'App Store';
      case 'follow_user':
        return 'Follow';
      case 'like':
        return 'Like';
      case 'comment':
        return 'Comment';
      case 'share':
        return 'Share';
      default:
        return PlatformHelper.getPlatformDisplayName(platform);
    }
  }

  Future<void> _selectTask(TaskModel task) async {
    final result = await _showTaskConfigurationDialog(context, task);

    if (result != null) {
      final int quantity = result['quantity'];
      final String platform = result['platform'];

      if (task.category == 'advert') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AdvertFormPage(
                  task: task,
                  quantity: quantity,
                  platform: platform,
                ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => EngagementFormPage(
                  task: task,
                  quantity: quantity,
                  platform: platform,
                ),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showTaskConfigurationDialog(
    BuildContext context,
    TaskModel task,
  ) async {
    int quantity = task.minQuantity;
    String? selectedPlatform =
        task.platforms.isNotEmpty ? task.platforms.first : null;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Configure Order'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity Selection
                    Text(
                      'Quantity:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantity > task.minQuantity) {
                              setState(() => quantity--);
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            '$quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (quantity < task.maxQuantity) {
                              setState(() => quantity++);
                            }
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Min: ${task.minQuantity} | Max: ${task.maxQuantity}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // Platform Selection
                    if (task.platforms.length > 1) ...[
                      Text(
                        'Platform:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            task.platforms.map((platform) {
                              return ChoiceChip(
                                label: Text(_getPlatformDisplayName(platform)),
                                selected: selectedPlatform == platform,
                                onSelected: (selected) {
                                  setState(() => selectedPlatform = platform);
                                },
                              );
                            }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Price Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:'),
                          Text(
                            '₦${(task.price * quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
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
                  onPressed:
                      selectedPlatform != null
                          ? () {
                            Navigator.pop(context, {
                              'quantity': quantity,
                              'platform': selectedPlatform!,
                            });
                          }
                          : null,
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
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
          'Create Social Media Campaign',
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                color: colorScheme.onSurface,
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
                  ? "Get real people to post your adverts on their social media accounts. Boost your brand visibility across multiple platforms with genuine engagement."
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
                        color: _getPlatformColor(platform).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          _getPlatformIcon(platform),
                          size: 28,
                          color: _getPlatformColor(platform),
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
                          if (task.difficulty != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(
                                  task.difficulty!,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getDifficultyColor(
                                    task.difficulty!,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                task.difficulty!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getDifficultyColor(task.difficulty!),
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  color: _getPlatformColor(
                                    platform,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getPlatformColor(
                                      platform,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getPlatformIcon(platform),
                                      size: 12,
                                      color: _getPlatformColor(platform),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getPlatformDisplayName(platform),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _getPlatformColor(platform),
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getUnitType(TaskModel task) {
    final title = task.title.toLowerCase();
    if (title.contains('follow')) return 'Follower';
    if (title.contains('like')) return 'Like';
    if (title.contains('comment')) return 'Comment';
    if (title.contains('subscriber') || title.contains('subscribe'))
      return 'Subscriber';
    if (title.contains('download') || title.contains('review'))
      return 'Download & Review';
    if (title.contains('join')) return 'Member';
    if (title.contains('share')) return 'Share';
    if (title.contains('post') || title.contains('advert')) return 'Post';
    return 'Action';
  }
}
