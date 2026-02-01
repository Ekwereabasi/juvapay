// views/advertise/engagement_form_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_auth_service.dart';
import '../../services/state_service.dart';
import '../../models/task_models.dart';
import '../../models/location_models.dart';
import '../../utils/platform_helper.dart';
import '../../utils/task_helper.dart';
import '../../utils/form_field_helper.dart';
import '../settings/subpages/fund_wallet_view.dart';

class EngagementFormPage extends StatefulWidget {
  final TaskModel task;
  final int quantity;
  final String platform;

  const EngagementFormPage({
    super.key,
    required this.task,
    required this.quantity,
    required this.platform,
  });

  @override
  State<EngagementFormPage> createState() => _EngagementFormPageState();
}

class _EngagementFormPageState extends State<EngagementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  late final SupabaseAuthService _authService;
  late final StateService _stateService;

  String _selectedGender = 'All Gender';
  StateModel? _selectedState;
  LgaModel? _selectedLga;
  String _selectedReligion = 'All Religion';

  List<StateModel> _states = [];
  List<LgaModel> _lgas = [];

  bool _isLoading = false;
  bool _isLoadingStates = false;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _authService = SupabaseAuthService();
    _stateService = StateService();
    _totalPrice = widget.task.price * widget.quantity;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchStates();
  }

  Future<void> _fetchStates() async {
    setState(() => _isLoadingStates = true);
    try {
      final loadedStates = await _stateService.getStates();
      if (mounted) setState(() => _states = loadedStates);
    } catch (e) {
      debugPrint('State load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStates = false);
    }
  }

  Future<void> _fetchLgas(int stateId) async {
    try {
      final loadedLgas = await _stateService.getLgasByState(stateId);
      if (mounted) setState(() => _lgas = loadedLgas);
    } catch (e) {
      debugPrint('LGA load error: $e');
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _usernameController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill all required fields correctly');
      return;
    }

    // Validate link based on platform
    if (!_validateLinkForPlatform()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.createAdvertiserOrder(
        taskId: widget.task.id,
        platform: widget.platform,
        quantity: widget.quantity,
        targetLink:
            _linkController.text.trim().isEmpty
                ? null
                : _linkController.text.trim(),
        targetUsername:
            _usernameController.text.trim().isEmpty
                ? null
                : _usernameController.text.trim(),
        adContent:
            _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
        metadata: {
          'gender': _selectedGender,
          'religion': _selectedReligion,
          'state': _selectedState?.name,
          'lga': _selectedLga?.name,
          'task_type': 'engagement',
          'engagement_type': _getEngagementType(widget.task),
        },
      );

      debugPrint('Order creation result: $result');

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        // Show detailed error message
        String errorMessage = result['message'] ?? 'Failed to submit order';

        // Check for specific error codes
        if (errorMessage.contains('Insufficient balance') ||
            errorMessage.contains('Insufficient wallet balance')) {
          _showInsufficientBalanceDialog(errorMessage);
        } else if (errorMessage.contains('wallet locked')) {
          _showWalletLockedDialog(errorMessage);
        } else if (errorMessage.contains('Task not found')) {
          _showError('The selected task is no longer available.');
        } else if (errorMessage.contains('payment')) {
          _showError('Payment processing failed. Please try again.');
        } else {
          _showError(errorMessage);
        }

        // Log the error for debugging
        debugPrint(
          'Order creation failed: ${result['error_code']} - $errorMessage',
        );
        if (result['raw_response'] != null) {
          debugPrint('Raw response: ${result['raw_response']}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in _submitOrder: $e');
      debugPrint('Stack trace: $stackTrace');

      _showError('Failed to submit order: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateLinkForPlatform() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return true;

    final platformLower = widget.platform.toLowerCase();

    // Basic URL validation
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      _showError('Please enter a valid URL starting with http:// or https://');
      return false;
    }

    // Platform-specific validation
    if (platformLower.contains('facebook') && !link.contains('facebook.com')) {
      _showError('Please enter a valid Facebook URL');
      return false;
    }

    if (platformLower.contains('instagram') &&
        !link.contains('instagram.com')) {
      _showError('Please enter a valid Instagram URL');
      return false;
    }

    if ((platformLower.contains('x') || platformLower.contains('twitter')) &&
        !link.contains('x.com') &&
        !link.contains('twitter.com')) {
      _showError('Please enter a valid X (Twitter) URL');
      return false;
    }

    if (platformLower.contains('tiktok') && !link.contains('tiktok.com')) {
      _showError('Please enter a valid TikTok URL');
      return false;
    }

    if (platformLower.contains('youtube') &&
        !link.contains('youtube.com') &&
        !link.contains('youtu.be')) {
      _showError('Please enter a valid YouTube URL');
      return false;
    }

    if (platformLower.contains('telegram') &&
        !link.contains('t.me') &&
        !link.contains('telegram.me')) {
      _showError('Please enter a valid Telegram URL');
      return false;
    }

    if (platformLower.contains('whatsapp') && !link.contains('whatsapp.com')) {
      _showError('Please enter a valid WhatsApp URL');
      return false;
    }

    if (platformLower.contains('google_play') &&
        !link.contains('play.google.com')) {
      _showError('Please enter a valid Google Play Store URL');
      return false;
    }

    if ((platformLower.contains('apple') ||
            platformLower.contains('appstore')) &&
        !link.contains('apps.apple.com')) {
      _showError('Please enter a valid Apple App Store URL');
      return false;
    }

    return true;
  }

  void _showInsufficientBalanceDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Insufficient Balance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 20),
                Text(
                  'Total Required: ${FormFieldHelper.formatCurrency(_totalPrice)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You need to add funds to your wallet before creating this order.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FundWalletScreen(),
                    ),
                  );
                },
                child: const Text('Fund Wallet'),
              ),
            ],
          ),
    );
  }

  void _showWalletLockedDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Wallet Locked'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please contact support to unlock your wallet',
                      ),
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
                child: const Text('Contact Support'),
              ),
            ],
          ),
    );
  }

  String _getLinkHint() {
    final platformLower = widget.platform.toLowerCase();

    if (platformLower.contains('facebook'))
      return 'https://facebook.com/yourpage';
    if (platformLower.contains('instagram'))
      return 'https://instagram.com/yourprofile';
    if (platformLower.contains('x') || platformLower.contains('twitter'))
      return 'https://x.com/yourprofile';
    if (platformLower.contains('tiktok'))
      return 'https://tiktok.com/@yourprofile';
    if (platformLower.contains('youtube'))
      return 'https://youtube.com/channel/yourchannel';
    if (platformLower.contains('telegram')) return 'https://t.me/yourchannel';
    if (platformLower.contains('whatsapp'))
      return 'https://chat.whatsapp.com/yourgroup';
    if (platformLower.contains('google_play'))
      return 'https://play.google.com/store/apps/details?id=com.yourapp';
    if (platformLower.contains('apple') || platformLower.contains('appstore'))
      return 'https://apps.apple.com/app/id1234567890';

    return 'Enter your profile or content link';
  }

  String _getEngagementType(TaskModel task) {
    final title = task.title.toLowerCase();
    if (title.contains('follow')) return 'followers';
    if (title.contains('like')) return 'likes';
    if (title.contains('comment')) return 'comments';
    if (title.contains('subscribe')) return 'subscribers';
    if (title.contains('view')) return 'views';
    if (title.contains('download')) return 'downloads';
    if (title.contains('review')) return 'reviews';
    if (title.contains('join')) return 'members';
    if (title.contains('share')) return 'shares';
    return 'engagement';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
          'Complete Order Details',
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(colorScheme, textTheme),
                    const SizedBox(height: 24),
                    _buildLinkSection(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildUsernameSection(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildCaptionSection(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildLocationSection(colorScheme, textTheme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          _buildSubmitButton(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final platformDisplayName = PlatformHelper.getPlatformDisplayName(
      widget.platform,
    );
    final unitType = _getEngagementType(widget.task);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: PlatformHelper.getPlatformColor(
                    widget.platform,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    PlatformHelper.getPlatformIcon(widget.platform),
                    color: PlatformHelper.getPlatformColor(widget.platform),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        children: [
                          TextSpan(text: 'Platform: '),
                          TextSpan(
                            text: platformDisplayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        children: [
                          TextSpan(text: 'Quantity: '),
                          TextSpan(
                            text: '${widget.quantity} ${unitType}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colorScheme.outline.withOpacity(0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                FormFieldHelper.formatCurrency(_totalPrice),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection(ColorScheme colorScheme, TextTheme textTheme) {
    final unitType = _getEngagementType(widget.task);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Link *',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _linkController,
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: _getLinkHint(),
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            prefixIcon: Icon(
              Icons.link,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Target link is required';
            if (!value.contains('.')) return 'Please enter a valid URL';
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the link to your profile, post, or content for $unitType',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Username (Optional)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: '@username',
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            prefixIcon: Icon(
              Icons.person,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the username you want people to engage with',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions (Optional)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _captionController,
          maxLines: 3,
          minLines: 2,
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Add specific instructions for the engagement...',
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell workers exactly what you want them to do',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Location (Optional)',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        // State Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child:
              _isLoadingStates
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : DropdownButtonHideUnderline(
                    child: DropdownButton<StateModel>(
                      value: _selectedState,
                      isExpanded: true,
                      icon: Icon(
                        Icons.expand_more,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      hint: Text(
                        'All Nigeria',
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<StateModel>(
                          value: null,
                          child: Text('All Nigeria'),
                        ),
                        ..._states.map((state) {
                          return DropdownMenuItem<StateModel>(
                            value: state,
                            child: Text(
                              state.name,
                              style: GoogleFonts.inter(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          _selectedLga = null;
                        });
                        if (value != null) _fetchLgas(value.id);
                      },
                    ),
                  ),
        ),

        // LGA Dropdown
        if (_selectedState != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LgaModel>(
                value: _selectedLga,
                isExpanded: true,
                icon: Icon(
                  Icons.expand_more,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                hint: Text(
                  'All Locations',
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                items: [
                  const DropdownMenuItem<LgaModel>(
                    value: null,
                    child: Text('All Locations'),
                  ),
                  ..._lgas.map((lga) {
                    return DropdownMenuItem<LgaModel>(
                      value: lga,
                      child: Text(
                        lga.name,
                        style: GoogleFonts.inter(color: colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) => setState(() => _selectedLga = value),
              ),
            ),
          ),
        ],

        // Gender Selection
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Gender',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  ['All Gender', 'Male', 'Female'].map((gender) {
                    final isSelected = _selectedGender == gender;
                    return ChoiceChip(
                      label: Text(gender),
                      selected: isSelected,
                      onSelected:
                          (selected) =>
                              setState(() => _selectedGender = gender),
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      labelStyle: GoogleFonts.inter(
                        color:
                            isSelected ? Colors.white : colorScheme.onSurface,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),

        // Religion Selection
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Religion',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  ['All Religion', 'Christianity', 'Islam', 'Others'].map((
                    religion,
                  ) {
                    final isSelected = _selectedReligion == religion;
                    return ChoiceChip(
                      label: Text(religion),
                      selected: isSelected,
                      onSelected:
                          (selected) =>
                              setState(() => _selectedReligion = religion),
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      labelStyle: GoogleFonts.inter(
                        color:
                            isSelected ? Colors.white : colorScheme.onSurface,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme, TextTheme textTheme) {
    final isFormValid = _linkController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading || !isFormValid ? null : _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isFormValid
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.3),
              foregroundColor:
                  isFormValid
                      ? (colorScheme.primary.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)
                      : colorScheme.onSurface.withOpacity(0.38),
              disabledBackgroundColor: colorScheme.primary.withOpacity(0.2),
              disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      'COMPLETE ORDER',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessDialog() {
    final unitType = _getEngagementType(widget.task);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Order Created Successfully!',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your engagement order has been submitted and payment processed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Order Details',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quantity:',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                            Text(
                              '${widget.quantity} ${unitType}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Platform:',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                            Text(
                              PlatformHelper.getPlatformDisplayName(
                                widget.platform,
                              ),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                            Text(
                              FormFieldHelper.formatCurrency(_totalPrice),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'GO TO DASHBOARD',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Optionally navigate to order details
                    },
                    child: Text(
                      'View Order Details',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
