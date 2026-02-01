import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juvapay/services/supabase_auth_service.dart';

class UploadProofScreen extends StatefulWidget {
  final String assignmentId;
  final Map<String, dynamic> taskData;

  const UploadProofScreen({
    super.key,
    required this.assignmentId,
    required this.taskData,
  });

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isSubmitting = false;
  bool _hasImageError = false;
  String? _imageError;

  static const _maxUsernameLength = 50;
  static const _allowedImageSize = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    // Pre-fill username if available from task data
    if (widget.taskData['proof_platform_username'] != null) {
      _usernameController.text =
          widget.taskData['proof_platform_username'].toString();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Validate file size
        final fileSize = await file.length();
        if (fileSize > _allowedImageSize) {
          _setImageError('Image size exceeds 10MB limit');
          return;
        }

        // Validate file extension
        final extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          _setImageError('Only JPG, PNG, and GIF images are allowed');
          return;
        }

        setState(() {
          _imageFile = file;
          _hasImageError = false;
          _imageError = null;
        });
      }
    } catch (e) {
      _setImageError('Failed to pick image: ${e.toString()}');
    }
  }

  void _setImageError(String error) {
    if (mounted) {
      setState(() {
        _hasImageError = true;
        _imageError = error;
      });
    }
  }

  bool _validateForm() {
    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your social media username', isError: true);
      return false;
    }

    if (_usernameController.text.trim().length > _maxUsernameLength) {
      _showSnackBar('Username is too long', isError: true);
      return false;
    }

    if (_imageFile == null) {
      _showSnackBar('Please upload a screenshot as proof', isError: true);
      return false;
    }

    if (_hasImageError) {
      _showSnackBar('Please fix image errors before submitting', isError: true);
      return false;
    }

    return true;
  }

  Future<void> _submitProof() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _authService.submitTaskProof(
        assignmentId: widget.assignmentId,
        platformUsername: _usernameController.text.trim(),
        proofImage: _imageFile!,
      );

      if (result['success'] == true) {
        if (mounted) {
          await _showSuccessDialog();
        }
      } else {
        _showSnackBar(result['message'] ?? 'Submission failed', isError: true);
      }
    } catch (e) {
      _showSnackBar(
        'Submission failed: ${_getUserFriendlyError(e)}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getUserFriendlyError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (errorString.contains('storage') ||
        errorString.contains('upload')) {
      return 'Failed to upload image. Please try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    return 'Please try again later.';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
          ),
          backgroundColor: isError ? theme.colorScheme.error : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder:
          (ctx) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Task Submitted!",
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your proof has been submitted for review.",
                    style: Theme.of(ctx).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (widget.taskData['payout_amount'] != null)
                    Text(
                      "Payout: ₦${(widget.taskData['payout_amount'] as num).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    "You'll be notified once it's approved.",
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Close upload screen
                    Navigator.pop(context); // Close task execution screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        "Upload Proof",
        style: Theme.of(
          context,
        ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: Theme.of(context).appBarTheme.elevation ?? 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Theme.of(context).appBarTheme.iconTheme?.color,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      iconTheme: Theme.of(context).appBarTheme.iconTheme,
      actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskInfoSection(theme),
              const SizedBox(height: 20),
              _buildWarningSection(theme, isDark),
              const SizedBox(height: 25),
              _buildUsernameInputSection(theme, isDark),
              const SizedBox(height: 25),
              _buildImageUploadSection(theme, isDark),
              const SizedBox(height: 30),
              _buildSubmitButton(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoSection(ThemeData theme) {
    final taskTitle = widget.taskData['task_title'] ?? 'Task';
    final payoutAmount = widget.taskData['payout_amount'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task:",
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  taskTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Payout:",
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
              const SizedBox(height: 4),
              Text(
                '₦${payoutAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Important: Your proof must clearly show task completion. "
              "Make sure the screenshot includes all required elements.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade700,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameInputSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Social Media Username *",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          style: theme.textTheme.bodyLarge,
          maxLength: _maxUsernameLength,
          decoration: InputDecoration(
            hintText: "@username or full profile URL",
            hintStyle: TextStyle(color: theme.hintColor),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            counterText: '',
            prefixIcon: Icon(Icons.person_outline, color: theme.hintColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_usernameController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_usernameController.text.length}/$_maxUsernameLength',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageUploadSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Upload Screenshot *",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (_hasImageError)
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 16,
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (_imageError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _imageError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        GestureDetector(
          onTap: _isSubmitting ? null : _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _hasImageError
                        ? theme.colorScheme.error
                        : theme.dividerColor.withOpacity(0.5),
                width: _hasImageError ? 2 : 1,
              ),
            ),
            child: _buildImageContent(theme, isDark),
          ),
        ),

        if (_imageFile != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isSubmitting ? null : _pickImage,
            icon: Icon(Icons.refresh, size: 16, color: theme.primaryColor),
            label: Text(
              "Change Image",
              style: TextStyle(color: theme.primaryColor, fontSize: 14),
            ),
          ),
        ],

        const SizedBox(height: 8),
        Text(
          "Upload a clear screenshot showing task completion",
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildImageContent(ThemeData theme, bool isDark) {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _imageFile!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Failed to load image",
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 16),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.primaryColor.withOpacity(0.1),
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Tap to select screenshot",
          style: TextStyle(color: theme.hintColor, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          "JPG, PNG, or GIF • Max 10MB",
          style: TextStyle(
            color: theme.hintColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isDark) {
    final isFormValid =
        _usernameController.text.trim().isNotEmpty &&
        _imageFile != null &&
        !_hasImageError;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting || !isFormValid ? null : _submitProof,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFormValid
                  ? theme.primaryColor
                  : theme.primaryColor.withOpacity(0.3),
          foregroundColor:
              isFormValid
                  ? (theme.primaryColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white)
                  : theme.hintColor,
          disabledBackgroundColor: theme.primaryColor.withOpacity(0.2),
          disabledForegroundColor: theme.hintColor,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 20,
                      color:
                          isFormValid
                              ? (theme.primaryColor.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white)
                              : theme.hintColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "SUBMIT PROOF",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
