import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:juvapay/services/marketplace_service.dart';
import 'package:juvapay/services/wallet_service.dart';
import 'package:juvapay/widgets/loading_overlay.dart';
import 'package:juvapay/widgets/error_dialog.dart';
import 'package:juvapay/widgets/success_dialog.dart';
import 'package:juvapay/views/advertise/advert_payment_view.dart';

class MarketplaceUploadPage extends StatefulWidget {
  const MarketplaceUploadPage({super.key});

  @override
  State<MarketplaceUploadPage> createState() => _MarketplaceUploadPageState();
}

class _MarketplaceUploadPageState extends State<MarketplaceUploadPage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final WalletService _walletService = WalletService();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _returnPolicyController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  // State
  String _selectedCategory = 'Other Categories';
  String? _selectedSubCategory1;
  String? _selectedSubCategory2;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _hasAdvertSubscription = false;
  double _availableBalance = 0.0;
  bool _isWalletLocked = false;

  // Categories
  final List<String> _categories = [
    "Health and Beauty",
    "Grocery",
    "Phones and Tablets",
    "Baby Product",
    "Computing",
    "Fashion",
    "Electronics",
    "Home and Office",
    "Books, Movies and Musics",
    "Other Categories",
  ];

  StreamSubscription? _walletStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeWalletStream();
    _checkAdvertSubscription();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _returnPolicyController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _walletStreamSubscription?.cancel();
    super.dispose();
  }

  void _initializeWalletStream() {
    try {
      _walletStreamSubscription = _walletService.getWalletStream().listen(
        (walletData) {
          if (mounted) {
            setState(() {
              _availableBalance = walletData['available_balance'] ?? 0.0;
            });
          }
        },
        onError: (error) {
          debugPrint('Error in wallet stream: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing wallet stream: $e');
    }
  }

  Future<void> _checkAdvertSubscription() async {
    try {
      final subscription =
          await _marketplaceService.getActiveAdvertSubscription();
      setState(() {
        _hasAdvertSubscription = subscription['is_active'] == true;
      });
    } catch (e) {
      debugPrint('Error checking advert subscription: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        // Limit to 5 images
        final filesToAdd =
            pickedFiles.take(5 - _selectedImages.length).toList();

        setState(() {
          _selectedImages.addAll(filesToAdd.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      await showErrorDialog(
        context,
        title: 'Image Selection Error',
        message: 'Failed to pick images: ${e.toString()}',
      );
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      showErrorDialog(
        context,
        title: 'Validation Error',
        message: 'Please enter product title',
      );
      return false;
    }

    if (_priceController.text.trim().isEmpty) {
      showErrorDialog(
        context,
        title: 'Validation Error',
        message: 'Please enter product price',
      );
      return false;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      showErrorDialog(
        context,
        title: 'Validation Error',
        message: 'Please enter a valid price',
      );
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      showErrorDialog(
        context,
        title: 'Validation Error',
        message: 'Please enter product description',
      );
      return false;
    }

    if (_selectedImages.isEmpty) {
      showErrorDialog(
        context,
        title: 'Validation Error',
        message: 'Please add at least one product image',
      );
      return false;
    }

    return true;
  }

  Future<void> _submitProduct() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // Check advert subscription first
      final subscription =
          await _marketplaceService.getActiveAdvertSubscription();
      final hasActiveSubscription = subscription['is_active'] == true;

      if (!hasActiveSubscription) {
        // Check if user has sufficient balance
        final balanceCheck = await _walletService.checkBalance(1000.0);
        final hasSufficientBalance =
            balanceCheck['hasSufficientBalance'] == true;
        final isWalletLocked = balanceCheck['isWalletLocked'] == true;

        if (isWalletLocked) {
          await showErrorDialog(
            context,
            title: 'Wallet Locked',
            message: 'Your wallet is currently locked. Please contact support.',
          );
          return;
        }

        if (!hasSufficientBalance) {
          // Navigate to advert payment page
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => AdvertPaymentView()),
          );

          if (result == true) {
            // User paid successfully, now list the product
            await _listProduct();
          } else {
            // User cancelled or payment failed
            showErrorDialog(
              context,
              title: 'Advert Subscription Required',
              message:
                  'You need an active advert subscription to list products.',
            );
          }
          return;
        } else {
          // User has sufficient balance, process payment and list product
          final paymentResult = await _walletService.processAdvertPayment();

          if (paymentResult['success'] == true) {
            await _listProduct();
          } else {
            await showErrorDialog(
              context,
              title: 'Payment Failed',
              message:
                  'Failed to process advert payment: ${paymentResult['message']}',
            );
          }
          return;
        }
      }

      // User already has active subscription, list product directly
      await _listProduct();
    } catch (e) {
      await showErrorDialog(
        context,
        title: 'Submission Error',
        message: 'Failed to list product: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _listProduct() async {
    // Parse form data
    final price = double.parse(_priceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final oldPrice =
        _oldPriceController.text.trim().isNotEmpty
            ? double.tryParse(_oldPriceController.text.trim())
            : null;

    // Parse sizes and colors
    final sizes =
        _sizeController.text.trim().isNotEmpty
            ? _sizeController.text.split(',').map((s) => s.trim()).toList()
            : null;
    final colors =
        _colorController.text.trim().isNotEmpty
            ? _colorController.text.split(',').map((c) => c.trim()).toList()
            : null;

    // Create product
    final product = await _marketplaceService.createProduct(
      title: _titleController.text.trim(),
      price: price,
      description: _descriptionController.text.trim(),
      mainCategory: _selectedCategory,
      subCategory1: _selectedSubCategory1,
      subCategory2: _selectedSubCategory2,
      quantity: quantity,
      oldPrice: oldPrice,
      brand:
          _brandController.text.trim().isNotEmpty
              ? _brandController.text.trim()
              : null,
      returnPolicy:
          _returnPolicyController.text.trim().isNotEmpty
              ? _returnPolicyController.text.trim()
              : null,
      availableSizes: sizes,
      availableColors: colors,
      images: _selectedImages,
    );

    // Clear form
    _clearForm();

    // Show success
    await showSuccessDialog(
      context,
      title: 'Product Listed!',
      message: 'Your product has been listed successfully.',
      icon: Icons.check_circle,
    );

    // Navigate back
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _priceController.clear();
    _oldPriceController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    _brandController.clear();
    _returnPolicyController.clear();
    _sizeController.clear();
    _colorController.clear();
    _selectedImages.clear();
    setState(() {
      _selectedCategory = 'Other Categories';
      _selectedSubCategory1 = null;
      _selectedSubCategory2 = null;
    });
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _selectedImages.length) {
          return _buildImagePreview(index);
        } else {
          return _buildAddImageButton();
        }
      },
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _selectedImages[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Add Image',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('List Product'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Wallet balance indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₦${_availableBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images
              const Text(
                'Product Images (Max 5)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildImageGrid(),
              const SizedBox(height: 20),

              // Title
              _buildTextField(
                controller: _titleController,
                label: 'Product Title*',
                hint: 'Enter product title',
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Category
              _buildDropdown(
                label: 'Category*',
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),

              // Price
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price (₦)*',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _oldPriceController,
                      label: 'Old Price (₦)',
                      hint: 'Optional',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Brand & Quantity
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _brandController,
                      label: 'Brand',
                      hint: 'Enter brand name',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sizes & Colors
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _sizeController,
                      label: 'Available Sizes',
                      hint: 'S, M, L, XL (comma separated)',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _colorController,
                      label: 'Available Colors',
                      hint: 'Red, Blue, Black (comma separated)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description*',
                hint: 'Enter detailed product description',
                maxLines: 4,
                maxLength: 1000,
              ),
              const SizedBox(height: 16),

              // Return Policy
              _buildTextField(
                controller: _returnPolicyController,
                label: 'Return Policy',
                hint: 'Enter your return policy (optional)',
                maxLines: 2,
                maxLength: 500,
              ),
              const SizedBox(height: 30),

              // Info Box about advert fee
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[800], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Advert Subscription Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A ₦1,000 advert subscription fee is required to list products. '
                      'This subscription is valid for 30 days.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your available balance: ₦${_availableBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _validateForm() ? _submitProduct : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'LIST PRODUCT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
