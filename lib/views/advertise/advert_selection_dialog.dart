import 'package:flutter/material.dart';
import 'advert_upload_page.dart'; // Make sure to import the AdvertUploadPage

class AdvertSelectionDialog extends StatelessWidget {
  final VoidCallback onNavigateToMarket;

  const AdvertSelectionDialog({super.key, required this.onNavigateToMarket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor, // Adaptive background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose your advert package below:",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- OPTION 1: JuvaPay Market ---
                    Expanded(
                      child: _buildOptionCard(
                        context,
                        icon: Icons.storefront,
                        iconColor: Colors.orange,
                        title: "Advertise on JuvaPay Market",
                        desc:
                            "Take massive advantage of the huge traffic on JuvaPay and advertise directly to thousands of buyers.",
                        onTap: onNavigateToMarket,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // --- OPTION 2: Social Media ---
                    Expanded(
                      child: _buildOptionCard(
                        context,
                        icon: Icons.share,
                        iconColor: Colors.blue,
                        title: "Advertise on Social Media",
                        desc:
                            "Get people with active followers to repost your adverts and perform social tasks.",
                        isSocialGroup: true,
                        onTap: () {
                          Navigator.pop(context); // Close the dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdvertUploadPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Close Button ---
          Positioned(
            right: -10,
            top: -10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      theme
                          .colorScheme
                          .error, // Uses theme error color (usually red)
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool isSocialGroup = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor, // Adaptive card background
          border: Border.all(color: theme.dividerColor), // Adaptive border
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            isSocialGroup
                ? SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.facebook, color: Colors.blue),
                      const SizedBox(width: 5),
                      const Icon(Icons.camera_alt, color: Colors.pink),
                      const SizedBox(width: 5),
                      // TikTok icon needs to be white in dark mode
                      Icon(
                        Icons.music_note,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ],
                  ),
                )
                : Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 10),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodySmall?.color, // Adaptive grey
                height: 1.2,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "GET STARTED",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
