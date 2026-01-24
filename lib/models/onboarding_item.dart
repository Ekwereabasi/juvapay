
class OnboardingItem {
  final String title;
  final String description;
  final String? imagePath; // Optional, if you were using local assets

  OnboardingItem({
    required this.title,
    required this.description,
    this.imagePath,
  });
}
