// views/settings/subpages/order/my_orders_view.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';

import '../../../../services/order_service.dart';
import '../../../../services/wallet_service.dart';
import '../../../../utils/network_messages.dart';
import '../../../../utils/platform_helper.dart';
import 'order_details_view.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  final OrderService _orderService = OrderService();
  final WalletService _walletService = WalletService();
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // State variables
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isExporting = false;
  bool _isOnline = true;
  bool _retryLoading = false;

  // Filter variables
  String _selectedStatus = 'all';
  String _selectedPlatform = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // Pagination
  int _currentPage = 1;
  final int _limit = 15;
  int _totalOrders = 0;
  bool _hasMore = true;

  // Platform options from AdvertUploadPage static tasks
  final List<String> _allPlatforms = [
    'whatsapp',
    'facebook',
    'instagram',
    'x',
    'tiktok',
    'youtube',
    'telegram',
    'audiomack',
    'apple',
    'google_play',
  ];
  List<String> _filteredPlatformOptions = ['all'];

  // Date formatters
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  final DateFormat _timeFormatter = DateFormat('hh:mm a');
  final DateFormat _fullDateFormatter = DateFormat('EEE, dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _initializePlatforms();
    _checkConnectivity();
    _loadInitialData();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _initializePlatforms() {
    _filteredPlatformOptions = ['all', ..._allPlatforms];
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline && _retryLoading) {
        _retryLoading = false;
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (!_isOnline) {
      _showOfflineError();
      return;
    }

    setState(() {
      _isLoading = true;
      _retryLoading = false;
    });

    try {
      final results = await Future.wait([
        _orderService.getOrderStats(),
        _orderService.getOrders(page: _currentPage, limit: _limit),
      ], eagerError: true).timeout(const Duration(seconds: 30));

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          final ordersData = results[1] as Map<String, dynamic>;
          _orders = List<Map<String, dynamic>>.from(ordersData['orders']);
          _totalOrders = ordersData['total'] as int;
          _hasMore = ordersData['has_more'] as bool;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _retryLoading = true;
        });
        _showTimeoutError();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _retryLoading = true;
        });
        _showNetworkError(e.toString());
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (!_hasMore || _isLoadingMore || !_isOnline) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final ordersData = await _orderService.getOrders(
        page: nextPage,
        limit: _limit,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
        platform: _selectedPlatform != 'all' ? _selectedPlatform : null,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          final newOrders = List<Map<String, dynamic>>.from(
            ordersData['orders'] as List,
          );
          _orders.addAll(newOrders);
          _currentPage = nextPage;
          _hasMore = ordersData['has_more'] as bool;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showError('Failed to load more orders: ${e.toString()}');
      }
    }
  }

  Future<void> _applyFilters() async {
    if (!_isOnline) {
      _showOfflineError();
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _orders.clear();
    });

    try {
      final ordersData = await _orderService.getOrders(
        page: _currentPage,
        limit: _limit,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
        platform: _selectedPlatform != 'all' ? _selectedPlatform : null,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(
            ordersData['orders'] as List,
          );
          _totalOrders = ordersData['total'] as int;
          _hasMore = ordersData['has_more'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to apply filters: ${e.toString()}');
      }
    }
  }

  Future<void> _searchOrders() async {
    if (!_isOnline) {
      _showOfflineError();
      return;
    }

    if (_searchQuery.trim().isEmpty) {
      await _applyFilters();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ordersData = await _orderService.searchOrders(_searchQuery);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(
            ordersData['orders'] as List,
          );
          _totalOrders = ordersData['total'] as int;
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to search orders: ${e.toString()}');
      }
    }
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedStatus = 'all';
      _selectedPlatform = 'all';
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
    });

    await _loadInitialData();
  }

  Future<void> _exportOrders() async {
    if (!_isOnline) {
      _showOfflineError();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final csvData = await _orderService.exportOrdersToCSV(
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
        platform: _selectedPlatform != 'all' ? _selectedPlatform : null,
      );

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/orders_${_dateFormatter.format(DateTime.now())}.csv',
      );

      await file.writeAsString(csvData);
      _showSuccess('Orders exported successfully');

      // Copy file path to clipboard for easy access
      await Clipboard.setData(ClipboardData(text: file.path));

      setState(() => _isExporting = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        _showError('Failed to export orders: ${e.toString()}');
      }
    }
  }

  Future<void> _copyOrderId(String orderId) async {
    await Clipboard.setData(ClipboardData(text: orderId));
    _showSuccess('Order ID copied to clipboard');
  }

  Future<void> _cancelOrder(String orderId) async {
    if (!_isOnline) {
      _showOfflineError();
      return;
    }

    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Cancel Order',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            content: Text(
              'Are you sure you want to cancel this order?\nThis action cannot be undone.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Yes, Cancel',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final result = await _orderService.cancelOrder(orderId);

      if (result['success'] == true) {
        _showSuccess(result['message']);
        await _applyFilters();
        final newStats = await _orderService.getOrderStats();
        setState(() => _stats = newStats as Map<String, dynamic>);
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError('Failed to cancel order: ${e.toString()}');
    }
  }

  void _navigateToOrderDetails(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsView(orderId: orderId),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final theme = Theme.of(context);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _applyFilters();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  Widget _buildStatsCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Statistics',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Total',
                _stats['total_orders']?.toString() ?? '0',
                theme,
                icon: Icons.receipt_long,
              ),
              _buildStatItem(
                'Active',
                _stats['active_orders']?.toString() ?? '0',
                theme,
                color: Colors.blue,
                icon: Icons.autorenew,
              ),
              _buildStatItem(
                'Completed',
                _stats['completed_orders']?.toString() ?? '0',
                theme,
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              _buildStatItem(
                'Spent',
                '₦${(_stats['total_spent'] ?? 0).toStringAsFixed(0)}',
                theme,
                color: Colors.purple,
                icon: Icons.account_balance_wallet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
    IconData? icon,
  }) {
    final textColor = color ?? theme.colorScheme.onSurface;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 14, color: textColor.withOpacity(0.8)),
            if (icon != null) const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_alt, color: theme.colorScheme.primary),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          if (_selectedStatus != 'all' ||
              _selectedPlatform != 'all' ||
              _startDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_selectedStatus != 'all')
                      _buildFilterChip(
                        'Status: $_selectedStatus',
                        theme,
                        onRemove: () {
                          setState(() => _selectedStatus = 'all');
                          _applyFilters();
                        },
                      ),
                    if (_selectedPlatform != 'all')
                      _buildFilterChip(
                        'Platform: ${PlatformHelper.getPlatformDisplayName(_selectedPlatform)}',
                        theme,
                        onRemove: () {
                          setState(() => _selectedPlatform = 'all');
                          _applyFilters();
                        },
                      ),
                    if (_startDate != null && _endDate != null)
                      _buildFilterChip(
                        'Date: ${_dateFormatter.format(_startDate!)} - ${_dateFormatter.format(_endDate!)}',
                        theme,
                        onRemove: _clearDateRange,
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ThemeData theme, {
    VoidCallback? onRemove,
  }) {
    return Chip(
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
        size: 16,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onDeleted: onRemove,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, ThemeData theme) {
    final status = order['status'] as String;
    final createdAt = DateTime.parse(order['created_at'] as String);
    final statusColor = _getStatusColor(status);
    final platform =
        order['platform']?.toString() ??
        order['selected_platform']?.toString() ??
        'social';
    final isCancelable = status == 'pending' || status == 'active';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
          onTap: () => _navigateToOrderDetails(order['id'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['task_title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                PlatformHelper.getPlatformIcon(platform),
                                size: 14,
                                color: PlatformHelper.getPlatformColor(
                                  platform,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                PlatformHelper.getPlatformDisplayName(platform),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${(order['total_price'] as num).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormatter.format(createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantity: ${order['quantity']}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.content_copy,
                            size: 18,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () => _copyOrderId(order['id'] as String),
                          tooltip: 'Copy Order ID',
                        ),
                        if (isCancelable)
                          IconButton(
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed:
                                () => _cancelOrder(order['id'] as String),
                            tooltip: 'Cancel Order',
                          ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed:
                                () => _navigateToOrderDetails(
                                  order['id'] as String,
                                ),
                            padding: EdgeInsets.zero,
                            tooltip: 'View Details',
                          ),
                        ),
                      ],
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

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'No Orders Found',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'When you create orders, they will appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create First Order',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/error.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _checkConnectivity(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Check Connection',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 100,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No Internet Connection',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              NetworkMessages.pageLoadFailed,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _checkConnectivity();
                if (_isOnline) _loadInitialData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Retry Connection',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (context) {
        String tempStatus = _selectedStatus;
        String tempPlatform = _selectedPlatform;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Orders',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterSection(
                              'Status',
                              [
                                'all',
                                'pending',
                                'active',
                                'completed',
                                'cancelled',
                              ],
                              tempStatus,
                              (value) => setState(() => tempStatus = value!),
                              theme,
                            ),
                            const SizedBox(height: 24),
                            _buildFilterSection(
                              'Platform',
                              _filteredPlatformOptions,
                              tempPlatform,
                              (value) => setState(() => tempPlatform = value!),
                              theme,
                            ),
                            const SizedBox(height: 24),
                            _buildDateRangeSection(theme),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearFilters();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.3,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Reset All',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedStatus = tempStatus;
                                  _selectedPlatform = tempPlatform;
                                });
                                _applyFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Apply Filters',
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
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String value,
    ValueChanged<String?> onChanged,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                final isSelected = option == value;
                final displayText =
                    option == 'all'
                        ? 'All'
                        : PlatformHelper.getPlatformDisplayName(option);

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (option != 'all')
                        Icon(
                          PlatformHelper.getPlatformIcon(option),
                          size: 14,
                          color:
                              isSelected
                                  ? Colors.white
                                  : PlatformHelper.getPlatformColor(option),
                        ),
                      if (option != 'all') const SizedBox(width: 6),
                      Text(
                        displayText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onChanged(option);
                  },
                  backgroundColor: theme.colorScheme.surface,
                  selectedColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showDateRangePicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                label: Text(
                  _startDate != null && _endDate != null
                      ? '${_dateFormatter.format(_startDate!)} - ${_dateFormatter.format(_endDate!)}'
                      : 'Select Date Range',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (_startDate != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: _clearDateRange,
                tooltip: 'Clear Date Range',
              ),
            ],
          ],
        ),
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showOfflineError() {
    _showError(NetworkMessages.pageLoadFailed);
  }

  void _showTimeoutError() {
    _showError('Request timeout. Please try again.');
  }

  void _showNetworkError(String error) {
    _showError('Network error: $error');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
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
          'Order History',
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isExporting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.download,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              onPressed: _exportOrders,
              tooltip: 'Export Orders',
            ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            onPressed: _loadInitialData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          !_isOnline && _retryLoading
              ? _buildOfflineState()
              : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: TextEditingController(text: _searchQuery),
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search orders by ID, title, or platform...',
                        hintStyle: GoogleFonts.inter(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _applyFilters();
                                  },
                                )
                                : null,
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
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        if (value.isEmpty) _applyFilters();
                      },
                      onSubmitted: (_) => _searchOrders(),
                    ),
                  ),

                  // Stats Card
                  _buildStatsCard(theme),

                  // Filters Card
                  _buildFiltersCard(theme),

                  // Order Count
                  if (!_isLoading && _orders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${_orders.length} of $_totalOrders orders',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          if (_totalOrders > 0)
                            Text(
                              '₦${(_stats['total_spent'] ?? 0).toStringAsFixed(0)} total spent',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Orders List
                  Expanded(
                    child:
                        _isLoading && _orders.isEmpty
                            ? _buildLoadingState(theme)
                            : _retryLoading && _orders.isEmpty
                            ? _buildErrorState(
                              NetworkMessages.pageLoadFailed,
                              _loadInitialData,
                            )
                            : _orders.isEmpty
                            ? _buildEmptyState(theme)
                            : NotificationListener<ScrollNotification>(
                              onNotification: (scrollNotification) {
                                if (scrollNotification
                                        is ScrollEndNotification &&
                                    scrollNotification.metrics.pixels ==
                                        scrollNotification
                                            .metrics
                                            .maxScrollExtent &&
                                    _hasMore) {
                                  _loadMoreOrders();
                                }
                                return false;
                              },
                              child: RefreshIndicator(
                                color: colorScheme.primary,
                                onRefresh: _loadInitialData,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 8),
                                  itemCount:
                                      _orders.length + (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index < _orders.length) {
                                      return _buildOrderCard(
                                        _orders[index],
                                        theme,
                                      );
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _clearFilters,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.filter_alt_off, size: 20),
        label: Text(
          'Clear Filters',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
