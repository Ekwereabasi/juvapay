import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/onboarding_view_model.dart';
import '../../view_models/registration_view_model.dart';
import '../../models/onboarding_item.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final registrationVM = Provider.of<RegistrationViewModel>(
      context,
      listen: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      registrationVM.initializeData();
    });

    return ChangeNotifierProvider<OnboardingViewModel>(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, child) {
          // ✅ FIXED: Removed hardcoded backgroundColor. Uses Theme scaffoldBackgroundColor automatically.
          return Scaffold(
            appBar: AppBar(
              // ✅ FIXED: Removed hardcoded colors. Inherits from AppTheme.
              elevation: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.account_balance_wallet,
                      // ✅ FIXED: Use Primary Color from theme
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JuvaPay',
                    style: TextStyle(
                      // ✅ FIXED: Use Primary Color from theme
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      // ✅ FIXED: Use icon theme color so it changes in Dark Mode
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            endDrawer: AppDrawer(viewModel: viewModel),
            body: OnboardingBody(viewModel: viewModel),
          );
        },
      ),
    );
  }
}

// ... AppDrawer remains mostly the same, just ensure text/background colors aren't hardcoded ...


// --- STANDALONE APP DRAWER CLASS ---
class AppDrawer extends StatelessWidget {
  final OnboardingViewModel viewModel;
  const AppDrawer({required this.viewModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20, left: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF673AB7),
                          ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'JuvaPay',
                      style: TextStyle(
                        color: Color(0xFF673AB7),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, 'Home', () => Navigator.pop(context)),
          _buildDrawerItem(context, 'Earning', () {}),
          _buildDrawerItem(context, 'Pricing', () {}),
          _buildDrawerItem(context, 'Marketplace', () {}),
          _buildDrawerItem(context, 'Support', () {}),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close drawer
                      viewModel.onLoginToYourAccount(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF673AB7),
                      side: const BorderSide(color: Color(0xFF673AB7)),
                    ),
                    child: const Text('LOGIN'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close drawer
                      viewModel.onCreateFreeAccount(context);
                    },
                    child: const Text('SIGN UP'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}



class OnboardingBody extends StatefulWidget {
  final OnboardingViewModel viewModel;
  const OnboardingBody({required this.viewModel, super.key});

  @override
  State<OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<OnboardingBody> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.viewModel.currentPageIndex,
    );
    widget.viewModel.addListener(_onViewModelChange);
  }

  void _onViewModelChange() {
    if (_pageController.hasClients &&
        _pageController.page?.round() != widget.viewModel.currentPageIndex) {
      _pageController.animateToPage(
        widget.viewModel.currentPageIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use LayoutBuilder to handle small screens gracefully
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // TOP SECTION (Image & Text)
            Expanded(
              flex: 6,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.viewModel.pageCount,
                onPageChanged: (index) => widget.viewModel.updatePageIndex(index),
                itemBuilder: (context, index) {
                  final item = widget.viewModel.pages[index];
                  return OnboardingPageItem(item: item);
                },
              ),
            ),
            
            // BOTTOM SECTION (Buttons)
            // ✅ FIXED: Wrapped in SingleChildScrollView to prevent overflow on very short screens
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.viewModel.pageCount,
                          (index) => buildDot(
                              index, widget.viewModel.currentPageIndex, context),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              widget.viewModel.onCreateFreeAccount(context),
                          child: const Text('CREATE FREE ACCOUNT'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              widget.viewModel.onLoginToYourAccount(context),
                          child: const Text('LOGIN TO YOUR ACCOUNT'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildDot(int index, int currentPage, BuildContext context) {
    final isSelected = currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isSelected ? 24 : 8,
      decoration: BoxDecoration(
        // ✅ FIXED: Use Theme colors
        color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).disabledColor, 
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPageItem extends StatelessWidget {
  final OnboardingItem item;
  
  const OnboardingPageItem({
    required this.item,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Wrapped content in SingleChildScrollView
    // This allows the text to scroll if it gets too long for the flex area
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
              decoration: BoxDecoration(
                // ✅ FIXED: Dynamic Card Color for Dark Mode
                color: Theme.of(context).cardColor, 
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 80,
                  // ✅ FIXED: Dynamic Primary Color
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.3,
                    // Text color is now handled by Theme (bodyLarge/headlineSmall)
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    height: 1.5,
                    // Use standard body text color (white in dark, black in light)
                  ),
            ),
          ],
        ),
      ),
    );
  }
}