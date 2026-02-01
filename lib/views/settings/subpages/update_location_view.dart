import 'package:flutter/material.dart';
import 'package:juvapay/services/state_service.dart'; // Use StateService
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:juvapay/models/location_models.dart';

class UpdateLocationScreen extends StatefulWidget {
  const UpdateLocationScreen({super.key});

  @override
  State<UpdateLocationScreen> createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  final StateService _stateService = StateService(); // Use StateService
  final SupabaseAuthService _authService = SupabaseAuthService();

  List<StateModel> _states = [];
  List<LgaModel> _lgas = [];

  StateModel? _selectedState;
  LgaModel? _selectedLga;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    try {
      final states = await _stateService.getStates(); // Use StateService method
      setState(() {
        _states = states;
        _isLoading = false;
      });
    } catch (e) {
      _showTopSnackBar("Error loading states: $e", isError: true);
    }
  }

  Future<void> _onStateChanged(StateModel? newState) async {
    setState(() {
      _selectedState = newState;
      _selectedLga = null;
      _lgas = [];
    });
    if (newState != null) {
      try {
        final lgas = await _stateService.getLgasByState(
          newState.id,
        ); // Use StateService method
        setState(() => _lgas = lgas);
      } catch (e) {
        _showTopSnackBar("Error loading LGAs", isError: true);
      }
    }
  }

  Future<void> _updateLocation() async {
    if (_selectedState == null || _selectedLga == null) {
      _showTopSnackBar("Please select both State and LGA", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update profile with location using the correct method
      final updateResult = await _authService.updateProfile(
        stateId: _selectedState!.id,
        lgaId: _selectedLga!.id,
      );

      if (updateResult['success'] == true) {
        if (mounted) {
          _showTopSnackBar("Location updated successfully!", isError: false);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        _showTopSnackBar(
          updateResult['message'] ?? "Failed to update location",
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showTopSnackBar("Failed to update location: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showTopSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Update Your Location",
          style: Theme.of(
            context,
          ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You can change your current location below. Your location is very important as it determines who sees your products.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.8,
                        ),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- State Dropdown ---
                    _buildDropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<StateModel>(
                          value: _selectedState,
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          hint: Text(
                            "Select State",
                            style: TextStyle(color: theme.hintColor),
                          ),
                          icon: Icon(Icons.unfold_more, color: theme.hintColor),
                          items:
                              _states
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.name,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: _onStateChanged,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- LGA Dropdown ---
                    _buildDropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<LgaModel>(
                          value: _selectedLga,
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          hint: Text(
                            "Select LGA",
                            style: TextStyle(color: theme.hintColor),
                          ),
                          icon: Icon(Icons.unfold_more, color: theme.hintColor),
                          items:
                              _lgas
                                  .map(
                                    (l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(
                                        l.name,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _selectedLga = val),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "You will have to select your state before selecting the LGA.",
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ),

                    const Spacer(),

                    // --- Submit Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            _selectedLga == null || _isSaving
                                ? null
                                : _updateLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  "SET LOCATION",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: theme.hintColor),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
