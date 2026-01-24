// views/tasks/task_details_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/wallet_service.dart';
import '../../view_models/home_view_model.dart';
import '../../models/task_models.dart'; // Import TaskModel

class TaskDetailsView extends StatefulWidget {
  final TaskModel task; // CHANGED: Use TaskModel instead of Map

  const TaskDetailsView({super.key, required this.task});

  @override
  State<TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<TaskDetailsView> {
  final WalletService _walletService = WalletService();
  int _quantity = 1;
  String? _selectedPlatform;
  String _gender = 'All Gender';
  String _religion = 'All Religion';
  String _caption = '';
  List<String> _selectedMedia = [];
  TextEditingController _captionController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final platforms = widget.task.platforms;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: SingleChildScrollView(
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
                  child: Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Price
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
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.description,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),

            const SizedBox(height: 30),

            // Platform Selection
            if (platforms.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Platform',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                _selectedPlatform = selected ? platform : null;
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Quantity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_quantity > 1) {
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
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Total Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                        _selectedPlatform == null
                            ? null
                            : () {
                              _processOrder(context);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'PROCEED TO PAY',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processOrder(BuildContext context) async {
    try {
      // Determine media type based on selected media
      final mediaType =
          _selectedMedia.isNotEmpty
              ? 'photo'
              : 'text'; // CHANGED: Provide default value

      final result = await _walletService.processOrderPayment(
        taskId: widget.task.id,
        taskTitle: widget.task.title,
        taskCategory: widget.task.category,
        platform: _selectedPlatform!,
        quantity: _quantity,
        gender: _gender,
        stateId: null,
        stateName: null,
        lgaId: null,
        lgaName: null,
        religion: _religion,
        caption: _caption,
        postLink: null,
        mediaType: mediaType, // CHANGED: Now a non-null String
        mediaUrls: _selectedMedia.isNotEmpty ? _selectedMedia : null,
        mediaStoragePaths: _selectedMedia.isNotEmpty ? _selectedMedia : null,
        unitPrice: widget.task.price,
        totalPrice: totalPrice,
      );

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or to orders page
        Navigator.pop(context);

        // Refresh the home view model if needed
        final viewModel = Provider.of<HomeViewModel>(context, listen: false);
        viewModel.refreshWallet();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
