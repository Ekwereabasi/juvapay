// views/tasks/task_details_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/wallet_view_model.dart';
import '../../view_models/home_view_model.dart';
import '../../models/task_models.dart';
import '../../services/supabase_auth_service.dart';

class TaskDetailsView extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsView({super.key, required this.task});

  @override
  State<TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<TaskDetailsView> {
  int _quantity = 1;
  String? _selectedPlatform;
  final SupabaseAuthService _authService = SupabaseAuthService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final platforms = widget.task.platforms;
    if (platforms.isNotEmpty) {
      _selectedPlatform = platforms.first;
    }
  }

  double get totalPrice {
    final price = widget.task.price;
    return price * _quantity;
  }

  Future<void> _createAdvertiserOrder(BuildContext context) async {
    final walletViewModel = context.read<WalletViewModel>();

    // Validate platform selection
    if (_selectedPlatform == null) {
      _showSnackBar('Please select a platform', isError: true);
      return;
    }

    // Validate quantity within min/max limits
    if (_quantity < widget.task.minQuantity) {
      _showSnackBar(
        'Minimum quantity is ${widget.task.minQuantity}',
        isError: true,
      );
      return;
    }

    if (_quantity > widget.task.maxQuantity) {
      _showSnackBar(
        'Maximum quantity is ${widget.task.maxQuantity}',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if user has sufficient balance using WalletViewModel
      final balanceCheck = await walletViewModel.checkBalance(totalPrice);

      if (!balanceCheck['hasSufficientBalance']) {
        final deficit = balanceCheck['deficit'] ?? 0.0;
        _showSnackBar(
          'Insufficient balance. You need ₦${deficit.toStringAsFixed(2)} more.',
          isError: true,
        );
        return;
      }

      // Create order using the new system
      final result = await _authService.createAdvertiserOrder(
        taskId: widget.task.id,
        platform: _selectedPlatform!,
        quantity: _quantity,
        metadata: {
          'task_title': widget.task.title,
          'task_category': widget.task.category,
          'created_via': 'mobile_app',
          'app_version': '1.0.0',
        },
      );

      if (result['success'] == true) {
        // Show success message
        _showSnackBar(
          result['message'] ?? 'Order created successfully!',
          isError: false,
        );

        // Refresh wallet data
        await walletViewModel.refreshWalletData();

        // Navigate back after delay
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // Show error message
        _showSnackBar(
          result['message'] ?? 'Failed to create order',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error creating order: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.blue, size: 24),
              SizedBox(width: 10),
              Text('Confirm Order'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to create an order for:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildConfirmDetailRow(
                      'Task',
                      widget.task.title,
                      Colors.black,
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmDetailRow(
                      'Platform',
                      _selectedPlatform!,
                      Colors.grey[600]!,
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmDetailRow(
                      'Quantity',
                      _quantity.toString(),
                      Colors.grey[600]!,
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmDetailRow(
                      'Unit Price',
                      '₦${widget.task.price.toStringAsFixed(2)}',
                      Colors.grey[600]!,
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmDetailRow(
                      'Total Amount',
                      '₦${totalPrice.toStringAsFixed(2)}',
                      Colors.green,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This amount will be deducted from your wallet balance.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (widget.task.category == 'advert')
                Text(
                  'You will need to provide ad content after payment.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createAdvertiserOrder(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Confirm & Create Order'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmDetailRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final platforms = widget.task.platforms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, walletViewModel, child) {
          final wallet = walletViewModel.wallet;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.work, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.task.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Price Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price per unit:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '₦${widget.task.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task.description,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),

                // Requirements
                if (widget.task.requirements.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Requirements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.task.requirements.map((req) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req.toString(),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                // Instructions
                if (widget.task.instructions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Instructions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.task.instructions.map((inst) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.arrow_right,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              inst.toString(),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                const SizedBox(height: 30),

                // Platform Selection
                if (platforms.length > 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Platform',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            platforms.map((platform) {
                              return ChoiceChip(
                                label: Text(platform),
                                selected: _selectedPlatform == platform,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedPlatform =
                                        selected ? platform : null;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Quantity Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Min: ${widget.task.minQuantity} | Max: ${widget.task.maxQuantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > widget.task.minQuantity) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                '$_quantity',
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
                                if (_quantity < widget.task.maxQuantity) {
                                  setState(() {
                                    _quantity++;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Total Price Card with Balance Check
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₦${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (wallet != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Available Balance:',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '₦${wallet.availableBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    totalPrice <= wallet.availableBalance
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (wallet != null &&
                          totalPrice > wallet.availableBalance)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Insufficient balance. Add ₦${(totalPrice - wallet.availableBalance).toStringAsFixed(2)} to proceed.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: primaryColor),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isProcessing || _selectedPlatform == null
                                ? null
                                : () {
                                  _showConfirmationDialog(context);
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isProcessing || _selectedPlatform == null
                                  ? theme.disabledColor
                                  : primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isProcessing
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'CREATE ORDER',
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Additional Info
                if (_selectedPlatform != null)
                  Card(
                    color: Colors.blue.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.task.category == 'advert'
                                  ? 'After payment, you will provide ad content for your order.'
                                  : 'After payment, you will provide target links and details.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
