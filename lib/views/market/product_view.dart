import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductViewPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductViewPage({super.key, required this.product});

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  int _currentImageIndex = 0;
  final SupabaseAuthService _service = SupabaseAuthService();

  @override
  void initState() {
    super.initState();
    // Safely increment view using the BIGINT id
    if (widget.product['id'] != null) {
      _service.incrementView(widget.product['id']);
    }
  }

  // --- ACTIONS & DIALOGS ---

  void _showReportBottomSheet() {
    final theme = Theme.of(context);
    final List<String> reasons = [
      "Fraudulent/Scam Advert",
      "Inappropriate/Offensive Content",
      "Counterfeit Item",
      "Wrong Category",
      "Price is misleading",
      "Other",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Report this Product",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Why are you reporting this advert?",
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: reasons.length,
                    itemBuilder:
                        (context, index) => ListTile(
                          title: Text(
                            reasons[index],
                            style: theme.textTheme.bodyMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () async {
                            Navigator.pop(context);
                            _submitReport(reasons[index]);
                          },
                        ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _submitReport(String reason) async {
    try {
      await _service.reportProduct(
        productId: widget.product['id'],
        reason: reason,
        details: "Reported from mobile app view.",
      );
      _showSnackBar("Report submitted successfully. We will investigate.");
    } catch (e) {
      _showErrorSnackBar("Failed to submit report. Please try again.");
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String formattedNum = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (formattedNum.startsWith('0')) {
      formattedNum = '234${formattedNum.substring(1)}';
    } else if (formattedNum.startsWith('+')) {
      formattedNum = formattedNum.substring(1);
    }
    final Uri whatsappUri = Uri.parse("https://wa.me/$formattedNum");
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar('Could not open WhatsApp.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatCurrency = NumberFormat.simpleCurrency(
      name: 'NGN',
      decimalDigits: 0,
    );

    final images = widget.product['marketplace_product_images'] as List? ?? [];
    final profile = widget.product['profiles'] ?? {};
    final String sellerPhone = profile['phone_number'] ?? "";
    final double? oldPrice =
        widget.product['old_price'] != null
            ? double.tryParse(widget.product['old_price'].toString())
            : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // No EndDrawer here anymore
      appBar: AppBar(
        title: Text("View Product", style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        // No Search Action here anymore
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE CAROUSEL
            _buildImageCarousel(images, theme),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. CATEGORY & BRAND TAGS
                  Row(
                    children: [
                      _buildTag(
                        widget.product['main_category'] ?? 'General',
                        theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildTag(
                        widget.product['brand'] ?? "Generic",
                        Colors.blueGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. TITLE
                  Text(
                    widget.product['title'] ?? 'Untitled Product',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. PRICE & OLD PRICE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatCurrency.format(widget.product['price'] ?? 0),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      if (oldPrice != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          formatCurrency.format(oldPrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 5. DESCRIPTION
                  Text(
                    "DESCRIPTION",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.hintColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product['description'] ?? 'No description provided.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 25),

                  // 6. VARIATIONS
                  if (widget.product['available_sizes'] != null)
                    _buildVariationList(
                      "Available Sizes",
                      widget.product['available_sizes'],
                      theme,
                    ),
                  if (widget.product['available_colors'] != null)
                    _buildVariationList(
                      "Available Colors",
                      widget.product['available_colors'],
                      theme,
                    ),

                  const SizedBox(height: 25),

                  // 7. SAFETY DISCLAIMER
                  _buildSafetyDisclaimer(theme),
                  const SizedBox(height: 30),

                  // 8. SOCIAL ACTIONS & VIEWS
                  Row(
                    children: [
                      _buildSocialIcon(theme, Icons.favorite_border),
                      const SizedBox(width: 20),
                      _buildSocialIcon(theme, Icons.share_outlined),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _showReportBottomSheet,
                        child: _buildSocialIcon(
                          theme,
                          Icons.report_gmailerrorred_outlined,
                          color: Colors.red,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${(widget.product['views_count'] ?? 0)} Views",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120), // Bottom padding for actions
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildPersistentActions(theme, sellerPhone),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildImageCarousel(List images, ThemeData theme) {
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.isNotEmpty ? images.length : 1,
            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
            itemBuilder: (context, index) {
              final imgUrl =
                  images.isNotEmpty
                      ? images[index]['image_url']
                      : 'https://via.placeholder.com/400';
              return Image.network(
                imgUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
          if (images.length > 1)
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
                              ? theme.primaryColor
                              : Colors.white.withOpacity(0.5),
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

  Widget _buildVariationList(String title, dynamic items, ThemeData theme) {
    final List list = items is List ? items : [];
    if (list.isEmpty) return const SizedBox.shrink();
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
                list
                    .map(
                      (i) => Chip(
                        label: Text(
                          i.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
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

  Widget _buildSafetyDisclaimer(ThemeData theme) {
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
              "Safety Tip: Avoid direct bank transfers. Pay securely on our platform to protect your funds.",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentActions(ThemeData theme, String phone) {
    return Container(
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
            Expanded(
              child: _buildContactButton(
                onPressed:
                    phone.isNotEmpty ? () => _makePhoneCall(phone) : null,
                icon: Icons.call,
                label: "Call",
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactButton(
                onPressed: phone.isNotEmpty ? () => _openWhatsApp(phone) : null,
                icon: Icons.chat_bubble_outline,
                label: "WhatsApp",
                color: Colors.green,
              ),
            ),
          ],
        ),
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

  Widget _buildSocialIcon(ThemeData theme, IconData icon, {Color? color}) {
    return Icon(icon, color: color ?? theme.iconTheme.color?.withOpacity(0.7));
  }
}
