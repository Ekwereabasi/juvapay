import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/order_service.dart';

class OrderDetailsView extends StatefulWidget {
  final String orderId;

  const OrderDetailsView({super.key, required this.orderId});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  final OrderService _orderService = OrderService();
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  bool _isCancelling = false;
  bool _isSavingMedia = false;
  String _saveStatus = '';

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final order = await _orderService.getOrderById(widget.orderId);
      final activities = await _orderService.getOrderActivity(widget.orderId);

      if (mounted) {
        setState(() {
          _order = order;
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load order details: $e');
      }
    }
  }

  // Save image to gallery using gal package
  Future<void> _saveImageToGallery(String imageUrl) async {
    setState(() {
      _isSavingMedia = true;
      _saveStatus = 'Downloading image...';
    });

    try {
      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      setState(() => _saveStatus = 'Saving to gallery...');

      // Save the image bytes
      final imageBytes = response.bodyBytes;

      // Use gal to save to gallery
      await Gal.putImageBytes(
        imageBytes,
        name:
            'order_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Show success message
      _showSuccess('Image saved to gallery successfully!');
    } catch (e) {
      // Handle gal-specific errors
      if (e.toString().contains('permission')) {
        _showError('Please grant storage permission to save images');
      } else if (e.toString().contains('cancel')) {
        _showError('Save operation was cancelled');
      } else {
        _showError('Failed to save image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMedia = false;
          _saveStatus = '';
        });
      }
    }
  }

  // Alternative method for saving with progress feedback
  Future<void> _saveImageToGalleryWithProgress(String imageUrl) async {
    setState(() {
      _isSavingMedia = true;
      _saveStatus = 'Preparing image...';
    });

    try {
      setState(() => _saveStatus = 'Downloading...');

      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      setState(() => _saveStatus = 'Processing...');

      // Get file extension from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      String? extension;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex > 0) {
          extension = fileName.substring(dotIndex);
        }
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'JuvaPay_Order_${widget.orderId}_$timestamp${extension ?? '.jpg'}';

      setState(() => _saveStatus = 'Saving...');

      // Save to gallery with custom name
      await Gal.putImageBytes(
        response.bodyBytes,
        name: fileName,
        // Optional: Add album name for organization
        album: 'JuvaPay Orders',
      );

      // Show success with details
      _showSaveSuccessDialog(fileName);
    } catch (e) {
      // Handle specific error cases
      String errorMessage;
      if (e is SocketException) {
        errorMessage = 'Network error: Please check your internet connection';
      } else if (e.toString().contains('Permission')) {
        errorMessage =
            'Storage permission required. Please grant permission in settings.';
      } else if (e.toString().contains('cancel')) {
        errorMessage = 'Save operation cancelled';
      } else {
        errorMessage = 'Failed to save image: ${e.toString()}';
      }

      _showError(errorMessage);

      // For permission errors, show how-to guide
      if (e.toString().contains('Permission')) {
        await _showPermissionGuide();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMedia = false;
          _saveStatus = '';
        });
      }
    }
  }

  // Show permission guide dialog
  Future<void> _showPermissionGuide() async {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('To save images, the app needs storage permission.'),
                const SizedBox(height: 12),
                Text(
                  'On Android:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• Go to Settings → Apps → JuvaPay → Permissions'),
                const Text('• Enable Storage permission'),
                const SizedBox(height: 8),
                Text('On iOS:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Go to Settings → JuvaPay → Photos'),
                const Text('• Select "Read and Write" or "Add Photos Only"'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: theme.primaryColor)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Open app settings
                  if (Platform.isAndroid) {
                    await launchUrl(Uri.parse('app-settings:'));
                  } else if (Platform.isIOS) {
                    await launchUrl(Uri.parse('app-settings:'));
                  }
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  // Show success dialog with details
  void _showSaveSuccessDialog(String fileName) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text('Success!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image has been saved to your gallery.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('File:', fileName),
                      _buildInfoRow('Location:', 'Gallery → JuvaPay Orders'),
                      _buildInfoRow(
                        'Time:',
                        DateFormat('hh:mm a').format(DateTime.now()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text(
              'Are you sure you want to cancel this order? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No', style: TextStyle(color: theme.hintColor)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    final result = await _orderService.cancelOrder(widget.orderId);
    if (mounted) setState(() => _isCancelling = false);

    if (result['success'] == true) {
      _showSuccess(result['message']);
      await _loadOrderDetails();
    } else {
      _showError(result['message']);
    }
  }

  Widget _buildInfoRowWidget(
    BuildContext context,
    String label,
    String value, {
    bool isAmount = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: theme.hintColor),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                color:
                    isAmount
                        ? (theme.brightness == Brightness.dark
                            ? Colors.green[400]
                            : Colors.green[700])
                        : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ThemeData theme) {
    if (_order == null) return Container();
    final mediaUrls = _order!['media_urls'] as List<dynamic>? ?? [];
    final mediaUrl = _order!['media_url'] as String?;

    if (mediaUrls.isEmpty && mediaUrl == null) return Container();

    final urls = mediaUrls.isNotEmpty ? mediaUrls.cast<String>() : [mediaUrl!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Media',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            if (_isSavingMedia)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  if (_saveStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _saveStatus,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            itemBuilder: (context, index) {
              final url = urls[index];
              final isVideo =
                  url.toLowerCase().contains('.mp4') ||
                  url.toLowerCase().contains('.mov');

              return GestureDetector(
                onLongPress: () {
                  if (!isVideo) {
                    _showSaveImageDialog(url);
                  }
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            isVideo
                                ? Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: theme.disabledColor.withOpacity(
                                          0.1,
                                        ),
                                        child: const Icon(Icons.broken_image),
                                      ),
                                ),
                      ),
                      if (!isVideo)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.download,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (isVideo)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (!_isSavingMedia &&
            urls.any(
              (url) =>
                  !url.toLowerCase().contains('.mp4') &&
                  !url.toLowerCase().contains('.mov'),
            ))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Long press on images to save to gallery',
              style: GoogleFonts.inter(fontSize: 12, color: theme.hintColor),
            ),
          ),
      ],
    );
  }

  // Show dialog to save image
  void _showSaveImageDialog(String imageUrl) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Text('Save Image', style: theme.textTheme.titleMedium),
            content: Text(
              'Do you want to save this image to your gallery?',
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveImageToGalleryWithProgress(imageUrl);
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Widget _buildActivityTimeline(ThemeData theme) {
    if (_activities.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Activity Timeline',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 16),
        ..._activities.map((activity) {
          final description = activity['description'] as String? ?? 'Activity';
          final createdAt = DateTime.parse(activity['created_at'] as String);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.history, color: theme.primaryColor, size: 20),
            ),
            title: Text(description, style: theme.textTheme.bodyMedium),
            subtitle: Text(
              _dateFormatter.format(createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionSection(BuildContext context) {
    if (_order == null) return Container();
    final theme = Theme.of(context);
    final financialTransactions = _order!['financial_transactions'];

    Map<String, dynamic>? transaction;
    if (financialTransactions is Map<String, dynamic>) {
      transaction = financialTransactions;
    } else if (financialTransactions is List<dynamic> &&
        financialTransactions.isNotEmpty) {
      transaction = financialTransactions.first as Map<String, dynamic>;
    }

    if (transaction == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRowWidget(
                  context,
                  'Transaction ID',
                  transaction['id'] as String? ?? 'N/A',
                ),
                _buildInfoRowWidget(
                  context,
                  'Amount',
                  '₦${(transaction['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                ),
                _buildInfoRowWidget(
                  context,
                  'Type',
                  transaction['transaction_type'] as String? ?? 'N/A',
                ),
                _buildInfoRowWidget(
                  context,
                  'Status',
                  transaction['status'] as String? ?? 'N/A',
                ),
                _buildInfoRowWidget(
                  context,
                  'Reference',
                  transaction['reference_id'] as String? ?? 'N/A',
                ),
                if (transaction['created_at'] != null)
                  _buildInfoRowWidget(
                    context,
                    'Date',
                    _dateFormatter.format(
                      DateTime.parse(transaction['created_at'] as String),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (_order != null &&
              (_order!['status'] == 'pending' || _order!['status'] == 'active'))
            _isCancelling
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
                : IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: _cancelOrder,
                  tooltip: 'Cancel Order',
                ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : _order == null
              ? Center(
                child: Text(
                  'Order not found',
                  style: theme.textTheme.bodyLarge,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _order!['task_title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                        _buildStatusBadge(_order!['status'] as String),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ID: ${_order!['id']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Information',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRowWidget(
                              context,
                              'Platform',
                              _order!['selected_platform'] as String,
                            ),
                            _buildInfoRowWidget(
                              context,
                              'Quantity',
                              _order!['quantity'].toString(),
                            ),
                            _buildInfoRowWidget(
                              context,
                              'Unit Price',
                              '₦${(_order!['unit_price'] as num).toStringAsFixed(2)}',
                            ),
                            _buildInfoRowWidget(
                              context,
                              'Total Amount',
                              '₦${(_order!['total_price'] as num).toStringAsFixed(2)}',
                              isAmount: true,
                            ),
                            _buildInfoRowWidget(
                              context,
                              'Category',
                              _order!['task_category'] as String,
                            ),
                            _buildInfoRowWidget(
                              context,
                              'Date Created',
                              _dateFormatter.format(
                                DateTime.parse(_order!['created_at'] as String),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Targeting',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRowWidget(
                              context,
                              'Gender',
                              _order!['gender'] as String? ?? 'All Gender',
                            ),
                            _buildInfoRowWidget(
                              context,
                              'Religion',
                              _order!['religion'] as String? ?? 'All Religion',
                            ),
                            if (_order!['state_name'] != null)
                              _buildInfoRowWidget(
                                context,
                                'State',
                                _order!['state_name'] as String,
                              ),
                            if (_order!['lga_name'] != null)
                              _buildInfoRowWidget(
                                context,
                                'LGA',
                                _order!['lga_name'] as String,
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (_order!['caption'] != null &&
                        (_order!['caption'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Caption',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _order!['caption'] as String,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    _buildMediaPreview(theme),
                    _buildActivityTimeline(theme),
                    _buildTransactionSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }
}
