import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'services/theme_service.dart';
import 'services/cache_service.dart';
import 'services/network_service.dart';
import 'utils/app_themes.dart';
import 'view_models/registration_view_model.dart';
import 'view_models/wallet_view_model.dart';
import 'view_models/home_view_model.dart';
import 'views/onboarding/onboarding_view.dart';
import 'widgets/app_bottom_navbar.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Hive for caching
  await Hive.initFlutter();

  runApp(const JuvaPayApp());
}

class JuvaPayApp extends StatefulWidget {
  const JuvaPayApp({super.key});

  @override
  State<JuvaPayApp> createState() => _JuvaPayAppState();
}

class _JuvaPayAppState extends State<JuvaPayApp>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late CacheService _cacheService;
  late NetworkService _networkService;

  bool _isServicesInitialized = false;
  bool _hiveInitialized = false;

  // Animation controllers
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize animations
    _initializeAnimations();

    // Start services initialization
    _initializeServices();
  }

  void _initializeAnimations() {
    // Scale animation (pulse effect)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Fade animation for loading text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();

    WidgetsBinding.instance.removeObserver(this);
    if (_hiveInitialized) {
      _cacheService.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isServicesInitialized) return;

    if (state == AppLifecycleState.paused && _hiveInitialized) {
      _cacheService.close();
    } else if (state == AppLifecycleState.resumed && _hiveInitialized) {
      _cacheService.init();
    }
  }

  Future<void> _initializeServices() async {
    try {
      _cacheService = CacheService();
      await _cacheService.init();
      _hiveInitialized = true;
      _networkService = NetworkService();

      // Add a small delay for smooth animation
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isServicesInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  // Custom animated logo widget
  Widget _buildAnimatedSplashScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 80,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // App name with animation
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Text(
                      'JuvaPay',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // Loading indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Animated loading text
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Text(
                      'Initializing...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isServicesInitialized) {
      return _buildAnimatedSplashScreen();
    }

    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return ProviderScope(
      child: provider.MultiProvider(
        providers: [
          // 🟢 KEY FIX: Use ChangeNotifierProvider for ThemeService
          provider.ChangeNotifierProvider<ThemeService>(
            create: (_) => ThemeService(),
          ),

          provider.Provider<CacheService>(
            create: (_) => _cacheService,
            dispose: (_, service) => service.close(),
          ),
          provider.Provider<NetworkService>(
            create: (_) => _networkService,
            dispose: (_, service) => service.dispose(),
          ),
          provider.ChangeNotifierProvider<RegistrationViewModel>(
            create: (_) => RegistrationViewModel(),
          ),
          provider.ChangeNotifierProvider<WalletViewModel>(
            create: (_) => WalletViewModel(),
          ),
          provider.ChangeNotifierProxyProvider2<
            CacheService,
            NetworkService,
            HomeViewModel
          >(
            create:
                (context) => HomeViewModel(
                  cacheService: context.read<CacheService>(),
                  networkService: context.read<NetworkService>(),
                ),
            update: (context, cacheService, networkService, homeViewModel) {
              return homeViewModel ??
                  HomeViewModel(
                    cacheService: cacheService,
                    networkService: networkService,
                  );
            },
          ),
        ],
        child: provider.Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'JuvaPay',
              theme: lightTheme(),
              darkTheme: darkTheme(),
              // This now updates correctly because of ChangeNotifierProvider
              themeMode: themeService.themeMode,
              home:
                  isLoggedIn
                      ? const AppBottomNavigationBar()
                      : const OnboardingView(),
              routes: {
                '/home': (context) => const AppBottomNavigationBar(),
                '/onboarding': (context) => const OnboardingView(),
              },
            );
          },
        ),
      ),
    );
  }
}
