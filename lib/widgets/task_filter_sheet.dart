// widgets/task_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/home_view_model.dart';
import '../utils/platform_helper.dart';
import '../utils/task_helper.dart';

class TaskFilterSheet extends StatefulWidget {
  final String currentCategory;
  final String currentPlatform;
  final Function(String, String) onApplyFilters;
  final VoidCallback onClearFilters;

  const TaskFilterSheet({
    super.key,
    required this.currentCategory,
    required this.currentPlatform,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late String _selectedCategory;
  late String _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
    _selectedPlatform = widget.currentPlatform;
  }

  @override
  Widget build(BuildContext context) {
    // Get HomeViewModel from Provider instead of creating new instance
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);

    // Get dynamic categories from tasks
    final categories = _getAvailableCategories(viewModel);
    // Get dynamic platforms from tasks
    final platforms = _getAvailablePlatforms(viewModel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Tasks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category filter
          const Text(
            'Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                categories.map((category) {
                  return FilterChip(
                    label: Text(
                      category == 'All'
                          ? 'All Categories'
                          : TaskHelper.getTaskCategoryDisplayName(category),
                    ),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),

          // Platform filter
          const Text(
            'Platform',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                platforms.map((platform) {
                  return FilterChip(
                    label: Text(
                      platform == 'All'
                          ? 'All Platforms'
                          : PlatformHelper.getPlatformDisplayName(platform),
                    ),
                    selected: _selectedPlatform == platform,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPlatform = selected ? platform : 'All';
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 30),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CLEAR ALL'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilters(_selectedCategory, _selectedPlatform);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'APPLY FILTERS',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper method to get available categories from tasks
  List<String> _getAvailableCategories(HomeViewModel viewModel) {
    // Start with 'All' option
    final categories = <String>['All'];

    // Get unique categories from tasks
    final uniqueCategories =
        viewModel.tasks.map((task) => task.category).toSet().toList();

    // Sort categories
    uniqueCategories.sort();

    // Add to the list
    categories.addAll(uniqueCategories);

    return categories;
  }

  // Helper method to get available platforms from tasks
  List<String> _getAvailablePlatforms(HomeViewModel viewModel) {
    // Start with 'All' option
    final platforms = <String>['All'];

    // Get all platforms from all tasks
    final allPlatforms = <String>{};

    for (final task in viewModel.tasks) {
      allPlatforms.addAll(task.platforms);
    }

    // Convert to list and sort
    final sortedPlatforms = allPlatforms.toList()..sort();

    // Add to the list
    platforms.addAll(sortedPlatforms);

    return platforms;
  }
}
