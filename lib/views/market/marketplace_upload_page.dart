import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juvapay/services/marketplace_service.dart';
import 'package:juvapay/services/wallet_service.dart';
import 'package:juvapay/widgets/loading_overlay.dart';
import 'package:juvapay/widgets/error_dialog.dart';
import 'package:juvapay/widgets/success_dialog.dart';
import 'package:juvapay/views/market/market_view.dart';
import 'package:juvapay/views/advertise/advert_payment_view.dart';

class MarketplaceUploadPage extends StatefulWidget {
  const MarketplaceUploadPage({Key? key}) : super(key: key);

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
  final TextEditingController _subCategory1Controller = TextEditingController();
  final TextEditingController _subCategory2Controller = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State
  String _selectedCategory = 'Other Categories';
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _hasAdvertSubscription = false;
  double _availableBalance = 0.0;

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

  // Sub-category suggestions based on main category
  final Map<String, List<String>> _subCategorySuggestions = {
    "Health and Beauty": [
      "Skincare",
      "Haircare",
      "Makeup",
      "Fragrances",
      "Personal Care",
      "Vitamins & Supplements",
    ],
    "Grocery": [
      "Food & Beverages",
      "Snacks",
      "Cooking Ingredients",
      "Dairy Products",
      "Beverages",
      "Canned Foods",
    ],
    "Phones and Tablets": [
      "Smartphones",
      "Tablets",
      "Accessories",
      "Cases & Covers",
      "Chargers",
      "Screen Protectors",
    ],
    "Baby Product": [
      "Baby Clothing",
      "Diapers",
      "Baby Food",
      "Toys",
      "Nursery",
      "Feeding",
    ],
    "Computing": [
      "Laptops",
      "Desktops",
      "Computer Accessories",
      "Software",
      "Storage Devices",
      "Networking",
    ],
    "Fashion": [
      "Clothing",
      "Shoes",
      "Bags",
      "Accessories",
      "Jewelry",
      "Watches",
    ],
    "Electronics": [
      "TV & Audio",
      "Home Appliances",
      "Gaming",
      "Cameras",
      "Smart Home",
      "Wearables",
    ],
    "Home and Office": [
      "Furniture",
      "Decor",
      "Kitchenware",
      "Office Supplies",
      "Lighting",
      "Garden",
    ],
    "Books, Movies and Musics": [
      "Books",
      "Movies",
      "Music",
      "Magazines",
      "E-books",
      "Instruments",
    ],
    "Other Categories": [],
  };

  List<String> _currentSubCategoryOptions = [];

  StreamSubscription? _walletStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      _initializeWalletStream();
      await _checkAdvertSubscription();
      _updateSubCategoryOptions();
    } catch (e) {
      debugPrint('Error initializing marketplace upload page: $e');
    }
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
    _subCategory1Controller.dispose();
    _subCategory2Controller.dispose();
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
      if (mounted) {
        setState(() {
          _hasAdvertSubscription = subscription['is_active'] == true;
        });
      }
    } catch (e) {
      debugPrint('Error checking advert subscription: $e');
    }
  }

  void _updateSubCategoryOptions() {
    setState(() {
      _currentSubCategoryOptions =
          _subCategorySuggestions[_selectedCategory] ?? [];
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        final remainingSlots = 5 - _selectedImages.length;
        if (remainingSlots > 0) {
          final filesToAdd = pickedFiles.take(remainingSlots).toList();

          setState(() {
            _selectedImages.addAll(filesToAdd.map((file) => File(file.path)));
          });
        } else {
          await showErrorDialog(
            context,
            title: 'Maximum Images Reached',
            message: 'You can only upload up to 5 images',
          );
        }
      }
    } catch (e) {
      await showErrorDialog(
        context,
        title: 'Image Selection Error',
        message: 'Failed to pick images. Please check your permissions.',
      );
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Enhanced validation
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Check for minimum 2 images
    if (_selectedImages.length < 2) {
      showErrorDialog(
        context,
        title: 'Image Requirement',
        message: 'Please upload at least 2 product images (max 5)',
      );
      return false;
    }

    // Validate price
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      showErrorDialog(
        context,
        title: 'Invalid Price',
        message: 'Please enter a valid price greater than 0',
      );
      return false;
    }

    // Validate quantity
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    if (quantity <= 0) {
      showErrorDialog(
        context,
        title: 'Invalid Quantity',
        message: 'Please enter a valid quantity (minimum 1)',
      );
      return false;
    }

    return true;
  }

  Future<void> _submitProduct() async {
    // Close keyboard if open
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_validateForm()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if user has active advert subscription
      if (!_hasAdvertSubscription) {
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
          setState(() => _isLoading = false);
          return;
        }

        if (!hasSufficientBalance) {
          // Navigate to advert payment page and wait for result
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AdvertPaymentView()),
          );

          // If payment was successful, refresh subscription status
          if (result == true) {
            await _checkAdvertSubscription();

            if (_hasAdvertSubscription) {
              await _listProduct();
            } else {
              setState(() => _isLoading = false);
            }
          } else {
            setState(() => _isLoading = false);
          }
          return;
        } else {
          // User has sufficient balance, process payment directly
          final paymentResult = await _walletService.processAdvertPayment();

          if (paymentResult['success'] == true) {
            // Payment successful, refresh subscription status
            await _checkAdvertSubscription();

            if (_hasAdvertSubscription) {
              await _listProduct();
            } else {
              await showErrorDialog(
                context,
                title: 'Payment Processing',
                message:
                    'Your payment is being processed. Please try again in a moment.',
              );
              setState(() => _isLoading = false);
            }
          } else {
            await showErrorDialog(
              context,
              title: 'Payment Failed',
              message: 'Failed to process advert payment. Please try again.',
            );
            setState(() => _isLoading = false);
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
        message: 'Failed to list product. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _listProduct() async {
    try {
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
              ? _sizeController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
              : null;

      final colors =
          _colorController.text.trim().isNotEmpty
              ? _colorController.text
                  .split(',')
                  .map((c) => c.trim())
                  .where((c) => c.isNotEmpty)
                  .toList()
              : null;

      // Get sub-category values
      final subCategory1 =
          _subCategory1Controller.text.trim().isNotEmpty
              ? _subCategory1Controller.text.trim()
              : null;

      final subCategory2 =
          _subCategory2Controller.text.trim().isNotEmpty
              ? _subCategory2Controller.text.trim()
              : null;

      // Create product
      await _marketplaceService.createProduct(
        title: _titleController.text.trim(),
        price: price,
        description: _descriptionController.text.trim(),
        mainCategory: _selectedCategory,
        subCategory1: subCategory1,
        subCategory2: subCategory2,
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

      // Show success
      await showSuccessDialog(
        context,
        title: 'Product Listed!',
        message: 'Your product has been listed successfully.',
        icon: Icons.check_circle,
      );

      // Navigate back to MarketView (the page users typically come from)
      if (mounted) {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      debugPrint('Error listing product: $e');
      rethrow;
    }
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount:
              _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _selectedImages.length) {
              return _buildImagePreview(index);
            } else {
              return _buildAddImageButton();
            }
          },
        ),

        // Image requirement indicator
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(
                _selectedImages.length >= 2 ? Icons.check_circle : Icons.error,
                size: 16,
                color:
                    _selectedImages.length >= 2 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                '${_selectedImages.length}/5 images (min 2 required)',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      _selectedImages.length >= 2
                          ? Colors.green
                          : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
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
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
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
                color: Colors.black.withOpacity(0.7),
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
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
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

  Widget _buildSubCategoryField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<String> suggestions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            if (suggestions.isNotEmpty)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  onSelected: (value) {
                    setState(() {
                      controller.text = value;
                    });
                  },
                  itemBuilder: (context) {
                    return suggestions
                        .map(
                          (suggestion) => PopupMenuItem<String>(
                            value: suggestion,
                            child: Text(suggestion),
                          ),
                        )
                        .toList();
                  },
                ),
              ),
          ],
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Suggestions: ${suggestions.take(3).join(', ')}${suggestions.length > 3 ? '...' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₦${_availableBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Advert Subscription Status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        _hasAdvertSubscription
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _hasAdvertSubscription ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasAdvertSubscription
                            ? Icons.check_circle
                            : Icons.warning,
                        color:
                            _hasAdvertSubscription
                                ? Colors.green
                                : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasAdvertSubscription
                              ? '✓ Advert subscription active'
                              : '⚠ Advert subscription required (₦1,000)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                _hasAdvertSubscription
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Images Section
                const Text(
                  'Product Images*',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload at least 2 images (max 5)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _buildImageGrid(),
                const SizedBox(height: 24),

                // Product Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Product Title*',
                    hintText: 'Enter product title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter product title';
                    }
                    if (value.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items:
                            _categories.map((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                              _updateSubCategoryOptions();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sub-categories in a row
                Row(
                  children: [
                    Expanded(
                      child: _buildSubCategoryField(
                        controller: _subCategory1Controller,
                        label: 'Sub-category 1',
                        hint: 'Optional (e.g., Skincare, Smartphones)',
                        suggestions: _currentSubCategoryOptions,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSubCategoryField(
                        controller: _subCategory2Controller,
                        label: 'Sub-category 2',
                        hint: 'Optional (e.g., Makeup, Accessories)',
                        suggestions: _currentSubCategoryOptions,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price (₦)*',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter price';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _oldPriceController,
                        decoration: InputDecoration(
                          labelText: 'Old Price (₦)',
                          hintText: 'Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isNotEmpty == true) {
                            final price = double.tryParse(value!);
                            if (price == null || price <= 0) {
                              return 'Enter valid price or leave empty';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Brand & Quantity
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          labelText: 'Brand',
                          hintText: 'Enter brand name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity*',
                          hintText: '1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final quantity = int.tryParse(value ?? '1') ?? 1;
                          if (quantity <= 0) {
                            return 'Quantity must be at least 1';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sizes & Colors
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sizeController,
                        decoration: InputDecoration(
                          labelText: 'Available Sizes',
                          hintText: 'S, M, L, XL (comma separated)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: InputDecoration(
                          labelText: 'Available Colors',
                          hintText: 'Red, Blue, Black (comma separated)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description*',
                    hintText: 'Enter detailed product description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Return Policy
                TextFormField(
                  controller: _returnPolicyController,
                  decoration: InputDecoration(
                    labelText: 'Return Policy',
                    hintText: 'Enter your return policy (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                  maxLength: 500,
                ),
                const SizedBox(height: 24),

                // Important Information
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
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Upload at least 2 clear product images'),
                          Text('• Provide accurate product description'),
                          Text('• Set a competitive price for better sales'),
                          Text('• Ensure return policy is clearly stated'),
                          Text(
                            '• Sub-categories help buyers find your product',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Available balance: ₦${_availableBalance.toStringAsFixed(2)}',
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
                    onPressed: _isLoading ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'LIST PRODUCT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
