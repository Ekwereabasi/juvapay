import 'dart:io';
import 'location_models.dart';

class UserRegistrationModel {
  // Basic authentication info
  String email = '';
  String password = '';
  String fullName = '';
  String username = '';

  // Optional contact info
  String phone = '';

  // Location info
  StateModel? selectedState;
  LgaModel? selectedLga;

  // Profile image
  File? profileImage;

  // Additional profile info (optional)
  String bio = '';
  String gender = '';
  String religion = '';

  // Date of birth (optional)
  int? dobDay;
  String? dobMonth;
  int? dobYear;

  // Avatar URL (will be set after upload)
  String? avatarUrl;

  // Validation methods

  // Check if required fields for signup are filled
  bool get isSignupReady {
    return email.isNotEmpty && password.isNotEmpty && fullName.isNotEmpty;
  }

  // Check if all required fields for database profile are present
  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        username.isNotEmpty &&
        selectedState != null &&
        selectedLga != null;
  }

  // Check if optional profile info is complete
  bool get isProfileDetailed {
    return gender.isNotEmpty ||
        religion.isNotEmpty ||
        (dobDay != null && dobMonth != null && dobYear != null) ||
        bio.isNotEmpty;
  }

  // Get date of birth as DateTime if available
  DateTime? get dateOfBirth {
    if (dobDay != null && dobMonth != null && dobYear != null) {
      try {
        // Map month name to number
        final monthMap = {
          'January': 1,
          'February': 2,
          'March': 3,
          'April': 4,
          'May': 5,
          'June': 6,
          'July': 7,
          'August': 8,
          'September': 9,
          'October': 10,
          'November': 11,
          'December': 12,
        };

        final monthNumber = monthMap[dobMonth];
        if (monthNumber != null) {
          return DateTime(dobYear!, monthNumber, dobDay!);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Get age from date of birth
  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;

    final now = DateTime.now();
    int age = now.year - dob.year;

    // Adjust if birthday hasn't occurred yet this year
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    return age;
  }

  // Check if user is at least 18 years old
  bool get isAdult {
    final userAge = age;
    return userAge != null && userAge >= 18;
  }

  // Get location as formatted string
  String get locationString {
    if (selectedState != null && selectedLga != null) {
      return '${selectedLga!.name}, ${selectedState!.name}';
    } else if (selectedState != null) {
      return selectedState!.name;
    }
    return '';
  }

  // Convert to map for database insertion
  Map<String, dynamic> toProfileMap() {
    return {
      'full_name': fullName,
      'username': username,
      'phone_number': phone.isNotEmpty ? phone : null,
      'avatar_url': avatarUrl,
      'bio': bio.isNotEmpty ? bio : null,
      'gender': gender.isNotEmpty ? gender : null,
      'religion': religion.isNotEmpty ? religion : null,
      'dob_day': dobDay,
      'dob_month': dobMonth,
      'dob_year': dobYear,
      'state_id': selectedState?.id,
      'lga_id': selectedLga?.id,
    };
  }

  // Convert to map for auth metadata
  Map<String, dynamic> toAuthMetadata() {
    return {
      'full_name': fullName,
      'phone': phone.isNotEmpty ? phone : null,
      'avatar_url': avatarUrl,
      'state_id': selectedState?.id,
      'lga_id': selectedLga?.id,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create a summary of the registration data
  Map<String, dynamic> get summary {
    return {
      'email': email,
      'full_name': fullName,
      'username': username,
      'phone': phone,
      'location': locationString,
      'has_profile_image': profileImage != null,
      'bio': bio,
      'gender': gender,
      'religion': religion,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'age': age,
      'is_adult': isAdult,
      'is_signup_ready': isSignupReady,
      'is_profile_complete': isProfileComplete,
      'is_profile_detailed': isProfileDetailed,
    };
  }

  // Reset all fields
  void reset() {
    email = '';
    password = '';
    fullName = '';
    username = '';
    phone = '';
    selectedState = null;
    selectedLga = null;
    profileImage = null;
    avatarUrl = null;
    bio = '';
    gender = '';
    religion = '';
    dobDay = null;
    dobMonth = null;
    dobYear = null;
  }

  // Copy with method for creating modified copies
  UserRegistrationModel copyWith({
    String? email,
    String? password,
    String? fullName,
    String? username,
    String? phone,
    StateModel? selectedState,
    LgaModel? selectedLga,
    File? profileImage,
    String? avatarUrl,
    String? bio,
    String? gender,
    String? religion,
    int? dobDay,
    String? dobMonth,
    int? dobYear,
  }) {
    return UserRegistrationModel()
      ..email = email ?? this.email
      ..password = password ?? this.password
      ..fullName = fullName ?? this.fullName
      ..username = username ?? this.username
      ..phone = phone ?? this.phone
      ..selectedState = selectedState ?? this.selectedState
      ..selectedLga = selectedLga ?? this.selectedLga
      ..profileImage = profileImage ?? this.profileImage
      ..avatarUrl = avatarUrl ?? this.avatarUrl
      ..bio = bio ?? this.bio
      ..gender = gender ?? this.gender
      ..religion = religion ?? this.religion
      ..dobDay = dobDay ?? this.dobDay
      ..dobMonth = dobMonth ?? this.dobMonth
      ..dobYear = dobYear ?? this.dobYear;
  }

  // Merge with another instance
  void mergeWith(UserRegistrationModel other) {
    if (other.email.isNotEmpty) email = other.email;
    if (other.password.isNotEmpty) password = other.password;
    if (other.fullName.isNotEmpty) fullName = other.fullName;
    if (other.username.isNotEmpty) username = other.username;
    if (other.phone.isNotEmpty) phone = other.phone;
    if (other.selectedState != null) selectedState = other.selectedState;
    if (other.selectedLga != null) selectedLga = other.selectedLga;
    if (other.profileImage != null) profileImage = other.profileImage;
    if (other.avatarUrl != null) avatarUrl = other.avatarUrl;
    if (other.bio.isNotEmpty) bio = other.bio;
    if (other.gender.isNotEmpty) gender = other.gender;
    if (other.religion.isNotEmpty) religion = other.religion;
    if (other.dobDay != null) dobDay = other.dobDay;
    if (other.dobMonth != null) dobMonth = other.dobMonth;
    if (other.dobYear != null) dobYear = other.dobYear;
  }

  @override
  String toString() {
    return 'UserRegistrationModel(\n'
        '  email: $email,\n'
        '  fullName: $fullName,\n'
        '  username: $username,\n'
        '  phone: $phone,\n'
        '  location: $locationString,\n'
        '  hasImage: ${profileImage != null},\n'
        '  bio: ${bio.isNotEmpty ? bio.length : 0} chars,\n'
        '  gender: $gender,\n'
        '  religion: $religion,\n'
        '  dob: ${dobDay != null && dobMonth != null && dobYear != null ? "$dobDay $dobMonth $dobYear" : "Not set"},\n'
        '  isSignupReady: $isSignupReady,\n'
        '  isProfileComplete: $isProfileComplete\n'
        ')';
  }
}
