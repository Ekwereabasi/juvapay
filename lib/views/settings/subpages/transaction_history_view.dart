import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/wallet_service.dart';
import 'package:juvapay/view_models/wallet_view_model.dart';

class _SummaryTotals {
  final double income;
  final double expenses;
  final double net;

  const _SummaryTotals({
    required this.income,
    required this.expenses,
    required this.net,
  });
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
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
    'Completed',
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

  // Date filter state
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _SummaryTotals _calculateSummaryTotals(List<Transaction> transactions) {
    double income = 0;
    double expenses = 0;

    for (final transaction in transactions) {
      if (transaction.isCredit) {
        income += transaction.amount;
      } else if (transaction.isDebit) {
        expenses += transaction.amount;
      }
    }

    return _SummaryTotals(
      income: income,
      expenses: expenses,
      net: income - expenses,
    );
  }

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
      case 'Completed':
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
      case 'Completed':
        return 'COMPLETED';
      case 'Failed':
        return 'FAILED';
      default:
        return null;
    }
  }

  Future<void> _refreshData() async {
    final walletViewModel = context.read<WalletViewModel>();
    await walletViewModel.refreshWalletData();
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
      startDate: _startDate,
      endDate: _endDate,
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
      final type =
          WalletService.formatTransactionType(transaction.type).toLowerCase();
      final amount = transaction.formattedAmount.toLowerCase();

      final query = searchQuery.toLowerCase();
      return description.contains(query) ||
          reference.contains(query) ||
          type.contains(query) ||
          amount.contains(query);
    }).toList();
  }

  Widget _buildSummaryCard(_SummaryTotals totals) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              'Total Income',
              '₦${totals.income.toStringAsFixed(2)}',
              Colors.green,
              Icons.arrow_upward,
            ),
            _buildStatCard(
              'Total Expenses',
              '₦${totals.expenses.toStringAsFixed(2)}',
              Colors.red,
              Icons.arrow_downward,
            ),
            _buildStatCard(
              'Net Flow',
              '₦${totals.net.toStringAsFixed(2)}',
              totals.net >= 0 ? Colors.green : Colors.red,
              totals.net >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 150,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                transaction.isCredit
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              transaction.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
              transaction.referenceId.length > 8
                  ? '${transaction.referenceId.substring(0, 8)}...'
                  : transaction.referenceId,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap:
            () => _showTransactionDetails(
              transaction,
            ), // Fixed: removed context parameter
      ),
    );
  }

  void _showFilterDialog() {
    // Fixed: removed BuildContext parameter
    showModalBottomSheet(
      context: context, // Use widget's context
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Filter Type
                  const Text(
                    'Filter By',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        _filterOptions.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? filter : 'All';
                              });
                            },
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Date Range
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _startDate == null
                                ? 'Start Date'
                                : DateFormat('dd/MM/yyyy').format(_startDate!),
                          ),
                        ),
                      ),
                      const Text('to'),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: _startDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _endDate == null
                                ? 'End Date'
                                : DateFormat('dd/MM/yyyy').format(_endDate!),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _currentPage = 1;
                            _hasMore = true;
                            setState(() {});
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'All';
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    // Fixed: removed BuildContext parameter
    showModalBottomSheet(
      context: context, // Use widget's context
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
                        color:
                            transaction.isCredit
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
                            WalletService.formatTransactionType(
                              transaction.type,
                            ),
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
                  color:
                      transaction.isCredit
                          ? Colors.green.withOpacity(0.05)
                          : Colors.red.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          transaction.formattedAmount,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color:
                                transaction.isCredit
                                    ? Colors.green
                                    : Colors.red,
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
                        style: const TextStyle(fontWeight: FontWeight.w500),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        value,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog, // Fixed: no parameters needed
          ),
        ],
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, walletViewModel, child) {
          if (walletViewModel.isLoading &&
              walletViewModel.recentTransactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Apply filters to get filtered transactions
          final types = _getTransactionTypesFromFilter(_selectedFilter);
          final status = _getStatusFromFilter(_selectedFilter);

          List<Transaction> allTransactions =
              walletViewModel.recentTransactions;

          List<Transaction> filteredTransactions =
              allTransactions.where((transaction) {
                if (types.isNotEmpty && !types.contains(transaction.type)) {
                  return false;
                }
                if (status != null && transaction.status != status) {
                  return false;
                }
                if (_startDate != null &&
                    transaction.createdAt.isBefore(_startDate!)) {
                  return false;
                }
                if (_endDate != null &&
                    transaction.createdAt.isAfter(
                      _endDate!.add(const Duration(days: 1)),
                    )) {
                  return false;
                }
                return true;
              }).toList();

          // Apply search filter
          filteredTransactions = _filterTransactions(
            filteredTransactions,
            _searchQuery,
          );

          // Group by date
          final Map<String, List<Transaction>> groupedTransactions = {};
          for (final transaction in filteredTransactions) {
            final dateKey = transaction.formattedDate;
            if (!groupedTransactions.containsKey(dateKey)) {
              groupedTransactions[dateKey] = [];
            }
            groupedTransactions[dateKey]!.add(transaction);
          }

          // Sort dates
          final sortedDates = groupedTransactions.keys.toList();
          sortedDates.sort((a, b) {
            if (a == 'Today') return -1;
            if (b == 'Today') return 1;
            if (a == 'Yesterday') return -1;
            if (b == 'Yesterday') return 1;
            return b.compareTo(a);
          });

          return Column(
            children: [
              // Summary Cards
              _buildSummaryCard(
                _calculateSummaryTotals(filteredTransactions),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
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
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Filter Chip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _filterOptions.map((filter) {
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
                              backgroundColor:
                                  isSelected
                                      ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1)
                                      : Colors.grey[100],
                              labelStyle: TextStyle(
                                color:
                                    isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[700],
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color:
                                      isSelected
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

              // Transactions List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollEndNotification &&
                          scrollNotification.metrics.pixels ==
                              scrollNotification.metrics.maxScrollExtent &&
                          _hasMore &&
                          !_isLoadingMore &&
                          filteredTransactions.length >= _transactionsPerPage) {
                        _loadMoreTransactions();
                      }
                      return false;
                    },
                    child:
                        filteredTransactions.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                              itemCount:
                                  sortedDates.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= sortedDates.length) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final date = sortedDates[index];
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
                                    ...transactions.map(
                                      (transaction) =>
                                          _buildTransactionItem(transaction),
                                    ),
                                  ],
                                );
                              },
                            ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? 'No transactions found'
                : 'No matching transactions',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          if (_searchQuery.isNotEmpty ||
              _selectedFilter != 'All' ||
              _startDate != null ||
              _endDate != null)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                  _startDate = null;
                  _endDate = null;
                  _currentPage = 1;
                  _hasMore = true;
                });
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }
}
