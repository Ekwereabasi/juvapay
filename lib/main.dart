import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:app_links/app_links.dart';
import 'dart:async';

// Services
import 'services/theme_service.dart';
import 'services/cache_service.dart';
import 'services/network_service.dart';

// Utils
import 'utils/app_themes.dart';

// View Models
import 'view_models/registration_view_model.dart';
import 'view_models/wallet_view_model.dart';
import 'view_models/home_view_model.dart';

// Views
import 'views/onboarding/onboarding_view.dart';
import 'views/auth/reset_password_page.dart';
import 'widgets/app_bottom_navbar.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Load environment variables
    print("🔄 Loading environment variables...");
    try {
      await dotenv.load(fileName: ".env");
      print("✅ Environment variables loaded successfully");
    } catch (e) {
      print("⚠️ Warning: Failed to load .env file: $e");
      // For debugging, you can set default values or continue without .env
    }

    // 2. Initialize Hive FIRST (it's lightweight)
    print("🔄 Initializing Hive...");
    await Hive.initFlutter();
    print("✅ Hive initialized successfully");

    // 3. Initialize Supabase (check for null values)
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    print("🔑 Supabase URL: ${supabaseUrl.isNotEmpty ? 'FOUND' : 'MISSING'}");
    print("🔑 Supabase Key: ${supabaseKey.isNotEmpty ? 'FOUND' : 'MISSING'}");

    bool supabaseInitialized = false;
    
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      print("⚠️ Supabase credentials are empty! Check your .env file");
      print("SUPABASE_URL: ${supabaseUrl.isEmpty ? 'MISSING' : 'FOUND'}");
      print("SUPABASE_ANON_KEY: ${supabaseKey.isEmpty ? 'MISSING' : 'FOUND'}");
      supabaseInitialized = false;
    } else {
      try {
        print("🔄 Initializing Supabase...");
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
          // authCallbackUrlHostname: 'login', // Optional: for deep links
        );
        print("✅ Supabase initialized successfully");
        supabaseInitialized = true;
      } catch (e) {
        print("❌ Supabase initialization failed: $e");
        supabaseInitialized = false;
      }
    }

    // 4. Start app
    print("🚀 Starting app...");
    runApp(JuvaPayApp(initializeSupabase: supabaseInitialized));
  } catch (error, stackTrace) {
    print('❌ App initialization failed: $error');
    print('Stack trace: $stackTrace');
    // Show error screen
    runApp(ErrorApp(error: error.toString()));
  }
}

class JuvaPayApp extends StatefulWidget {
  final bool initializeSupabase;

  const JuvaPayApp({super.key, required this.initializeSupabase});

  @override
  State<JuvaPayApp> createState() => _JuvaPayAppState();
}

class _JuvaPayAppState extends State<JuvaPayApp> with WidgetsBindingObserver {
  late CacheService _cacheService;
  late NetworkService _networkService;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri?>? _linkSubscription;

  // App state
  bool _isServicesInitialized = false;
  bool _isSupabaseInitialized = false;
  bool _isDeepLinkHandled = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start initialization immediately
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print("🔄 Starting app initialization...");

    try {
      // Check if Supabase should be initialized
      _isSupabaseInitialized = widget.initializeSupabase;
      print("📱 Supabase initialization flag: $_isSupabaseInitialized");

      // Initialize services
      await _initializeServices();

      print("✅ All services initialized successfully");

      // Initialize deep links
      await _initDeepLinks();

      print("✅ App initialization complete");
      
      if (mounted) {
        setState(() {
          _isServicesInitialized = true;
        });
      }
    } catch (error, stackTrace) {
      print("❌ App initialization error: $error");
      print("Stack trace: $stackTrace");
      
      if (mounted) {
        setState(() {
          _initializationError = error.toString();
          _isServicesInitialized = true; // Set to true to show error screen
        });
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      print("🔄 Initializing CacheService...");
      _cacheService = CacheService();
      await _cacheService.init();
      print("✅ CacheService initialized");

      print("🔄 Initializing NetworkService...");
      _networkService = NetworkService();
      print("✅ NetworkService initialized");

      // Small delay to ensure everything is ready
      await Future.delayed(const Duration(milliseconds: 300));
      print("✅ All services initialized successfully");
    } catch (error, stackTrace) {
      print("❌ Service initialization failed: $error");
      print("Stack trace: $stackTrace");
      // Don't rethrow - we want to show the app even if services fail
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      // Get initial deep link (if app was launched from a link)
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
        _isDeepLinkHandled = true;
      }

      // Listen for deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      });

      print('✅ Deep link service initialized');
    } catch (error) {
      print('⚠️ Deep link initialization failed: $error');
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    try {
      // Prevent multiple simultaneous deep link handling
      if (_isDeepLinkHandled) return;

      _isDeepLinkHandled = true;

      // Log deep link received
      print('🔗 Deep link received: ${uri.toString()}');

      // Wait for app to be ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if it's a password reset link
      if (uri.toString().contains('reset-password')) {
        await _handlePasswordResetLink(uri);
      }
      // Check if it's an email verification link
      else if (uri.toString().contains('verify-email')) {
        await _handleEmailVerificationLink(uri);
      } else {
        print('⚠️ Unknown deep link type: ${uri.toString()}');
      }

      // Reset flag after handling
      Future.delayed(const Duration(seconds: 1), () {
        _isDeepLinkHandled = false;
      });
    } catch (error) {
      print('❌ Deep link handling failed: $error');
      _isDeepLinkHandled = false;
    }
  }

  Future<void> _handlePasswordResetLink(Uri uri) async {
    final token = uri.queryParameters['token'];
    final type = uri.queryParameters['type'] ?? 'recovery';

    if (token == null) {
      print('⚠️ Password reset link missing token');
      return;
    }

    print('🔑 Password reset link received with token: $token');

    // Navigate to reset password page
    if (_navigatorKey.currentState != null && mounted) {
      _navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(token: token, type: type),
          settings: const RouteSettings(name: '/reset-password'),
        ),
        (route) => route.settings.name == '/onboarding',
      );
    }

    print('✅ Password reset link handled');
  }

  Future<void> _handleEmailVerificationLink(Uri uri) async {
    final token = uri.queryParameters['token'];

    if (token == null) {
      print('⚠️ Email verification link missing token');
      return;
    }

    try {
      // In Supabase, email verification is handled automatically when user clicks the link
      print('✅ Email verification token received: $token');

      if (_navigatorKey.currentState != null && mounted) {
        final context = _navigatorKey.currentState!.context;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! You can now login.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      print('✅ Email verification successful');
    } catch (error) {
      print('❌ Email verification failed: $error');

      if (_navigatorKey.currentState != null && mounted) {
        final context = _navigatorKey.currentState!.context;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verification failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      default:
        break;
    }
  }

  void _onAppResumed() {
    print('📱 App resumed');

    // Check if cache service is ready and reinitialize if needed
    if (_isServicesInitialized && mounted) {
      try {
        if (!_cacheService.isInitialized()) {
          _cacheService.init();
        }
      } catch (e) {
        print("⚠️ Error resuming cache service: $e");
      }
    }
  }

  void _onAppPaused() {
    print('⏸️ App paused');

    // Close Hive boxes to save state
    if (_isServicesInitialized) {
      try {
        if (_cacheService.isInitialized()) {
          _cacheService.saveAppState();
        }
      } catch (e) {
        print("⚠️ Error pausing cache service: $e");
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Close services safely
    if (_isServicesInitialized) {
      _cacheService.close();
      _networkService.dispose();
    }

    super.dispose();
  }

  Widget _buildSplashScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(25),
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
              const SizedBox(height: 30),

              // App name
              const Text(
                'JuvaPay',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),

              // Loading indicator
              const SizedBox(height: 30),
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),

              // Status message
              const SizedBox(height: 20),
              Text(
                _initializationError != null
                    ? 'Initializing with limited functionality...'
                    : 'Initializing app...',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              // Error message (if any)
              if (_initializationError != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Note: Some services may not be available',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                  ),
                ),
              ],

              // Version info
              const SizedBox(height: 40),
              const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _initializationError ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    // Retry initialization
                    setState(() {
                      _initializationError = null;
                      _isServicesInitialized = false;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Continue with limited functionality
                    setState(() {
                      _initializationError = null;
                    });
                  },
                  child: const Text('Continue Anyway'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while initializing
    if (!_isServicesInitialized) {
      return _buildSplashScreen();
    }

    // Show error screen if initialization failed
    if (_initializationError != null) {
      return _buildErrorScreen();
    }

    // Check if user is logged in
    bool isLoggedIn = false;
    if (widget.initializeSupabase) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        isLoggedIn = session != null;
        print("🔐 User logged in: $isLoggedIn");
      } catch (e) {
        print("⚠️ Error checking auth status: $e");
        isLoggedIn = false;
      }
    }

    return ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<ThemeService>(
            create: (_) => ThemeService(),
          ),
          provider.Provider<CacheService>(create: (_) => _cacheService),
          provider.Provider<NetworkService>(create: (_) => _networkService),
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
              themeMode: themeService.themeMode,
              navigatorKey: _navigatorKey,
              onGenerateRoute: (settings) {
                if (settings.name != null) {
                  if (settings.name!.contains('reset-password')) {
                    final uri = Uri.parse(settings.name!);
                    final token = uri.queryParameters['token'];
                    final type = uri.queryParameters['type'] ?? 'recovery';

                    if (token != null) {
                      return MaterialPageRoute(
                        builder:
                            (context) =>
                                ResetPasswordPage(token: token, type: type),
                      );
                    }
                  }
                }
                return null;
              },
              onUnknownRoute: (settings) {
                return MaterialPageRoute(
                  builder:
                      (context) => Scaffold(
                        appBar: AppBar(title: const Text('Not Found')),
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Page Not Found',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/home',
                                    (route) => false,
                                  );
                                },
                                child: const Text('Go to Home'),
                              ),
                            ],
                          ),
                        ),
                      ),
                );
              },
              home:
                  isLoggedIn
                      ? const AppBottomNavigationBar()
                      : const OnboardingView(),
              routes: {
                '/home': (context) => const AppBottomNavigationBar(),
                '/onboarding': (context) => const OnboardingView(),
                '/reset-password': (context) {
                  final args =
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, String>?;
                  return ResetPasswordPage(
                    token: args?['token'] ?? '',
                    type: args?['type'] ?? 'recovery',
                  );
                },
              },
            );
          },
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String? error;
  
  const ErrorApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  error ?? 'Please check your internet connection and restart the app.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    // Try to restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Run app without Supabase initialization
                    runApp(const JuvaPayApp(initializeSupabase: false));
                  },
                  child: const Text('Continue without Supabase'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}