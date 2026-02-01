import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:juvapay/services/marketplace_service.dart';
import 'package:juvapay/models/marketplace_models.dart';
import 'package:juvapay/view_models/wallet_view_model.dart';
import 'package:juvapay/widgets/loading_overlay.dart';
import 'package:juvapay/widgets/error_dialog.dart';
import 'package:juvapay/widgets/success_dialog.dart';

class ProductViewPage extends StatefulWidget {
  final int productId;

  const ProductViewPage({super.key, required this.productId});

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  // State
  MarketplaceProduct? _product;
  bool _isLoading = true;
  bool _isLiking = false;
  String? _errorMessage;
  int _currentImageIndex = 0;
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load product details
      final product = await _marketplaceService.getProductById(
        widget.productId,
      );

      if (!mounted) return;

      if (product == null) {
        setState(() {
          _errorMessage = 'Product not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _product = product;
        _isLoading = false;
      });

      // Increment view count
      if (product.isActive) {
        await _marketplaceService.incrementProductView(widget.productId);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load product: ${e.toString()}';
        _isLoading = false;
      });

      debugPrint('Error loading product: $e');
    }
  }

  Future<void> _handleLike() async {
    if (_product == null || _isLiking) return;

    setState(() => _isLiking = true);

    try {
      await _marketplaceService.toggleProductLike(_product!.id);

      // Refresh product data
      await _loadProduct();
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: 'Error',
        message: 'Failed to update like: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  Future<void> _showReportDialog() async {
    final reasons = [
      "Fraudulent/Scam Advert",
      "Inappropriate/Offensive Content",
      "Counterfeit Item",
      "Wrong Category",
      "Price is misleading",
      "Item already sold",
      "Spam or duplicate listing",
      "Other",
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Report Product",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Why are you reporting this product?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: reasons.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            reasons[index],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () async {
                            Navigator.pop(context);
                            await _submitReport(reasons[index]);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReport(String reason) async {
    if (_product == null || _isReporting) return;

    setState(() => _isReporting = true);

    try {
      await _marketplaceService.reportProduct(
        productId: _product!.id,
        reason: reason,
        details: "Reported from mobile app",
      );

      if (!mounted) return;

      await showSuccessDialog(
        context,
        title: 'Report Submitted',
        message: 'Thank you for your report. We will review it shortly.',
        icon: Icons.check_circle,
      );
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: 'Error',
        message: 'Failed to submit report: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isReporting = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (!await launchUrl(launchUri)) {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: 'Error',
        message: 'Failed to make call: ${e.toString()}',
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    try {
      final formattedNumber = MarketplaceService.formatPhoneForWhatsApp(
        phoneNumber,
      );
      final Uri whatsappUri = Uri.parse("https://wa.me/$formattedNumber");

      if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open WhatsApp');
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: 'Error',
        message: 'Failed to open WhatsApp: ${e.toString()}',
      );
    }
  }

  Widget _buildImageCarousel() {
    if (_product == null) return const SizedBox();

    final images = _product!.images;
    final hasImages = images.isNotEmpty;

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          // Image viewer
          PageView.builder(
            itemCount: hasImages ? images.length : 1,
            onPageChanged:
                (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              final imageUrl =
                  hasImages
                      ? images[index].imageUrl
                      : 'https://via.placeholder.com/400';

              return Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Image indicators
          if (hasImages && images.length > 1)
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentImageIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          _currentImageIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVariationList(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                items
                    .map(
                      (item) => Chip(
                        label: Text(item, style: const TextStyle(fontSize: 12)),
                        backgroundColor: theme.cardColor,
                        side: BorderSide(color: theme.dividerColor),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyDisclaimer() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Safety Tip: Meet in public places for transactions. Avoid sharing personal banking details.",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, {Color? color, VoidCallback? onTap}) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: color ?? theme.iconTheme.color?.withOpacity(0.7),
        size: 24,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load product',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProduct,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildErrorState(),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    final product = _product!;
    final seller = product.seller;
    final theme = Theme.of(context);
    final sellerPhone = seller?.phoneNumber ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Product Details"),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildSocialIcon(
            _isLiking ? Icons.favorite : Icons.favorite_border,
            color: _isLiking ? Colors.red : null,
            onTap: _handleLike,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel
                  _buildImageCarousel(),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Brand Tags
                        Row(
                          children: [
                            _buildTag(product.mainCategory, theme.primaryColor),
                            const SizedBox(width: 8),
                            if (product.brand != null)
                              _buildTag(product.brand!, Colors.blueGrey),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          product.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Price & Discount
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _currencyFormat.format(product.price),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                _currencyFormat.format(product.oldPrice!),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.hintColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.formattedDiscount,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 25),

                        // Description
                        Text(
                          "DESCRIPTION",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.hintColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Variations
                        if (product.availableSizes.isNotEmpty)
                          _buildVariationList(
                            "Available Sizes",
                            product.availableSizes,
                          ),
                        if (product.availableColors.isNotEmpty)
                          _buildVariationList(
                            "Available Colors",
                            product.availableColors,
                          ),

                        const SizedBox(height: 25),

                        // Seller Information
                        if (seller != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SELLER INFORMATION",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.hintColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.primaryColor
                                        .withOpacity(0.1),
                                    backgroundImage:
                                        seller.avatarUrl != null
                                            ? NetworkImage(seller.avatarUrl!)
                                            : null,
                                    child:
                                        seller.avatarUrl == null
                                            ? Text(
                                              seller.fullName[0].toUpperCase(),
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          seller.fullName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (seller.username != null)
                                          Text(
                                            '@${seller.username}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme.hintColor,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                        const SizedBox(height: 25),

                        // Safety Disclaimer
                        _buildSafetyDisclaimer(),
                        const SizedBox(height: 25),

                        // Social Actions
                        Row(
                          children: [
                            _buildSocialIcon(
                              Icons.share_outlined,
                              onTap: () {
                                // TODO: Implement share functionality
                              },
                            ),
                            const SizedBox(width: 20),
                            _buildSocialIcon(
                              Icons.report_gmailerrorred_outlined,
                              color: Colors.red,
                              onTap: _showReportDialog,
                            ),
                            const Spacer(),
                            Text(
                              "${product.viewsCount} Views • ${product.likesCount} Likes",
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Persistent Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (sellerPhone.isNotEmpty) ...[
                    Expanded(
                      child: _buildContactButton(
                        onPressed: () => _makePhoneCall(sellerPhone),
                        icon: Icons.call,
                        label: "Call",
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactButton(
                        onPressed: () => _openWhatsApp(sellerPhone),
                        icon: Icons.chat_bubble_outline,
                        label: "WhatsApp",
                        color: Colors.green,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        "No contact information available",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
