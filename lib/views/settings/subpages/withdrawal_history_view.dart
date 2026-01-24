import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/wallet_view_model.dart'; // Import the WalletViewModel
import '../../../services/wallet_service.dart'; // Import WalletService for utility methods


// ==========================================
// WALLET HISTORY PAGE
// ==========================================

class WalletHistoryPage extends StatefulWidget {
  const WalletHistoryPage({super.key});

  @override
  State<WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends State<WalletHistoryPage> {
  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Deposits',
    'Withdrawals',
    'Earnings',
    'Payments',
    'Transfers',
    'Pending',
    'Failed',
  ];

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination state
  int _currentPage = 1;
  final int _transactionsPerPage = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Refresh state
  bool _isRefreshing = false;

  // Filter functions
  List<String> _getTransactionTypesFromFilter(String filter) {
    switch (filter) {
      case 'Deposits':
        return ['DEPOSIT'];
      case 'Withdrawals':
        return ['WITHDRAWAL'];
      case 'Earnings':
        return ['TASK_EARNING', 'BONUS'];
      case 'Payments':
        return ['ORDER_PAYMENT', 'ADVERT_FEE', 'MEMBERSHIP_PAYMENT', 'FEE'];
      case 'Transfers':
        return ['TRANSFER_IN', 'TRANSFER_OUT'];
      case 'Pending':
        return [];
      case 'Failed':
        return [];
      default:
        return [];
    }
  }

  String? _getStatusFromFilter(String filter) {
    switch (filter) {
      case 'Pending':
        return 'PENDING';
      case 'Failed':
        return 'FAILED';
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
      _hasMore = true;
    });

    final walletViewModel = context.read<WalletViewModel>();
    await walletViewModel.refreshWalletData();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final walletViewModel = context.read<WalletViewModel>();
    final types = _getTransactionTypesFromFilter(_selectedFilter);
    final status = _getStatusFromFilter(_selectedFilter);

    final newTransactions = await walletViewModel.getTransactionHistory(
      types: types.isNotEmpty ? types : null,
      status: status,
      offset: _currentPage * _transactionsPerPage,
      limit: _transactionsPerPage,
    );

    setState(() {
      _isLoadingMore = false;
      if (newTransactions.length < _transactionsPerPage) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
    });
  }

  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return transactions;

    return transactions.where((transaction) {
      final description = transaction.description.toLowerCase();
      final reference = transaction.referenceId.toLowerCase();
      final type = WalletService.formatTransactionType(transaction.type).toLowerCase();
      final amount = transaction.formattedAmount.toLowerCase();

      final query = searchQuery.toLowerCase();
      return description.contains(query) ||
          reference.contains(query) ||
          type.contains(query) ||
          amount.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, walletViewModel, child) {
          if (walletViewModel.isLoading && walletViewModel.recentTransactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (walletViewModel.errorMessage != null && walletViewModel.recentTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    walletViewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildContent(walletViewModel);
        },
      ),
    );
  }

  Widget _buildContent(WalletViewModel walletViewModel) {
    // Get all transactions from the ViewModel
    List<Transaction> allTransactions = walletViewModel.recentTransactions;
    
    // Apply filters
    final types = _getTransactionTypesFromFilter(_selectedFilter);
    final status = _getStatusFromFilter(_selectedFilter);
    
    List<Transaction> filteredTransactions = allTransactions.where((transaction) {
      if (types.isNotEmpty && !types.contains(transaction.type)) {
        return false;
      }
      if (status != null && transaction.status != status) {
        return false;
      }
      return true;
    }).toList();

    // Apply search filter
    filteredTransactions = _filterTransactions(filteredTransactions, _searchQuery);

    // Group by date
    final Map<String, List<Transaction>> groupedTransactions = {};
    for (final transaction in filteredTransactions) {
      final dateKey = transaction.formattedDate;
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort dates in descending order
    final sortedDates = groupedTransactions.keys.toList();
    sortedDates.sort((a, b) {
      if (a == 'Today') return -1;
      if (b == 'Today') return 1;
      if (a == 'Yesterday') return -1;
      if (b == 'Yesterday') return 1;
      return b.compareTo(a);
    });

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filter Chip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? filter : 'All';
                            _currentPage = 1;
                            _hasMore = true;
                          });
                        },
                        backgroundColor: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Summary Card
          if (walletViewModel.dashboardStats != null)
            SliverToBoxAdapter(
              child: _buildSummaryCard(walletViewModel),
            ),

          // Transactions List
          if (filteredTransactions.isEmpty)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No transactions found'
                        : 'No matching transactions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Text('Clear search'),
                      ),
                    ),
                ],
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isEven) {
                    final dateIndex = index ~/ 2;
                    if (dateIndex >= sortedDates.length) return null;
                    
                    final date = sortedDates[dateIndex];
                    final transactions = groupedTransactions[date]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        ...transactions.map((transaction) =>
                            _buildTransactionItem(transaction)),
                      ],
                    );
                  }
                  return null;
                },
                childCount: sortedDates.length * 2,
              ),
            ),

          // Load More Indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          if (_hasMore && filteredTransactions.isNotEmpty && !_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: TextButton(
                    onPressed: _loadMoreTransactions,
                    child: const Text('Load More Transactions'),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(WalletViewModel walletViewModel) {
    final stats = walletViewModel.dashboardStats!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This Month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                    label: 'Income',
                    value: '₦${stats.month.totalIncome.toStringAsFixed(2)}',
                  ),
                  _buildStatItem(
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                    label: 'Expenses',
                    value: '₦${stats.month.totalExpenses.toStringAsFixed(2)}',
                  ),
                  _buildStatItem(
                    icon: Icons.account_balance_wallet,
                    color: stats.month.netChange >= 0 ? Colors.green : Colors.red,
                    label: 'Net',
                    value: '₦${stats.month.netChange.abs().toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.month.transactionCount} transactions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Avg: ₦${stats.month.averageTransactionAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transaction.isCredit
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            WalletService.getTransactionIcon(transaction.type),
            color: transaction.isCredit ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          WalletService.formatTransactionType(transaction.type),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              transaction.description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.statusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: transaction.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  transaction.formattedTime,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.formattedAmount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: transaction.isCredit ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.referenceId.substring(0, 8),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(context, transaction),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Transactions'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _filterOptions.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return CheckboxListTile(
                      title: Text(filter),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedFilter = filter;
                          } else {
                            _selectedFilter = 'All';
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'All';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Reset pagination when filter changes
                    setState(() {
                      _currentPage = 1;
                      _hasMore = true;
                    });
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: transaction.isCredit
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        WalletService.getTransactionIcon(transaction.type),
                        color: transaction.isCredit ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            WalletService.formatTransactionType(transaction.type),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Amount Card
                Card(
                  color: transaction.isCredit
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          transaction.formattedAmount,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: transaction.isCredit ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Details Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDetailItem(
                      'Status',
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: transaction.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transaction.statusText,
                          style: TextStyle(
                            color: transaction.statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    _buildDetailItem(
                      'Date',
                      Text(
                        '${transaction.formattedDate}, ${transaction.formattedTime}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildDetailItem(
                      'Reference ID',
                      Text(
                        transaction.referenceId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildDetailItem(
                      'Transaction ID',
                      Text(
                        transaction.id.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // Additional Information
                if (transaction.orderId != null) ...[
                  const SizedBox(height: 20),
                  _buildDetailItem(
                    'Order ID',
                    Text(
                      transaction.orderId!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (transaction.metadata != null &&
                    transaction.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        transaction.metadata.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}