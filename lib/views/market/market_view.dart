// views/marketplace/market_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:juvapay/services/marketplace_service.dart';
import 'package:juvapay/services/state_service.dart';
import 'package:juvapay/models/marketplace_models.dart';
import 'package:juvapay/models/location_models.dart';
import 'package:juvapay/views/market/product_view.dart';
import 'package:juvapay/views/market/market_product_card.dart';
import 'package:juvapay/widgets/loading_indicator.dart';
import 'package:juvapay/widgets/error_state.dart';
import 'package:juvapay/views/market/marketplace_upload_page.dart';
import 'package:juvapay/widgets/empty_state.dart'; // Add this line


class MarketView extends StatefulWidget {
  const MarketView({super.key});

  @override
  State<MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends State<MarketView> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final StateService _stateService = StateService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State
  List<MarketplaceProduct> _products = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  // Filters
  String _selectedSort = 'newest';
  int? _selectedStateId;
  int? _selectedLgaId;
  String? _selectedCategory;
  String _searchQuery = '';

  // Available filters
  List<String> _categories = [];
  List<StateModel> _states = [];
  Map<int, List<LgaModel>> _lgasByState = {};
  bool _loadingStates = false;
  bool _loadingLgas = false;

@override
  void initState() {
    super.initState();
    debugPrint('MarketView initState called');
    _initializeData();
  }

  Future<void> _initializeData() async {
    debugPrint('Initializing market data...');
    await Future.wait([
      _loadProducts(refresh: true),
      _loadCategories(),
      _loadStates(),
    ]);
    debugPrint('Market data initialization complete');
    debugPrint('Products loaded: ${_products.length}');
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    debugPrint('Loading products, refresh: $refresh');

    if (!refresh && (!_hasMore || _isLoading)) return;

    setState(() {
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
        _products.clear();
      }
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      debugPrint('Calling marketplace service...');
      final newProducts = await _marketplaceService.getProducts(
        category: _selectedCategory,
        stateId: _selectedStateId,
        lgaId: _selectedLgaId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _getSortField(),
        ascending: _isAscending(),
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      debugPrint('Received ${newProducts.length} products from service');

      setState(() {
        _isLoading = false;
        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }
        _hasMore = newProducts.length == _pageSize;
        _currentPage++;

        // Debug: print all product titles
        for (var product in _products) {
          debugPrint(
            'Product: ${product.title}, Images: ${product.images.length}',
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error in _loadProducts: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load products: ${e.toString()}';
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _marketplaceService.getCategories();
      if (!mounted) return;

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadStates() async {
    if (_loadingStates) return;

    setState(() => _loadingStates = true);

    try {
      final states = await _stateService.getStates();
      if (!mounted) return;

      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingStates = false);
      debugPrint('Error loading states: $e');
    }
  }

  Future<void> _loadLgasForState(int stateId) async {
    if (_loadingLgas || _lgasByState.containsKey(stateId)) return;

    setState(() => _loadingLgas = true);

    try {
      final lgas = await _stateService.getLgasByState(stateId);
      if (!mounted) return;

      setState(() {
        _lgasByState[stateId] = lgas;
        _loadingLgas = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingLgas = false);
      debugPrint('Error loading LGAs: $e');
    }
  }

  String _getSortField() {
    switch (_selectedSort) {
      case 'price_low':
      case 'price_high':
        return 'price';
      case 'popular':
        return 'views_count';
      case 'likes':
        return 'likes_count';
      default:
        return 'created_at';
    }
  }

  bool _isAscending() {
    switch (_selectedSort) {
      case 'price_low':
        return true;
      case 'price_high':
        return false;
      case 'popular':
      case 'likes':
        return false;
      default:
        return false;
    }
  }

  void _applyFilters() {
    _currentPage = 0;
    _hasMore = true;
    _loadProducts(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedStateId = null;
      _selectedLgaId = null;
      _searchQuery = '';
      _selectedSort = 'newest';
    });
    _applyFilters();
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
                  if (_hasActiveFilters)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                          : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onSubmitted: (_) => _applyFilters(),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                children: [
                  // Sort
                  _buildFilterSection(
                    title: 'Sort By',
                    children: [
                      _buildFilterChip('Newest', 'newest', 'sort'),
                      _buildFilterChip(
                        'Price: Low to High',
                        'price_low',
                        'sort',
                      ),
                      _buildFilterChip(
                        'Price: High to Low',
                        'price_high',
                        'sort',
                      ),
                      _buildFilterChip('Most Popular', 'popular', 'sort'),
                      _buildFilterChip('Most Liked', 'likes', 'sort'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Categories
                  if (_categories.isNotEmpty)
                    _buildFilterSection(
                      title: 'Categories',
                      children: [
                        _buildFilterChip('All Categories', null, 'category'),
                        ..._categories
                            .take(10)
                            .map(
                              (category) => _buildFilterChip(
                                category,
                                category,
                                'category',
                              ),
                            )
                            .toList(),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // States
                  _buildFilterSection(
                    title: 'State',
                    children: [
                      if (_loadingStates)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _buildFilterChip('All States', null, 'state'),
                        ..._states
                            .take(10)
                            .map(
                              (state) => _buildFilterChip(
                                state.name,
                                state.id,
                                'state',
                              ),
                            )
                            .toList(),
                      ],
                    ],
                  ),

                  // LGAs (only show if a state is selected)
                  if (_selectedStateId != null) ...[
                    const SizedBox(height: 20),
                    _buildFilterSection(
                      title: 'LGA',
                      children: [
                        _buildFilterChip('All LGAs', null, 'lga'),
                        if (_loadingLgas)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_lgasByState[_selectedStateId] != null)
                          ..._lgasByState[_selectedStateId]!
                              .take(10)
                              .map(
                                (lga) =>
                                    _buildFilterChip(lga.name, lga.id, 'lga'),
                              )
                              .toList(),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Apply Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text(
                    "APPLY FILTERS",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }

  Widget _buildFilterChip(String label, dynamic value, String type) {
    bool isSelected = false;

    switch (type) {
      case 'sort':
        isSelected = _selectedSort == value;
        break;
      case 'category':
        isSelected = _selectedCategory == value;
        break;
      case 'state':
        isSelected = _selectedStateId == value;
        break;
      case 'lga':
        isSelected = _selectedLgaId == value;
        break;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _handleFilterSelection(label, value, type);
      },
    );
  }

  void _handleFilterSelection(String label, dynamic value, String type) async {
    switch (type) {
      case 'sort':
        setState(() => _selectedSort = value ?? 'newest');
        break;
      case 'category':
        setState(() => _selectedCategory = value);
        break;
      case 'state':
        setState(() {
          _selectedStateId = value;
          _selectedLgaId = null; // Reset LGA when state changes
        });

        // Load LGAs for selected state
        if (value != null) {
          await _loadLgasForState(value);
        }
        break;
      case 'lga':
        setState(() => _selectedLgaId = value);
        break;
    }
  }

  bool get _hasActiveFilters {
    return _selectedCategory != null ||
        _selectedStateId != null ||
        _selectedLgaId != null ||
        _searchQuery.isNotEmpty ||
        _selectedSort != 'newest';
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          // Load more indicator
          if (_hasMore && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadProducts();
            });
          }
          return _buildLoadingMore();
        }

        final product = _products[index];
        return MarketProductCard(
          product: product,
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductViewPage(productId: product.id),
              ),
            );
            if (!mounted) return;
            if (updated is MarketplaceProduct) {
              setState(() => _products[index] = updated);
            } else if (updated == true) {
              _loadProducts(refresh: true);
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingMore() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          "Marketplace",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadProducts(refresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceUploadPage(),
                ),
              ).then((result) {
                if (result == true) {
                  _loadProducts(refresh: true);
                }
              });
            },
          ),
        ],
      ),
      drawer: _buildFilterDrawer(),
      body:
          _isLoading && _products.isEmpty
              ? const Center(child: LoadingIndicator())
              : _hasError && _products.isEmpty
              ? NetworkErrorState(
                onRetry: () => _loadProducts(refresh: true),
                customMessage: _errorMessage ?? 'Failed to load products',
              )
              : _products.isEmpty
              ? NoProductsEmptyState(
                onAddProduct: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarketplaceUploadPage(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadProducts(refresh: true);
                    }
                  });
                },
                isMarketplace: true,
              )
              : RefreshIndicator(
                onRefresh: () => _loadProducts(refresh: true),
                child: _buildProductsGrid(),
              ),
    );
  }
}
