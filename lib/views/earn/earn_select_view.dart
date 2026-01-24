// views/earn/earn_select_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../market/market_view.dart';
import 'task_list_view.dart';

class EarnSelectionView extends StatelessWidget {
  const EarnSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'How do you want to earn today?',
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text
            Text(
              'Choose your earning path',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the method that best fits your skills and earning goals',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Earning Options
            Column(
              children: [
                // Social Tasks Card
                _buildEarningCard(
                  context: context,
                  title: 'Perform Social Tasks',
                  subtitle: 'Earn Daily',
                  description:
                      'Complete social media tasks and earn instantly. Perfect for students and anyone with social media accounts.',
                  icon: Icons.thumb_up_alt_rounded,
                  iconColor: colorScheme.primary,
                  gradientColors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                  earnings: '₦500 - ₦5,000 daily',
                  time: 'Flexible hours',
                  buttonText: 'BROWSE TASKS',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TaskListView(),
                        ),
                      ),
                ),
                const SizedBox(height: 20),

                // Reselling Card
                _buildEarningCard(
                  context: context,
                  title: 'Resell Products',
                  subtitle: 'Earn Big Commissions',
                  description:
                      'Resell products from top brands and earn commissions up to 25%. No inventory required.',
                  icon: Icons.shopping_bag_rounded,
                  iconColor: Colors.green,
                  gradientColors: [Colors.green, Colors.green.shade700],
                  earnings: 'Up to ₦100,000 monthly',
                  time: 'Full-time/Part-time',
                  buttonText: 'VIEW MARKETPLACE',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MarketView()),
                      ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // How It Works Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.help_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'How it works',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Steps
                  _buildStep(
                    number: 1,
                    title: 'Choose Your Path',
                    description:
                        'Select between social tasks or product reselling based on your preferences',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildStep(
                    number: 2,
                    title: 'Get Started',
                    description:
                        'Browse available tasks or products and select what interests you',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildStep(
                    number: 3,
                    title: 'Complete & Earn',
                    description:
                        'Follow instructions and complete requirements to earn money',
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Stats
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Choose JuvaPay?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.payment_rounded,
                          label: 'Instant Payout',
                          value: '24 hours',
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.people_rounded,
                          label: 'Active Users',
                          value: '50,000+',
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.security_rounded,
                          label: 'Secure Platform',
                          value: '100% Safe',
                          color: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.support_agent_rounded,
                          label: '24/7 Support',
                          value: 'Live Chat',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Footer Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Start earning today! No experience needed. Choose your preferred method and begin immediately.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
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

  Widget _buildEarningCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required String earnings,
    required String time,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.currency_exchange_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              earnings,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Earnings',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Flexibility',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          buttonText,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: gradientColors.first,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
