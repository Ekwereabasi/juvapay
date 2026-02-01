// earn_membership_view.dart
import 'package:flutter/material.dart';

class EarnMembershipView extends StatelessWidget {
  final VoidCallback onBecomeMember;

  const EarnMembershipView({super.key, required this.onBecomeMember});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Header Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 50,
                color: theme.primaryColor,
              ),
            ),

            const SizedBox(height: 30),

            // Title
            Text(
              "Unlock Premium Earnings",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              "Become a Juvapay Member to access all earning opportunities",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Membership Benefits
            _buildBenefitItem("Access to all earning methods", theme),
            _buildBenefitItem("Higher task payouts", theme),
            _buildBenefitItem("Priority support", theme),
            _buildBenefitItem("Early access to new features", theme),

            const SizedBox(height: 40),

            // Membership Fee Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Text("Membership Fee", style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    "₦1,000",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("One-time payment", style: theme.textTheme.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Become Member Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBecomeMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "BECOME A MEMBER",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Terms
            Text(
              "By becoming a member, you agree to our Terms of Service and Privacy Policy",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
}
