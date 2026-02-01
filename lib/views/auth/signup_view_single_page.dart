import 'package:flutter/material.dart';
import 'package:juvapay/widgets/app_bottom_navbar.dart';
import 'package:provider/provider.dart';
import '../../view_models/registration_view_model.dart';
import '../../models/location_models.dart';

class SignupViewSinglePage extends StatefulWidget {
  const SignupViewSinglePage({super.key});

  @override
  State<SignupViewSinglePage> createState() => _SignupViewSinglePageState();
}

class _SignupViewSinglePageState extends State<SignupViewSinglePage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers for text input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();

  StateModel? _selectedState;
  LgaModel? _selectedLga;

  // State variables for password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Track if form has been submitted (to prevent multiple submissions)
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await Provider.of<RegistrationViewModel>(
        context,
        listen: false,
      ).initializeData();
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error loading location data. Please check your connection.',
          Colors.orange,
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // Dynamic Border Colors for Light/Dark Mode
  InputDecoration _inputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Theme.of(context).hintColor),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
      filled: true,
      fillColor: Theme.of(context).cardColor,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // --- SUBMISSION LOGIC WITH COMPREHENSIVE VALIDATION ---
  Future<void> _submitForm(RegistrationViewModel viewModel) async {
    // Prevent multiple submissions
    if (_isSubmitting) return;

    _isSubmitting = true;

    // Validate Form & Location Data
    if (!_formKey.currentState!.validate()) {
      _isSubmitting = false;
      _showSnackBar('Please fix the errors in the form.', Colors.orange);
      return;
    }

    if (_selectedState == null || _selectedLga == null) {
      _isSubmitting = false;
      _showSnackBar('Please select your State and LGA.', Colors.orange);
      return;
    }

    // Validate password match
    if (_passwordController.text != _confirmPasswordController.text) {
      _isSubmitting = false;
      _showSnackBar('Passwords do not match.', Colors.red);
      return;
    }

    // Validate password strength
    if (_passwordController.text.length < 6) {
      _isSubmitting = false;
      _showSnackBar(
        'Password must be at least 6 characters long.',
        Colors.orange,
      );
      return;
    }

    // Load all data into the ViewModel for processing
    viewModel.setBasicDetails(
      email: _emailController.text,
      password: _passwordController.text,
      username: _usernameController.text,
      fullName: _fullNameController.text,
    );

    // Process Signup
    final result = await viewModel.processSignup(context);

    _isSubmitting = false;

    if (!mounted) return;

    if (result['success'] == true) {
      // Show success message
      _showSnackBar(
        result['message'] ?? 'Registration successful!',
        Colors.green,
      );

      // Check for any warnings
      if (result['warning'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackBar(result['warning'], Colors.amber.shade700);
        });
      }

      // Navigate to main app after short delay
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppBottomNavigationBar()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      // Handle different error types
      final errorType = result['error_type'];
      final errorMessage = result['message'] ?? 'Registration failed.';

      if (errorType == 'network_error' || errorType == 'timeout_error') {
        _showErrorDialog(
          'Connection Error',
          '$errorMessage\n\nPlease check your internet connection and try again.',
        );
      } else if (errorType == 'auth_error') {
        _showErrorDialog('Authentication Error', errorMessage);
      } else if (errorType == 'validation_error') {
        _showSnackBar(errorMessage, Colors.orange);
      } else {
        _showErrorDialog('Registration Failed', errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RegistrationViewModel>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Join Juvapay',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration('Full Name'),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration('Username'),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please choose a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Only letters, numbers, and underscores allowed';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email Address'),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration(
                    'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    'Use at least 6 characters',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: _inputDecoration(
                    'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 30),

                // Location Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Location Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // State Dropdown
                      DropdownButtonFormField<StateModel>(
                        value: _selectedState,
                        hint: Text(
                          'Select State',
                          style: TextStyle(color: theme.hintColor),
                        ),
                        decoration: _inputDecoration('State'),
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        items:
                            viewModel.states.map((state) {
                              return DropdownMenuItem(
                                value: state,
                                child: Text(
                                  state.name,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedState = value;
                              _selectedLga = null;
                            });
                            viewModel.loadLgas(value);
                          }
                        },
                        validator: (value) {
                          if (value == null) return 'Please select your state';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // LGA Dropdown
                      DropdownButtonFormField<LgaModel>(
                        value: _selectedLga,
                        hint: Text(
                          _selectedState == null
                              ? 'Select State first'
                              : 'Select LGA',
                          style: TextStyle(color: theme.hintColor),
                        ),
                        decoration: _inputDecoration('LGA'),
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        items:
                            viewModel.lgas.map((lga) {
                              return DropdownMenuItem(
                                value: lga,
                                child: Text(
                                  lga.name,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLga = value;
                            });
                            viewModel.setLGA(value);
                          }
                        },
                        validator: (value) {
                          if (value == null) return 'Please select your LGA';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // Error Message
                if (viewModel.errorMessage != null &&
                    viewModel.errorType != 'network_error')
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed:
                      _isSubmitting || viewModel.isLoading
                          ? null
                          : () => _submitForm(viewModel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    disabledBackgroundColor: theme.primaryColor.withOpacity(
                      0.5,
                    ),
                  ),
                  child:
                      _isSubmitting || viewModel.isLoading
                          ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'CREATE ACCOUNT',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                ),

                const SizedBox(height: 20),

                // Additional Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• You will be signed in immediately after registration\n'
                        '• No email verification is required\n'
                        '• Use a valid email address for account recovery\n'
                        '• Keep your password secure and confidential',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Terms and Privacy Notice
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
