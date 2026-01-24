import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Access theme properties for dynamic styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Your privacy is important to us. This Privacy Policy explains how JuvaPay collects, uses, discloses, and safeguards your information.',
              style: textTheme.bodyLarge?.copyWith(
                height: 1.5,
                // Using onSurfaceVariant for secondary-style main text
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 30),

            // Use the updated helper that accepts theme data
            _buildPrivacySection(
              theme: theme,
              title: '1. Information We Collect',
              content: '''
Personal Information:
- Full name, email address, phone number
- Date of birth and gender
- Bank account details for withdrawals
- Government-issued ID for verification
- Profile picture and bio

Transaction Information:
- Task completion history
- Payment and withdrawal records
- Marketplace purchase/sale history
- Wallet balance and transaction logs

Technical Information:
- Device type and operating system
- IP address and location data
- Browser type and version
- App usage statistics and crash reports

Social Media Information (for task completion):
- Platform usernames (only when required for tasks)
- Task-specific engagement data
''',
            ),
            const SizedBox(height: 20),
            _buildPrivacySection(
              theme: theme,
              title: '2. How We Use Your Information',
              content: '''
We use your information to:
- Provide and improve our services
- Process payments and withdrawals
- Verify user identity and prevent fraud
- Facilitate task completion and posting
- Enable marketplace transactions
- Send important notifications
- Personalize your experience
- Comply with legal obligations
- Analyze platform usage for improvements
''',
            ),
            // ... (Sections 3 through 11 omitted for brevity, but use the same pattern)
            const SizedBox(height: 20),
            _buildPrivacySection(
              theme: theme,
              title: '12. Contact Us',
              content: '''
For privacy-related questions or concerns:
- Email: privacy@juvapay.com
- Phone: +234-XXX-XXX-XXXX
- Address: Data Protection Officer, JuvaPay, Akwa Ibom, Nigeria
- Response time: Within 48 hours
''',
            ),
            const SizedBox(height: 30),

            // Branded Data Protection Commitment Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Use the secondary or tertiary container for a highlighted box
                color: colorScheme.secondaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.secondary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Protection Commitment',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We are committed to protecting your privacy and handling your data transparently and securely.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Last Updated: January 17, 2026',
                    style: textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required ThemeData theme,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            // Using primary or tertiary for section headers
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            // Automatically adjusts color for Dark Mode contrast
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
