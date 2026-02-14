// worker_task_list_view.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:juvapay/services/task_service.dart';
import 'task_execution_view.dart';
import 'dart:async';

class WorkerTaskListView extends StatefulWidget {
  const WorkerTaskListView({super.key});

  @override
  State<WorkerTaskListView> createState() => _WorkerTaskListViewState();
}

class _WorkerTaskListViewState extends State<WorkerTaskListView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();
  final TaskService _taskService = TaskService();
  List<Map<String, dynamic>> _availableTasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _loadAvailableTasks();
  }

  Future<void> _loadAvailableTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _authService.getAvailableTasksForWorker(
        platform: _selectedPlatform,
        limit: 20,
      );

      setState(() {
        final seenKeys = <String>{};
        _availableTasks =
            tasks.where((task) {
              final orderId = task['order_id']?.toString();
              final assignmentId = task['assignment_id']?.toString();
              final taskTitle = task['task_title']?.toString();
              final key =
                  (orderId != null && orderId.isNotEmpty)
                      ? 'order:$orderId'
                      : (assignmentId != null && assignmentId.isNotEmpty)
                      ? 'assignment:$assignmentId'
                      : (taskTitle != null && taskTitle.isNotEmpty)
                      ? 'title:$taskTitle'
                      : null;
              if (key == null) {
                return true;
              }
              if (seenKeys.contains(key)) {
                return false;
              }
              seenKeys.add(key);
              return true;
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tasks: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _claimTask(String queueId) async {
    setState(() => _isLoading = true);

    try {
      debugPrint('Attempting to claim task with queueId: $queueId');

      final result = await _authService.claimTask(queueId);

      debugPrint('Claim task result: $result');

      if (result['success'] == true) {
        final assignmentId = result['assignment_id']?.toString();
        final task = _availableTasks.cast<Map<String, dynamic>?>().firstWhere(
          (t) => t?['queue_id']?.toString() == queueId,
          orElse: () => null,
        );

        if (task != null && assignmentId != null && assignmentId.isNotEmpty) {
          final taskData = {
            ...task,
            'assignment_id': assignmentId,
            'status': 'assigned',
          };

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TaskExecutionScreen(taskData: taskData),
            ),
          );
        } else if (assignmentId != null && assignmentId.isNotEmpty) {
          // Fallback for stale list data
          final assignedTask = await _fetchAssignedTask(assignmentId);
          if (assignedTask != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TaskExecutionScreen(taskData: assignedTask),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load task details'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to claim task: invalid assignment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to claim task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error claiming task: $e');
      debugPrint('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        await _loadAvailableTasks(); // Refresh list
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchAssignedTask(String assignmentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      debugPrint('Fetching assigned task for assignmentId: $assignmentId');
      return await _taskService.getTaskExecutionDetails(
        assignmentId: assignmentId,
      );
    } catch (e) {
      debugPrint('Error fetching assigned task: $e');
      return null;
    }
  }

  // Alternative simpler _claimTask method if the above is too complex:
  /*
  Future<void> _claimTask(String queueId) async {
    setState(() => _isLoading = true);

    try {
      debugPrint('Attempting to claim task with queueId: $queueId');

      final result = await _authService.claimTask(queueId);

      debugPrint('Claim task result: $result');

      if (result['success'] == true) {
        // Get the original task data
        final task = _availableTasks.firstWhere(
          (t) => t['queue_id'] == queueId,
        );

        // Merge with assignment data from result
        final taskData = {
          ...task,
          'assignment_id': result['assignment_id'],
          'status': 'claimed',
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskExecutionScreen(taskData: taskData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to claim task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error claiming task: $e');
      debugPrint('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        await _loadAvailableTasks(); // Refresh list
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Available Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Platform Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    decoration: InputDecoration(
                      labelText: 'Filter by Platform',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Platforms'),
                      ),
                      DropdownMenuItem(
                        value: 'facebook',
                        child: Text('Facebook'),
                      ),
                      DropdownMenuItem(
                        value: 'instagram',
                        child: Text('Instagram'),
                      ),
                      DropdownMenuItem(value: 'x', child: Text('X (Twitter)')),
                      DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                      DropdownMenuItem(
                        value: 'whatsapp',
                        child: Text('WhatsApp'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPlatform = value);
                      _loadAvailableTasks();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Task Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_availableTasks.length} tasks available',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadAvailableTasks,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _availableTasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tasks available',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPlatform != null
                                ? 'Try changing platform filter'
                                : 'Check back later for new tasks',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadAvailableTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableTasks.length,
                        itemBuilder: (context, index) {
                          final task = _availableTasks[index];
                          return _buildTaskCard(task, theme);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, ThemeData theme) {
    final platform = task['platform']?.toString() ?? 'social';
    final payout = (task['payout_amount'] as num?)?.toDouble() ?? 0.0;
    final taskTitle = task['task_title']?.toString() ?? 'Social Media Task';
    final queueId = task['queue_id']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPlatformColor(platform).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getPlatformIcon(platform),
                      color: _getPlatformColor(platform),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        platform.toUpperCase(),
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₦${payout.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task['task_description']?.toString() ??
                  'Complete the social media task',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (task['requirements'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task['requirements'].toString(),
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            if (task['expires_at'] != null)
              Row(
                children: [
                  const Icon(Icons.timer, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${_formatExpiry(task['expires_at'])}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: queueId != null ? () => _claimTask(queueId) : null,
                child: const Text('CLAIM TASK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'x':
      case 'twitter':
        return Colors.black;
      case 'tiktok':
        return const Color(0xFF000000);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return Colors.blue;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'x':
      case 'twitter':
        return Icons.alternate_email;
      case 'tiktok':
        return Icons.music_note;
      case 'whatsapp':
        return Icons.chat;
      case 'youtube':
        return Icons.play_circle_filled;
      default:
        return Icons.link;
    }
  }

  String _formatExpiry(dynamic expiresAt) {
    if (expiresAt == null) return 'Soon';
    try {
      final expiry = DateTime.parse(expiresAt.toString());
      final now = DateTime.now();
      final difference = expiry.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ${difference.inHours.remainder(24)}h';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
      } else {
        return '${difference.inMinutes}m';
      }
    } catch (e) {
      return 'Soon';
    }
  }
}
