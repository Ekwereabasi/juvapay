import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_view.dart';
import 'market_product_card.dart';
import '../advertise/product_upload.dart';

class MarketView extends StatefulWidget {
  const MarketView({super.key});

  @override
  State<MarketView> createState() => _MarketViewPageState();
}

class _MarketViewPageState extends State<MarketView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Product State
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<dynamic> _products = [];

  // Filter State
  String _selectedSort = 'Most Popular';
  bool _isLoadingStates = false;
  bool _isLoadingLgas = false;
  List<StateModel> _states = [];
  List<LgaModel> _lgas = [];
  StateModel? _selectedState;
  LgaModel? _selectedLga;

  final List<String> _sortOptions = [
    'Most Popular',
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
  ];

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

  // Track if this is initial load to prevent unnecessary snackbars
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Load both products and states in parallel for faster loading
      await Future.wait([_fetchProducts(), _fetchStates()]);
    } catch (e) {
      debugPrint("Error initializing data: $e");
      // Only show snackbar on subsequent loads, not initial load
      if (!_isInitialLoad && mounted) {
        _showSnackBar(
          "Failed to load some data. Please try again.",
          isError: true,
        );
      }
    } finally {
      _isInitialLoad = false;
    }
  }
  

  Future<void> _fetchProducts() async {
    if (_products.isEmpty) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final data = await _supabase
          .from('marketplace_products')
          .select('''
          *,
          marketplace_product_images(*),
          profiles!inner(*)
        ''')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
          _hasError = false;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint("Timeout fetching products: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Request timed out. Please check your connection.";
        });
      }
      if (!_isInitialLoad && mounted) {
        _showSnackBar(
          "Request timed out. Please check your connection.",
          isError: true,
        );
      }
    } on PostgrestException catch (e) {
      debugPrint("Database error fetching products: $e");
      debugPrint("Full error details: ${e.toJson()}");

      // Try a simpler query if the complex one fails
      try {
        debugPrint("Trying simpler query without profile join...");
        final simpleData = await _supabase
            .from('marketplace_products')
            .select('''
            *,
            marketplace_product_images(*)
          ''')
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _products = simpleData;
            _isLoading = false;
            _hasError = false;
          });
        }
      } catch (simpleError) {
        debugPrint("Simple query also failed: $simpleError");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = false; // Show empty state instead of error
            _products = [];
          });
        }
        if (!_isInitialLoad && mounted) {
          _showSnackBar(
            "No products available yet. Be the first to list one!",
            isError: false,
          );
        }
      }
    } catch (e) {
      debugPrint("Unexpected error fetching products: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false; // Show empty state
          _products = [];
        });
      }
      // Only show snackbar on subsequent loads
      if (!_isInitialLoad && mounted) {
        _showSnackBar(
          "Marketplace is empty. Start selling today!",
          isError: false,
        );
      }
    }
  }

  Future<void> _fetchStates() async {
    setState(() => _isLoadingStates = true);

    try {
      final response = await _supabase.from('states').select().order('name');

      final List<StateModel> loadedStates =
          (response as List).map((e) => StateModel.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _states = loadedStates;
          _isLoadingStates = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching states: $e");
      if (mounted) {
        setState(() => _isLoadingStates = false);
      }
    }
  }

  Future<void> _fetchLgas(int stateId) async {
    setState(() => _isLoadingLgas = true);

    try {
      final response = await _supabase
          .from('lgas')
          .select()
          .eq('state_id', stateId)
          .order('name');

      final List<LgaModel> loadedLgas =
          (response as List).map((e) => LgaModel.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _lgas = loadedLgas;
          _isLoadingLgas = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching LGAs: $e");
      if (mounted) {
        setState(() => _isLoadingLgas = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(
      context,
    ).removeCurrentSnackBar(); // Remove any existing snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    _isInitialLoad = false; // After first refresh, treat as non-initial
    await _fetchProducts();
  }

  void _handleStateChange(StateModel? newValue) {
    if (newValue?.id == _selectedState?.id) return; // No change

    setState(() {
      _selectedState = newValue;
      _selectedLga = null;
      _lgas = [];
    });

    if (newValue != null) {
      _fetchLgas(newValue.id);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
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
              _errorMessage ?? 'Failed to load products',
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
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _fetchProducts();
              },
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 60,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No products found",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Be the first to list a product in the marketplace!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarketplaceUploadPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('List Your Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return MarketProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductViewPage(product: product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDrawer() {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.cardColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Text(
                    "Filters",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedState != null || _selectedLga != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedState = null;
                          _selectedLga = null;
                          _lgas = [];
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),

            // Categories
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                "Categories",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                itemCount: _categories.length,
                separatorBuilder:
                    (ctx, i) => Divider(height: 1, color: theme.dividerColor),
                itemBuilder:
                    (context, index) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _categories[index],
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar("Filtering by: ${_categories[index]}");
                      },
                      dense: true,
                    ),
              ),
            ),

            Divider(color: theme.dividerColor),

            // Filters Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Filter
                  Text(
                    "Location",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // State Dropdown
                  Text("State", style: TextStyle(color: theme.hintColor)),
                  const SizedBox(height: 4),
                  _buildStateDropdown(theme),

                  // LGA Dropdown (Conditional)
                  if (_selectedState != null) ...[
                    const SizedBox(height: 12),
                    Text("LGA", style: TextStyle(color: theme.hintColor)),
                    const SizedBox(height: 4),
                    _buildLgaDropdown(theme),
                  ],

                  const SizedBox(height: 20),

                  // Sort By
                  Text(
                    "Sort By",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSortDropdown(theme),
                ],
              ),
            ),

            // Post Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarketplaceUploadPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    "POST YOUR PRODUCTS/SERVICES",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          _isLoadingStates
              ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
              : DropdownButtonHideUnderline(
                child: DropdownButton<StateModel>(
                  isExpanded: true,
                  dropdownColor: theme.cardColor,
                  value: _selectedState,
                  hint: Text(
                    "All Nigeria",
                    style: TextStyle(color: theme.hintColor),
                  ),
                  items: [
                    DropdownMenuItem<StateModel>(
                      value: null,
                      child: Text(
                        "All Nigeria",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    ..._states
                        .map(
                          (state) => DropdownMenuItem<StateModel>(
                            value: state,
                            child: Text(
                              state.name,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: _handleStateChange,
                ),
              ),
    );
  }

  Widget _buildLgaDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          _isLoadingLgas
              ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
              : DropdownButtonHideUnderline(
                child: DropdownButton<LgaModel>(
                  isExpanded: true,
                  dropdownColor: theme.cardColor,
                  value: _selectedLga,
                  hint: Text(
                    "All LGAs",
                    style: TextStyle(color: theme.hintColor),
                  ),
                  items: [
                    DropdownMenuItem<LgaModel>(
                      value: null,
                      child: Text(
                        "All LGAs",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    ..._lgas
                        .map(
                          (lga) => DropdownMenuItem<LgaModel>(
                            value: lga,
                            child: Text(
                              lga.name,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (newValue) {
                    setState(() => _selectedLga = newValue);
                  },
                ),
              ),
    );
  }

  Widget _buildSortDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: theme.cardColor,
          value: _selectedSort,
          items:
              _sortOptions
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: theme.textTheme.bodyMedium),
                    ),
                  )
                  .toList(),
          onChanged: (newValue) {
            setState(() => _selectedSort = newValue!);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.iconTheme.color),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          "Marketplace",
          style:
              theme.appBarTheme.titleTextStyle ??
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      drawer: _buildFilterDrawer(),
      body:
          _isLoading
              ? _buildLoadingState()
              : _hasError && _products.isEmpty
              ? _buildErrorState()
              : _products.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                color: theme.primaryColor,
                backgroundColor: theme.cardColor,
                onRefresh: _handleRefresh,
                child: _buildProductsGrid(),
              ),
    );
  }
}

class StateModel {
  final int id;
  final String name;

  StateModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory StateModel.fromJson(Map<String, dynamic> json) =>
      StateModel(id: json['id'], name: json['name']);
}

class LgaModel {
  final int id;
  final String name;

  LgaModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LgaModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory LgaModel.fromJson(Map<String, dynamic> json) =>
      LgaModel(id: json['id'], name: json['name']);
}
