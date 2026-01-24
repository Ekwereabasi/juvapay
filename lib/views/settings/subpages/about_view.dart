import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    // Access theme data for dynamic styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About JuvaPay')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Logo and Tagline
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'JuvaPay',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Earn. Advertise. Grow.',
              style: textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),

            // Our Story
            _buildAboutSection(
              theme: theme,
              icon: Icons.history,
              title: 'Our Story',
              content: '''
Founded in 2026, JuvaPay emerged from a simple idea: to create a fair and transparent platform where anyone can earn money by completing simple tasks while helping businesses grow through authentic social media engagement.

We noticed a gap in the market between businesses seeking genuine social media presence and individuals looking for flexible earning opportunities. JuvaPay bridges this gap by creating a win-win ecosystem for both parties.
''',
            ),
            const SizedBox(height: 30),

            // Our Mission (Using Primary Theme Color)
            _buildAboutSection(
              theme: theme,
              icon: Icons.flag,
              title: 'Our Mission',
              content: '''
To empower individuals with flexible earning opportunities while helping businesses and creators achieve authentic growth through genuine social media engagement and efficient marketplace solutions.
''',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 30),

            // Our Vision (Using Secondary/Purple Theme Color)
            _buildAboutSection(
              theme: theme,
              icon: Icons.remove_red_eye,
              title: 'Our Vision',
              content: '''
To become Africa's leading platform for micro-task completion and social media marketing, creating economic opportunities for millions while revolutionizing how businesses approach digital marketing.
''',
              color: Colors.purple, // Keeping brand-specific color
            ),
            const SizedBox(height: 30),

            // What We Offer
            Text(
              'What We Offer',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureCard(
                  theme: theme,
                  icon: Icons.attach_money,
                  title: 'Earn Money',
                  description: 'Complete social media tasks and get paid',
                  color: Colors.green,
                ),
                _buildFeatureCard(
                  theme: theme,
                  icon: Icons.campaign,
                  title: 'Advertise',
                  description: 'Post tasks to boost your social media presence',
                  color: Colors.orange,
                ),
                _buildFeatureCard(
                  theme: theme,
                  icon: Icons.store,
                  title: 'Marketplace',
                  description: 'Buy and sell products with ease',
                  color: Colors.blue,
                ),
                _buildFeatureCard(
                  theme: theme,
                  icon: Icons.account_balance_wallet,
                  title: 'Secure Wallet',
                  description: 'Safe transactions with instant withdrawals',
                  color: Colors.purple,
                ),
                _buildFeatureCard(
                  theme: theme,
                  icon: Icons.verified_user,
                  title: 'Verified Community',
                  description: 'Trusted users and secure transactions',
                  color: Colors.red,
                ),
                _buildFeatureCard(
                  theme: theme,
                  icon: Icons.support_agent,
                  title: '24/7 Support',
                  description: 'Round-the-clock customer assistance',
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Statistics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    'Our Impact',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(theme, '50K+', 'Active Users'),
                      _buildStatItem(theme, '₦10M+', 'Paid Out'),
                      _buildStatItem(theme, '100K+', 'Tasks Completed'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Team Section
            Text(
              'Our Team',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'We are a diverse team of developers, marketers, and entrepreneurs passionate about creating opportunities and driving digital growth across Africa.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 30),

            // Values
            Text(
              'Our Values',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            _buildValueItem(
              theme,
              'Integrity',
              'Transparent and honest in all dealings',
            ),
            _buildValueItem(
              theme,
              'Innovation',
              'Constantly improving our platform',
            ),
            _buildValueItem(
              theme,
              'Community',
              'Supporting and empowering our users',
            ),
            _buildValueItem(
              theme,
              'Excellence',
              'Delivering quality in everything we do',
            ),
            _buildValueItem(
              theme,
              'Accessibility',
              'Platform available to everyone',
            ),
            const SizedBox(height: 30),

            // Contact Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    'Contact Us',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildContactItem(theme, Icons.email, 'support@juvapay.com'),
                  _buildContactItem(theme, Icons.phone, '+234-XXX-XXX-XXXX'),
                  _buildContactItem(theme, Icons.location_on, 'Akwa Ibom, Nigeria'),
                  _buildContactItem(
                    theme,
                    Icons.access_time,
                    '24/7 Support Available',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Social Media
            Text(
              'Connect With Us',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                  FontAwesomeIcons.facebookF,
                  const Color(0xFF1877F2),
                ),
                const SizedBox(width: 20),
                _buildSocialIcon(
                  FontAwesomeIcons
                      .xTwitter, // Fixed: Changed from xTwitter to twitter
                  theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                const SizedBox(width: 20),
                _buildSocialIcon(
                  FontAwesomeIcons.instagram,
                  const Color(0xFFE4405F),
                ),
                const SizedBox(width: 20),
                _buildSocialIcon(
                  FontAwesomeIcons.linkedinIn,
                  const Color(0xFF0A66C2),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Copyright
            Text(
              '© 2026 JuvaPay. All rights reserved.',
              style: textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    final effectiveColor = color ?? theme.colorScheme.primary;
    return Column(
      children: [
        Icon(icon, size: 40, color: effectiveColor),
        const SizedBox(height: 10),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: effectiveColor,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          content,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildValueItem(ThemeData theme, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
