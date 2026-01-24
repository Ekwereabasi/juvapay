import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart'; 
import '../models/onboarding_item.dart';
import '../views/auth/signup_view_single_page.dart';
// import '../view_models/registration_view_model.dart';
import '../views/auth/login_view.dart'; // Import the LoginView

class OnboardingViewModel extends ChangeNotifier {
  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  // Static data based on your uploaded images
  final List<OnboardingItem> _pages = [
    OnboardingItem(
      title: "Get Paid for Posting Adverts Daily on Your Social Media",
      description:
          "Earn daily income by posting adverts and performing simple social tasks for top businesses and brands on your social media account.",
    ),
    OnboardingItem(
      title: "Boost Your Social Media Engagement and Portfolio",
      description:
          "Get real people to grow your social media portfolio and engagements by getting them to perform engagement tasks for you using their social media account.",
    ),
    OnboardingItem(
      title: "Get People to Post Your Adverts on their Social Media",
      description:
          "Get people with atleast 1,000 followers to post your adverts and perform social tasks for you on their social media account.",
    ),
    OnboardingItem(
      title: "Sell Faster on JuvaPay Marketplace",
      description:
          "Take advantage of our huge web traffic and sell your products/faster anything on the JuvaPay Marketplace.",
    ),
  ];

  List<OnboardingItem> get pages => _pages;
  int get pageCount => _pages.length;

  void updatePageIndex(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  void onCreateFreeAccount(BuildContext context) {
    print('Navigating to Create Account (Single Page)...');
    
    // Use simple push for the Sign Up full-screen route
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SignupViewSinglePage(), 
      ),
    );
  }

  // 🎯 APPLIED: Using showDialog to display LoginView as a popup
  void onLoginToYourAccount(BuildContext context) {
    print('Showing Login Dialog...');
    
    showDialog(
      context: context,
      // You may want to prevent closing the dialog by tapping outside
      barrierDismissible: false, 
      builder: (BuildContext context) {
        // The LoginView provides the ViewModel and the dialog content
        return const LoginView(); 
      },
    );
  }
}