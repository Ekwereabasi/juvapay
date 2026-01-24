import 'package:flutter/material.dart';

class TermsOfUseView extends StatelessWidget {
  const TermsOfUseView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Access the theme and color scheme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Terms of Use'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSection(
              theme: theme,
              title: '1. Acceptance of Terms',
              content: '''
By accessing or using JuvaPay (the "Platform"), you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use our Platform. These terms apply to all users including earners, advertisers, and marketplace participants.
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '2. Description of Service',
              content: '''
JuvaPay is a platform that enables:
- Task Performance: Users can perform social media tasks (likes, follows, comments, shares) and earn money
- Task Posting: Users can post tasks for others to complete, including advertising and engagement tasks
- Marketplace: Users can buy and sell products through our integrated marketplace
- Wallet System: Secure digital wallet for earnings, deposits, and withdrawals
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '3. User Accounts',
              content: '''
- You must be at least 18 years old to use JuvaPay
- You are responsible for maintaining the confidentiality of your account
- You agree to provide accurate and complete information
- One user per account - no sharing of accounts
- You are responsible for all activities under your account
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '4. Task Rules and Guidelines',
              content: '''
For Earners:
- Complete tasks honestly and according to instructions
- Do not use fake accounts or automation tools
- Submit proof of completion accurately
- Respect intellectual property rights
- Do not engage in fraudulent activities

For Advertisers:
- Provide clear and accurate task descriptions
- Set fair compensation for tasks
- Review submissions within 24 hours
- Pay for completed tasks promptly
- Do not request illegal or inappropriate content
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '5. Marketplace Rules',
              content: '''
- List only products you legally own or have rights to sell
- Provide accurate descriptions and images
- Price products fairly and transparently
- Ship products as described within stated timeframes
- Maintain good customer service
- Prohibited items include illegal goods, weapons, drugs, and counterfeit products
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '6. Payments and Fees',
              content: '''
- JuvaPay charges a 10% service fee on all completed tasks
- Marketplace sales include a 5% transaction fee
- Minimum withdrawal amount: ₦500
- Withdrawals are processed within 24-48 hours
- All payments are in Nigerian Naira (₦)
- We reserve the right to modify fees with 30 days notice
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '7. Intellectual Property',
              content: '''
- JuvaPay owns all intellectual property related to the Platform
- Users retain ownership of their content but grant JuvaPay license to use it
- Do not infringe on others' copyrights or trademarks
- Report intellectual property violations immediately
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '8. Prohibited Activities',
              content: '''
Users must not:
- Engage in fraudulent activities
- Create multiple accounts
- Use automated tools or bots
- Post offensive or illegal content
- Harass other users
- Attempt to hack or compromise the Platform
- Violate any laws or regulations
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '9. Termination',
              content: '''
We may suspend or terminate your account if you:
- Violate these Terms of Use
- Engage in fraudulent activities
- Harm other users or the Platform
- Fail to pay for completed tasks
- Repeatedly receive complaints
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '10. Limitation of Liability',
              content: '''
JuvaPay is not liable for:
- User-generated content
- Disputes between users
- Financial losses from using the Platform
- Technical issues or downtime
- Third-party actions
- Direct damages exceeding ₦10,000
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '11. Dispute Resolution',
              content: '''
- Report disputes through our support system
- We will mediate disputes between users
- Arbitration is preferred over litigation
- Nigerian law governs these terms
- Disputes must be filed in Nigerian courts
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '12. Changes to Terms',
              content: '''
- We may update these terms periodically
- Users will be notified of significant changes
- Continued use constitutes acceptance of new terms
- Check this page regularly for updates
''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme: theme,
              title: '13. Contact Information',
              content: '''
For questions about these Terms of Use, contact us at:
- Email: legal@juvapay.com
- Phone: +234-XXX-XXX-XXXX
- Address: JuvaPay Legal Department, Akwa Ibom, Nigeria
''',
            ),
            const SizedBox(height: 30),

            // Updated Footer Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Use primaryContainer for a branded but subtle look
                color: colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
              ),
              child: Text(
                'Last Updated: January 17, 2026\n\nBy using JuvaPay, you acknowledge that you have read, understood, and agree to be bound by these Terms of Use.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
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
            color: theme.colorScheme.primary, // Matches brand color
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            // Automatically flips from dark grey to light grey in dark mode
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
