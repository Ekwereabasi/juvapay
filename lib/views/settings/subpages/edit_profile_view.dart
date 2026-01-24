import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_auth_service.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  File? _imageFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  String? _selectedReligion;
  int? _selectedDay;
  String? _selectedMonth;
  int? _selectedYear;

  String? _currentProfileUrl;
  int? _selectedStateId;
  int? _selectedLgaId;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> _religions = [
    'Christianity',
    'Islam',
    'Traditional',
    'Other',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _nameController.addListener(() => setState(() {}));
    _usernameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _bioController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  double _calculateProgress() {
    int totalFields = 8;
    int filledFields = 0;
    if (_nameController.text.isNotEmpty) filledFields++;
    if (_usernameController.text.isNotEmpty) filledFields++;
    if (_phoneController.text.isNotEmpty) filledFields++;
    if (_bioController.text.isNotEmpty) filledFields++;
    if (_selectedGender != null) filledFields++;
    if (_selectedReligion != null) filledFields++;
    if (_selectedDay != null) filledFields++;
    if (_imageFile != null ||
        (_currentProfileUrl != null && _currentProfileUrl!.isNotEmpty))
      filledFields++;
    return filledFields / totalFields;
  }

  void _showTopSnackBar(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor:
            isError ? theme.colorScheme.error : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      // Get user profile using the correct method
      final profile = await _authService.getUserProfile();
      final user = _authService.getCurrentUser();

      if (profile != null) {
        _nameController.text = profile['full_name']?.toString() ?? '';
        _usernameController.text = profile['username']?.toString() ?? '';
        _bioController.text = profile['bio']?.toString() ?? '';
        _phoneController.text = profile['phone_number']?.toString() ?? '';
        _currentProfileUrl =
            profile['avatar_url']?.toString(); // Updated field name
        _emailController.text = user?.email ?? '';

        setState(() {
          _selectedGender = profile['gender']?.toString();
          _selectedReligion = profile['religion']?.toString();
          _selectedDay = profile['dob_day'] as int?;
          _selectedMonth = profile['dob_month']?.toString();
          _selectedYear = profile['dob_year'] as int?;
          _selectedStateId = profile['state_id'] as int?;
          _selectedLgaId = profile['lga_id'] as int?;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _showTopSnackBar('Failed to load profile', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showTopSnackBar('Failed to pick image', isError: true);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    DateTime initialDate = DateTime(
      _selectedYear ?? DateTime.now().year - 18,
      _selectedMonth != null ? _months.indexOf(_selectedMonth!) + 1 : 1,
      _selectedDay ?? 1,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onSurface: theme.textTheme.bodyLarge?.color,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDay = picked.day;
        _selectedMonth = _months[picked.month - 1];
        _selectedYear = picked.year;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      String? avatarUrl = _currentProfileUrl;

      // Upload image if new one is selected
      if (_imageFile != null) {
        final uploadResult = await _authService.uploadAvatar(_imageFile!);
        if (uploadResult['success'] == true) {
          avatarUrl = uploadResult['url'];
        } else {
          _showTopSnackBar(
            uploadResult['message'] ?? 'Failed to upload image',
            isError: true,
          );
        }
      }

      // Update profile using the correct method
      final updateResult = await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: avatarUrl,
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        religion: _selectedReligion,
        dobDay: _selectedDay,
        dobMonth: _selectedMonth,
        dobYear: _selectedYear,
        stateId: _selectedStateId,
        lgaId: _selectedLgaId,
      );

      if (updateResult['success'] == true) {
        _showTopSnackBar('Profile updated successfully!');
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showTopSnackBar(
          updateResult['message'] ?? 'Failed to update profile',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _showTopSnackBar(
        'Error updating profile: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.dividerColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : theme.primaryColor,
            ),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileAvatar(theme),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "${(progress * 100).toInt()}% Profile Completed",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildLabel("Name", theme),
                  _buildTextField(
                    controller: _nameController,
                    hint: "Full Name",
                    icon: Icons.person_outline,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Username", theme),
                  _buildTextField(
                    controller: _usernameController,
                    hint: "Username",
                    icon: Icons.alternate_email,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Phone Number", theme),
                  _buildTextField(
                    controller: _phoneController,
                    hint: "Phone",
                    icon: Icons.phone_outlined,
                    theme: theme,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Bio", theme),
                  _buildTextField(
                    controller: _bioController,
                    hint: "A short bio",
                    maxLines: 3,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Gender", theme),
                            _buildDropdown(
                              value: _selectedGender,
                              items: ['Male', 'Female', 'Other'],
                              hint: "Gender",
                              theme: theme,
                              onChanged:
                                  (v) => setState(() => _selectedGender = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Religion", theme),
                            _buildDropdown(
                              value: _selectedReligion,
                              items: _religions,
                              hint: "Religion",
                              theme: theme,
                              onChanged:
                                  (v) => setState(() => _selectedReligion = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Birthday", theme),
                  _buildBirthdaySelector(theme),
                  const SizedBox(height: 20),
                  // Display State and LGA if available
                  if (_selectedStateId != null && _selectedLgaId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Location", theme),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'State ID: $_selectedStateId, LGA ID: $_selectedLgaId',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  _buildLabel("Email (Read Only)", theme),
                  _buildTextField(
                    controller: _emailController,
                    hint: "Email",
                    readOnly: true,
                    fillColor: theme.disabledColor.withOpacity(0.05),
                    theme: theme,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'SAVE PROFILE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ThemeData theme) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: theme.dividerColor.withOpacity(0.3),
            backgroundImage:
                _imageFile != null
                    ? FileImage(_imageFile!) as ImageProvider
                    : (_currentProfileUrl != null &&
                            _currentProfileUrl!.isNotEmpty
                        ? NetworkImage(_currentProfileUrl!)
                        : null),
            child:
                (_imageFile == null &&
                        (_currentProfileUrl == null ||
                            _currentProfileUrl!.isEmpty))
                    ? Icon(Icons.person, size: 50, color: theme.hintColor)
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdaySelector(ThemeData theme) {
    String dateStr =
        (_selectedDay != null)
            ? "$_selectedDay $_selectedMonth, $_selectedYear"
            : "Select Birthday";

    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateStr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    _selectedDay == null
                        ? theme.hintColor
                        : theme.textTheme.bodyLarge?.color,
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color:
                  _selectedDay == null ? theme.hintColor : theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    Color? fillColor,
    required ThemeData theme,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge?.copyWith(
        color:
            readOnly
                ? theme.textTheme.bodyLarge?.color?.withOpacity(0.6)
                : theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? theme.cardColor,
        prefixIcon:
            icon != null
                ? Icon(
                  icon,
                  color: theme.primaryColor.withOpacity(0.7),
                  size: 20,
                )
                : null,
        hintText: hint,
        hintStyle: TextStyle(color: theme.hintColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 0,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ThemeData theme,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          isExpanded: true,
          dropdownColor: theme.cardColor,
          icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
          items:
              items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: theme.textTheme.bodyMedium),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
