// earn_task_view.dart
import 'package:flutter/material.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:juvapay/view_models/wallet_view_model.dart';
import 'package:provider/provider.dart';

import '../../../services/task_service.dart';
import 'task_execution_view.dart';
import 'earn_select_view.dart';

class EarnTaskView extends StatefulWidget {
  const EarnTaskView({super.key});

  @override
  State<EarnTaskView> createState() => _EarnTaskViewState();
}

class _EarnTaskViewState extends State<EarnTaskView> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _workerProfile;

  @override
  void initState() {
    super.initState();
    _loadWorkerProfile();
  }

  Future<void> _loadWorkerProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _authService.getWorkerProfile();
      setState(() {
        _workerProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    // Check if user has worker profile
    final hasWorkerProfile = _workerProfile != null;

    if (!hasWorkerProfile) {
      // User needs to create a worker profile
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            "Become a Worker",
            style: Theme.of(
              context,
            ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: Theme.of(context).appBarTheme.elevation ?? 0,
          centerTitle: true,
          iconTheme: Theme.of(context).appBarTheme.iconTheme,
          actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                "Start Earning by Completing Social Media Tasks!",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              _buildBenefitItem(
                "Earn money by completing simple social media tasks.",
                theme,
              ),
              _buildBenefitItem(
                "Get paid instantly for each completed task.",
                theme,
              ),
              _buildBenefitItem(
                "Work anytime, anywhere with flexible hours.",
                theme,
              ),
              const SizedBox(height: 30),
              _buildTermsBox(theme),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      // Create worker profile
                      await _authService.updateWorkerProfile(
                        isAvailable: true,
                        platformsConnected: [],
                        preferredPlatforms: [],
                      );
                      await _loadWorkerProfile();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "BECOME A WORKER",
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
      );
    }

    // User has worker profile, show task selection
    return const EarnSelectionView();
  }

  Widget _buildBenefitItem(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
          ),
        ),
      ],
    ),
  );

  Widget _buildTermsBox(ThemeData theme) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
    ),
    child: Text(
      "As a worker, you'll need to follow task instructions carefully and provide proof of completion. Payments are made after task approval.",
      textAlign: TextAlign.center,
      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500),
    ),
  );
}
