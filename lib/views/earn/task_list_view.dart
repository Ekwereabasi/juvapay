import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/home_view_model.dart';
import '../../models/task_models.dart';
import '../../widgets/task_filter_sheet.dart';
import '../tasks/task_details_view.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  String _selectedCategory = 'All';
  String _selectedPlatform = 'All';
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more tasks if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    // Filter tasks based on selections
    final filteredTasks = viewModel.filterTasks(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      platform: _selectedPlatform == 'All' ? null : _selectedPlatform,
      searchQuery: _searchQuery,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              _showFilterBottomSheet(context, viewModel);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              viewModel.refreshAll();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Filter Chips
          if (_selectedCategory != 'All' || _selectedPlatform != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedCategory != 'All')
                    FilterChip(
                      label: Text('Category: $_selectedCategory'),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_selectedPlatform != 'All')
                    FilterChip(
                      label: Text('Platform: $_selectedPlatform'),
                      onSelected: (selected) {
                        setState(() {
                          _selectedPlatform = 'All';
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                ],
              ),
            ),
          // Task Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredTasks.length} tasks available',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const Spacer(),
                if (viewModel.isOffline)
                  const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Offline Mode',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Tasks List
          Expanded(
            child:
                filteredTasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try a different search term'
                                : 'Check back later for new tasks',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async {
                        await viewModel.refreshAll();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return _buildTaskItem(context, viewModel, task);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    HomeViewModel viewModel,
    TaskModel task,
  ) {
    final theme = Theme.of(context);
    final platforms = task.platforms;
    final category = task.category;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsView(task: task),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: viewModel.getTaskCategoryColor(category),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      viewModel.getTaskIcon(task),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    category == 'advert'
                                        ? Colors.blue
                                        : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₦${task.price.toStringAsFixed(2)} per task",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Platform icons
                            ...platforms
                                .take(3)
                                .map(
                                  (platform) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      viewModel.getPlatformIcon(platform),
                                      size: 20,
                                      color: viewModel.getPlatformColor(
                                        platform,
                                      ),
                                    ),
                                  ),
                                ),
                            if (platforms.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '+${platforms.length - 3} more',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            // Featured badge
                            if (task.isFeatured)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            // Difficulty badge
                            if (task.difficulty != null)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(task.difficulty!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task.difficulty!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Estimated time
                        if (task.estimatedTime != null)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${task.estimatedTime} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailsView(task: task),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'VIEW DETAILS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterBottomSheet(BuildContext context, HomeViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return TaskFilterSheet(
          currentCategory: _selectedCategory,
          currentPlatform: _selectedPlatform,
          onApplyFilters: (category, platform) {
            setState(() {
              _selectedCategory = category;
              _selectedPlatform = platform;
            });
            Navigator.pop(context);
          },
          onClearFilters: () {
            setState(() {
              _selectedCategory = 'All';
              _selectedPlatform = 'All';
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
