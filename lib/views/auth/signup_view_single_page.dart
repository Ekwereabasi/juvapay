import 'package:flutter/material.dart';
import 'package:juvapay/widgets/app_bottom_navbar.dart';
import 'package:provider/provider.dart';
import '../../view_models/registration_view_model.dart';
import '../../models/location_models.dart';
// import '../home/home_view.dart'; // Not needed if using AppBottomNavbar

class SignupViewSinglePage extends StatefulWidget {
  const SignupViewSinglePage({super.key});

  @override
  State<SignupViewSinglePage> createState() => _SignupViewSinglePageState();
}

class _SignupViewSinglePageState extends State<SignupViewSinglePage> {
  final _formKey = GlobalKey<FormState>();

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize data fetching for states/LGAs
      Provider.of<RegistrationViewModel>(
        context,
        listen: false,
      ).initializeData();
    });
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

  // ✅ FIXED: Dynamic Border Colors for Light/Dark Mode
  InputDecoration _inputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      // Use standard label style from theme
      labelStyle: TextStyle(color: Theme.of(context).hintColor),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        // ✅ Uses dynamic divider color (Grey in light, White12 in dark)
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        // ✅ Uses your Primary Purple
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2.0,
        ),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
    );
  }

  // --- Unified Submission Logic ---
  void _submitForm(RegistrationViewModel viewModel) async {
    // 1. Validate Form & Location Data
    if (!_formKey.currentState!.validate() ||
        _selectedState == null ||
        _selectedLga == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please complete all required fields and select your location.',
          ),
          backgroundColor:
              Colors.orange.shade800, // Slightly darker for better contrast
        ),
      );
      return;
    }

    // 2. Load all data into the ViewModel for processing
    viewModel.setBasicDetails(
      email: _emailController.text,
      password: _passwordController.text,
      username: _usernameController.text,
      fullName: _fullNameController.text,
    );
    // Location data (LGA) is already in the ViewModel via the onChanged handler below

    // 3. Process Signup (Auth, Profile Update)
    final success = await viewModel.processSignup(context);

    if (context.mounted) {
      if (success) {
        // Success: Navigate to the Nav Bar Shell
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppBottomNavigationBar()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Failure: Show error message from ViewModel
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Registration failed.'),
            backgroundColor:
                Theme.of(context).colorScheme.error, // Use Theme error color
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RegistrationViewModel>(context);

    return Scaffold(
      // ✅ FIXED: Removed hardcoded background color.
      // It will now use 'scaffoldBackgroundColor' from AppTheme (White or #121212)
      appBar: AppBar(
        title: Text(
          'Complete Registration',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        // ✅ FIXED: Removed hardcoded white/elevation. Inherits from AppTheme.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Text Fields ---
              TextFormField(
                controller: _fullNameController,
                decoration: _inputDecoration('Full Name'),
                // ✅ Text color is automatic via Theme.textTheme.bodyMedium
                validator: (v) => v!.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration('Username (Public)'),
                validator:
                    (v) => v!.isEmpty ? 'Choose a unique username' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email Address'),
                validator:
                    (v) =>
                        v!.isEmpty || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
              ),
              const SizedBox(height: 16),

              // --- Password Input (with Toggle) ---
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration(
                  'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      // ✅ FIXED: Use theme hint color for icons
                      color: Theme.of(context).hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator:
                    (v) =>
                        v!.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
              ),
              const SizedBox(height: 16),

              // --- Confirm Password Input (with Toggle) ---
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: _inputDecoration(
                  'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      // ✅ FIXED: Use theme hint color for icons
                      color: Theme.of(context).hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Confirm your password';
                  if (v != _passwordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // --- Location Title ---
              Text(
                'Location Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  // ✅ FIXED: Primary color works well on both, but this ensures consistency
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 15),

              // --- Location Dropdowns ---
              if (viewModel.states.isEmpty && viewModel.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(
                      // ✅ FIXED: Ensure spinner uses primary color
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // State Dropdown
                    DropdownButtonFormField<StateModel>(
                      value: _selectedState,
                      hint: Text(
                        'Select State',
                        // ✅ FIXED: Ensure hint text is visible in dark mode
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      decoration: _inputDecoration('State'),
                      isExpanded: true,
                      // ✅ FIXED: Ensure dropdown background adapts to theme card color
                      dropdownColor: Theme.of(context).cardColor,
                      items:
                          viewModel.states
                              .map(
                                (state) => DropdownMenuItem(
                                  value: state,
                                  child: Text(
                                    state.name,
                                    // ✅ FIXED: Ensure item text adapts to theme body text
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedState = value;
                            _selectedLga = null;
                          });
                          viewModel.loadLgas(value);
                        }
                      },
                      validator:
                          (v) => v == null ? 'Please select a state' : null,
                    ),

                    const SizedBox(height: 20),

                    // LGA Dropdown
                    DropdownButtonFormField<LgaModel>(
                      value: _selectedLga,
                      hint: Text(
                        _selectedState == null
                            ? 'Select a State first'
                            : 'Select LGA',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      decoration: _inputDecoration('LGA'),
                      isExpanded: true,
                      dropdownColor: Theme.of(context).cardColor,
                      items:
                          viewModel.lgas
                              .map(
                                (lga) => DropdownMenuItem(
                                  value: lga,
                                  child: Text(
                                    lga.name,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLga = value;
                          });
                          viewModel.setLGA(value);
                        }
                      },
                      validator:
                          (v) => v == null ? 'Please select an LGA' : null,
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              // --- Submit Button ---
              if (viewModel.isLoading && viewModel.states.isNotEmpty)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () => _submitForm(viewModel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    // Theme handles background color, but explicit primary is fine too
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('REGISTER & SIGN IN'),
                ),

              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Error: ${viewModel.errorMessage!}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
