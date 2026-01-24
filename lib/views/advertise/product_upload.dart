import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:juvapay/services/supabase_auth_service.dart';

// --- MODELS ---
class StateModel {
  final int id;
  final String name;
  StateModel({required this.id, required this.name});
  factory StateModel.fromJson(Map<String, dynamic> json) =>
      StateModel(id: json['id'], name: json['name']);
}

class LgaModel {
  final int id;
  final String name;
  LgaModel({required this.id, required this.name});
  factory LgaModel.fromJson(Map<String, dynamic> json) =>
      LgaModel(id: json['id'], name: json['name']);
}

class MarketplaceUploadPage extends StatefulWidget {
  const MarketplaceUploadPage({super.key});

  @override
  State<MarketplaceUploadPage> createState() => _MarketplaceUploadPageState();
}

class _MarketplaceUploadPageState extends State<MarketplaceUploadPage> {
  final _authService = SupabaseAuthService();
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _descController = TextEditingController();
  final _policyController = TextEditingController();
  final _subCat1Controller = TextEditingController();
  final _subCat2Controller = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();

  // --- STATE VARIABLES ---
  List<File> _selectedImages = [];
  List<String> _sizes = [];
  List<String> _colors = [];
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  List<StateModel> _states = [];
  List<LgaModel> _lgas = [];
  StateModel? _selectedState;
  LgaModel? _selectedLga;

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
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _fetchStates();
    _policyController.text =
        "Standard 7-day return policy. Item must be in original condition.";
  }

  // --- LOGIC METHODS ---
  Future<void> _fetchStates() async {
    try {
      final List<dynamic> data = await supabase
          .from('states')
          .select('id, name')
          .order('name');
      setState(
        () => _states = data.map((item) => StateModel.fromJson(item)).toList(),
      );
    } catch (e) {
      debugPrint("Error fetching states: $e");
    }
  }

  Future<void> _fetchLgas(int stateId) async {
    setState(() => _isLocationLoading = true);
    try {
      final List<dynamic> data = await supabase
          .from('lgas')
          .select()
          .eq('state_id', stateId)
          .order('name');
      setState(() {
        _lgas = data.map((item) => LgaModel.fromJson(item)).toList();
        _selectedLga = null;
      });
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  void _handleSubmitPress() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty)
        return _showSnackBar("Please add at least one image", isError: true);
      if (_selectedState == null || _selectedLga == null)
        return _showSnackBar("Please select your location", isError: true);
      _showConfirmationModal();
    }
  }

  void _showConfirmationModal() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text("Confirm Advert", style: theme.textTheme.titleLarge),
            content: const Text(
              "Post this product? If no active subscription, ₦1,000 will be deducted.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "NO",
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _processUpload();
                },
                child: const Text("YES"),
              ),
            ],
          ),
    );
  }

  Future<void> _processUpload() async {
    setState(() => _isLoading = true);
    try {
      bool hasSub = await _authService.hasActiveSubscription();
      if (!hasSub) {
        String payResult = await _authService.processAdvertPayment();
        if (payResult == "INSUFFICIENT_FUNDS") {
          _showFundWalletDialog();
          return;
        }
      }

      await _authService.submitProduct(
        title: _titleController.text.trim(),
        brand: _brandController.text.trim(),
        price: double.parse(_priceController.text.replaceAll(',', '')),
        oldPrice:
            _oldPriceController.text.isNotEmpty
                ? double.parse(_oldPriceController.text.replaceAll(',', ''))
                : null,
        quantity: int.parse(_qtyController.text),
        description: _descController.text.trim(),
        mainCategory: _selectedCategory ?? 'Other',
        subCategory1: _subCat1Controller.text.trim(),
        subCategory2: _subCat2Controller.text.trim(),
        sizes: _sizes,
        colors: _colors,
        returnPolicy: _policyController.text.trim(),
        imageFiles: _selectedImages,
        stateId: _selectedState!.id,
        lgaId: _selectedLga!.id,
      );

      if (mounted) {
        _showSnackBar("Product Uploaded Successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFundWalletDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Insufficient Funds"),
            content: const Text(
              "Your wallet balance is below ₦1,000. Please fund your wallet.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Post New Advert", style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoSection(theme),
                      const SizedBox(height: 25),
                      _buildSectionHeader(theme, "Location"),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<StateModel>(
                              theme: theme,
                              value: _selectedState,
                              hint: "State",
                              items: _states,
                              itemLabel: (item) => item.name,
                              onChanged: (s) {
                                setState(() => _selectedState = s);
                                _fetchLgas(s!.id);
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildDropdownField<LgaModel>(
                              theme: theme,
                              value: _selectedLga,
                              hint: "LGA",
                              items: _lgas,
                              itemLabel: (item) => item.name,
                              isLoading: _isLocationLoading,
                              onChanged:
                                  (l) => setState(() => _selectedLga = l),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildSectionHeader(theme, "Basic Information"),
                      _buildTextField(
                        controller: _titleController,
                        hint: "Product Title",
                        icon: Icons.title,
                        theme: theme,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _brandController,
                        hint: "Brand Name",
                        icon: Icons.branding_watermark,
                        theme: theme,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _priceController,
                              hint: "Price",
                              prefixText: "₦",
                              isNumber: true,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _oldPriceController,
                              hint: "Old Price",
                              prefixText: "₦",
                              isNumber: true,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _qtyController,
                              hint: "Qty",
                              isNumber: true,
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _descController,
                        hint: "Full Description...",
                        icon: Icons.description,
                        maxLines: 4,
                        theme: theme,
                      ),
                      const SizedBox(height: 25),
                      _buildSectionHeader(theme, "Return Policy"),
                      _buildTextField(
                        controller: _policyController,
                        hint: "Enter policy...",
                        icon: Icons.security,
                        maxLines: 2,
                        theme: theme,
                      ),
                      const SizedBox(height: 25),
                      _buildSectionHeader(theme, "Variations"),
                      _buildTagInput(
                        _sizeController,
                        _sizes,
                        "Sizes (S, M, L)",
                        theme,
                      ),
                      const SizedBox(height: 15),
                      _buildTagInput(
                        _colorController,
                        _colors,
                        "Colors (Red, Blue)",
                        theme,
                      ),
                      const SizedBox(height: 25),

                      // --- UPDATED CATEGORY SECTION ---
                      _buildSectionHeader(theme, "Category"),
                      _buildDropdownField<String>(
                        theme: theme,
                        value: _selectedCategory,
                        hint: "Select Main Category",
                        items: _categories,
                        itemLabel: (i) => i,
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: 15),
                      // Subcategory inputs added below
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _subCat1Controller,
                              hint: "Sub Category 1",
                              icon: Icons.subdirectory_arrow_right,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _subCat2Controller,
                              hint: "Sub Category 2",
                              icon: Icons.subdirectory_arrow_right,
                              theme: theme,
                            ),
                          ),
                        ],
                      ),

                      // ---------------------------------
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _handleSubmitPress,
                          child: const Text(
                            "SUBMIT ADVERT",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.hintColor,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () async {
              final picked = await ImagePicker().pickMultiImage();
              if (picked.isNotEmpty) {
                setState(
                  () => _selectedImages.addAll(picked.map((e) => File(e.path))),
                );
              }
            },
            child: DottedBorder(
              color: theme.primaryColor.withOpacity(0.5),
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: Container(
                width: 90,
                height: 100,
                color: theme.primaryColor.withOpacity(0.05),
                child: Icon(Icons.add_a_photo, color: theme.primaryColor),
              ),
            ),
          ),
          ..._selectedImages.asMap().entries.map(
            (entry) => Stack(
              children: [
                Container(
                  width: 90,
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(entry.value),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap:
                        () =>
                            setState(() => _selectedImages.removeAt(entry.key)),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? prefixText,
    bool isNumber = false,
    int maxLines = 1,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        prefixText: prefixText,
        filled: true,
        fillColor: theme.cardColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required ThemeData theme,
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required Function(T?) onChanged,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child:
          isLoading
              ? const LinearProgressIndicator()
              : DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  hint: Text(hint),
                  dropdownColor: theme.cardColor,
                  items:
                      items
                          .map(
                            (i) => DropdownMenuItem<T>(
                              value: i,
                              child: Text(itemLabel(i)),
                            ),
                          )
                          .toList(),
                  onChanged: onChanged,
                ),
              ),
    );
  }

  Widget _buildTagInput(
    TextEditingController controller,
    List<String> list,
    String hint,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: controller,
          hint: hint,
          theme: theme,
          icon: Icons.add_circle_outline,
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          children:
              list
                  .map(
                    (tag) => Chip(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      label: Text(
                        tag,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                      onDeleted: () => setState(() => list.remove(tag)),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}
