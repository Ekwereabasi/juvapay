import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:juvapay/utils/platform_helper.dart';
import 'package:juvapay/services/task_service.dart';
import 'upload_proof_screen.dart';

class TaskExecutionScreen extends StatefulWidget {
  final Map<String, dynamic> taskData; // Updated to use new task structure

  const TaskExecutionScreen({super.key, required this.taskData});

  @override
  State<TaskExecutionScreen> createState() => _TaskExecutionScreenState();
}

class _TaskExecutionScreenState extends State<TaskExecutionScreen> {
  final TaskService _taskService = TaskService();
  Timer? _timer;
  Duration _timeLeft = const Duration(
    hours: 24,
  ); // Default 24 hours for new system
  bool _isLoading = false;
  bool _isFetchingTaskDetails = false;
  bool _isDownloadingImage = false;
  String? _assignmentId;
  String? _queueId;
  late Map<String, dynamic> _taskData;

  @override
  void initState() {
    super.initState();
    _taskData = Map<String, dynamic>.from(widget.taskData);
    _initializeTaskData();
    _initializeTimer();
    _fetchLatestTaskDetails();

    // Debug print to see what data we have
    debugPrint('Task data keys: ${_taskData.keys.toList()}');
    debugPrint('Assignment ID: ${_taskData['assignment_id']}');
    debugPrint('Queue ID: ${_taskData['queue_id']}');
  }

  void _initializeTaskData() {
    // Extract data from task structure
    _assignmentId = _taskData['assignment_id']?.toString();
    _queueId = _taskData['queue_id']?.toString();

    // If assignment_id is not in the main map, check nested structures
    if (_assignmentId == null) {
      // Check if assignment_id is in a nested result field
      if (_taskData.containsKey('result') && _taskData['result'] is Map) {
        _assignmentId = _taskData['result']['assignment_id']?.toString();
      }
    }

    debugPrint('Final Assignment ID: $_assignmentId');
    debugPrint('Final Queue ID: $_queueId');

    // Set time based on task requirements
    if (_taskData.containsKey('expires_at')) {
      try {
        final expiresAt = DateTime.parse(_taskData['expires_at'].toString());
        final now = DateTime.now();
        if (expiresAt.isAfter(now)) {
          _timeLeft = expiresAt.difference(now);
        }
      } catch (e) {
        debugPrint('Error parsing expires_at: $e');
      }
    } else if (_taskData.containsKey('estimated_time')) {
      final minutes = _taskData['estimated_time'] as int? ?? 1440;
      _timeLeft = Duration(minutes: minutes);
    }
  }

  Future<void> _fetchLatestTaskDetails() async {
    if (_isFetchingTaskDetails) return;
    if (_assignmentId == null && _queueId == null) return;

    setState(() => _isFetchingTaskDetails = true);

    try {
      final Map<String, dynamic>? taskDetails = await _loadTaskDetailsFromDb();
      if (!mounted || taskDetails == null) return;

      setState(() {
        _taskData = {..._taskData, ...taskDetails};
        _initializeTaskData();
      });
    } catch (e) {
      debugPrint('Failed to fetch latest task details: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingTaskDetails = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _loadTaskDetailsFromDb() async {
    return _taskService.getTaskExecutionDetails(
      assignmentId: _assignmentId,
      queueId: _queueId,
      fallbackTaskData: _taskData,
    );
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') {
        return text;
      }
    }
    return null;
  }

  Map<String, dynamic> _taskMetadata() {
    final metadata = _taskData['metadata'];
    if (metadata is Map<String, dynamic>) return metadata;
    if (metadata is String && metadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return {};
  }

  List<String> _collectTaskLinks() {
    final links = <String>{};

    final directLink = _taskData['target_link']?.toString().trim();
    if (directLink != null && directLink.isNotEmpty) {
      links.add(directLink);
    }

    for (final key in [
      'secondary_link',
      'backup_link',
      'profile_link',
      'post_link',
      'link',
    ]) {
      final value = _taskData[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        links.add(value);
      }
    }

    final metadata = _taskMetadata();
    final metadataLinks = metadata['links'];
    if (metadataLinks is List) {
      for (final entry in metadataLinks) {
        final link = entry?.toString().trim();
        if (link != null && link.isNotEmpty) {
          links.add(link);
        }
      }
    }

    for (final key in ['link', 'url', 'target_link']) {
      final value = metadata[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        links.add(value);
      }
    }

    return links.toList();
  }

  Future<void> _downloadTaskImage() async {
    final imageUrl = _taskData['ad_image_url']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      _showSnackBar("No task image available", isError: true);
      return;
    }

    if (_isDownloadingImage) return;
    setState(() => _isDownloadingImage = true);

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      await Gal.putImageBytes(
        response.bodyBytes,
        name: 'juvapay_task_${DateTime.now().millisecondsSinceEpoch}',
        album: 'JuvaPay Tasks',
      );

      _showSnackBar('Task image saved to gallery');
    } catch (e) {
      _showSnackBar('Failed to save image: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isDownloadingImage = false);
      }
    }
  }

  void _initializeTimer() {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    setState(() {
      if (_timeLeft.inSeconds > 0) {
        _timeLeft = _timeLeft - const Duration(seconds: 1);
      } else {
        timer.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Time has expired for this task'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _visitLink() async {
    final String? link = _taskData['target_link']?.toString();
    if (link == null || link.isEmpty) {
      _showSnackBar("No link provided for this task", isError: true);
      return;
    }

    final Uri url;
    try {
      url = Uri.parse(link);
    } catch (e) {
      _showSnackBar("Invalid URL format", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showSnackBar("Could not launch link", isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error launching link: ${e.toString()}", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelTask() async {
    final confirmed = await _showConfirmationDialog(
      context,
      title: "Cancel Task",
      content: "Are you sure you want to cancel this task?",
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement cancel task in new system
      // await _authService.cancelTask(widget.taskData['assignment_id']);

      if (mounted) {
        _showSnackBar("Task cancelled successfully");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to cancel task: ${e.toString()}", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: isError ? theme.colorScheme.error : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  void _navigateToUploadProof() {
    if (_assignmentId == null) {
      _showSnackBar("Task assignment ID is missing", isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UploadProofScreen(
              assignmentId: _assignmentId!,
              taskData: _taskData,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Perform Task",
          style: Theme.of(
            context,
          ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
      ),
      body: _buildBody(theme, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    final platformName =
        _taskData['platform']?.toString().toLowerCase() ?? 'facebook';
    final platformDisplayName = PlatformHelper.getPlatformDisplayName(
      platformName,
    );
    final platformColor = PlatformHelper.getPlatformColor(platformName);
    final platformIcon = PlatformHelper.getPlatformIcon(platformName);
    final payoutAmount =
        (_taskData['payout_amount'] as num?)?.toDouble() ?? 0.0;
    final taskTitle = _taskData['task_title'] ?? 'Social Media Task';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimerSection(theme),
          SizedBox(height: 20),
          _buildPlatformHeader(
            platformName: platformName,
            platformDisplayName: platformDisplayName,
            platformColor: platformColor,
            platformIcon: platformIcon,
            isDark: isDark,
            payoutAmount: payoutAmount,
            taskTitle: taskTitle,
          ),
          SizedBox(height: 20),
          _buildTaskMediaSection(theme),
          SizedBox(height: 20),
          _buildInstructionsSection(theme, platformDisplayName),
          SizedBox(height: 30),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildTimerSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: theme.colorScheme.error, size: 22),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _formatDuration(_timeLeft),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'remaining',
            style: TextStyle(
              color: theme.colorScheme.error.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformHeader({
    required String platformName,
    required String platformDisplayName,
    required Color platformColor,
    required IconData platformIcon,
    required bool isDark,
    required double payoutAmount,
    required String taskTitle,
  }) {
    final iconColor =
        (platformName == 'tiktok' && isDark) ? Colors.black : Colors.white;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                platformColor.withOpacity(0.3),
                platformColor.withOpacity(0.1),
              ],
            ),
          ),
          child: CircleAvatar(
            radius: 38,
            backgroundColor: platformColor,
            child: Icon(platformIcon, color: iconColor, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          taskTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Text(
            'Earn ₦${payoutAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if ((_taskData['target_link']?.toString().trim().isNotEmpty ?? false))
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _visitLink,
            icon: Icon(
              Icons.link,
              color: _isLoading ? Colors.grey : Colors.black,
            ),
            label: Text(
              _isLoading ? "LOADING..." : "VISIT TASK LINK",
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.2),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionsSection(
    ThemeData theme,
    String platformDisplayName,
  ) {
    final instructions = _taskData['instructions'] as List<dynamic>?;
    final adContent = _firstNonEmptyString([
      _taskData['ad_content'],
      _taskData['caption'],
      _taskData['ad_caption'],
    ]);
    final targetUsername = _taskData['target_username']?.toString();

    List<String> defaultInstructions = [
      "Click the 'Visit Task Link' button above to access the content.",
      "Complete the task on $platformDisplayName as instructed.",
      "Take a clear screenshot showing proof of completion.",
      "Click the button below to upload your proof.",
    ];

    final displayInstructions =
        instructions?.map((e) => e.toString()).toList() ?? defaultInstructions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        SizedBox(height: 20),
        Text(
          "Task Instructions:",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 20),
        ...displayInstructions.asMap().entries.map(
          (entry) => _buildStep(entry.key + 1, entry.value, theme),
        ),
        if (adContent != null && adContent.isNotEmpty) ...[
          SizedBox(height: 20),
          Text(
            "Caption / Ad Content:",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(adContent, style: theme.textTheme.bodyMedium),
          ),
        ],
        if (targetUsername != null && targetUsername.isNotEmpty) ...[
          SizedBox(height: 12),
          Text(
            "Target: $targetUsername",
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskMediaSection(ThemeData theme) {
    final imageUrl = _firstNonEmptyString([
      _taskData['ad_image_url'],
      _taskData['ad_image'],
      _taskData['image_url'],
      _taskData['target_image_url'],
    ]);
    final taskLinks = _collectTaskLinks();

    if ((imageUrl == null || imageUrl.isEmpty) && taskLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isFetchingTaskDetails)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            Text(
              "Task Image",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isDownloadingImage ? null : _downloadTaskImage,
              icon: Icon(
                _isDownloadingImage ? Icons.hourglass_top : Icons.download,
              ),
              label: Text(_isDownloadingImage ? 'Saving...' : 'Download Image'),
            ),
          ],
          if (taskLinks.isNotEmpty) ...[
            if (imageUrl != null && imageUrl.isNotEmpty)
              const SizedBox(height: 6),
            Text(
              "Task Links",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...taskLinks.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _openSpecificLink(link),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.primary.withOpacity(0.08),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSpecificLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      _showSnackBar("Invalid URL format", isError: true);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showSnackBar("Could not launch link", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error launching link: ${e.toString()}", isError: true);
    }
  }

  Widget _buildStep(int number, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _navigateToUploadProof,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            "UPLOAD PROOF",
            style: TextStyle(
              color:
                  theme.primaryColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _cancelTask,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            "Cancel Task",
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
