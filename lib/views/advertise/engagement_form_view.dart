// views/advertise/engagement_form_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/wallet_service.dart';
import '../../services/state_service.dart';
import '../../models/task_models.dart';
import '../../models/location_models.dart';
import '../../utils/platform_helper.dart';
import '../../utils/task_helper.dart';
import '../../utils/form_field_helper.dart';
import '../settings/subpages/fund_wallet_view.dart';

class EngagementFormPage extends StatefulWidget {
  final TaskModel task;
  const EngagementFormPage({super.key, required this.task});

  @override
  State<EngagementFormPage> createState() => _EngagementFormPageState();
}

class _EngagementFormPageState extends State<EngagementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '10',
  );
  final TextEditingController _captionController = TextEditingController();

  late final WalletService _walletService;
  late final StateService _stateService;

  String? _selectedPlatform;
  String _selectedGender = 'All Gender';
  StateModel? _selectedState;
  LgaModel? _selectedLga;
  String _selectedReligion = 'All Religion';

  List<StateModel> _states = [];
  List<LgaModel> _lgas = [];

  bool _isLoading = false;
  bool _isLoadingStates = false;
  double _currentBalance = 0.0;
  int _quantity = 10;

  @override
  void initState() {
    super.initState();
    _walletService = WalletService();
    _stateService = StateService();
    _loadInitialData();

    if (widget.task.platforms.isNotEmpty) {
      _selectedPlatform = widget.task.platforms.first;
    }

    _quantityController.addListener(() {
      if (mounted) {
        setState(() => _quantity = int.tryParse(_quantityController.text) ?? 0);
      }
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadWalletBalance(), _fetchStates()]);
  }

  Future<void> _loadWalletBalance() async {
    try {
      final wallet = await _walletService.getWalletBalance();
      setState(() => _currentBalance = (wallet['balance'] as num).toDouble());
    } catch (e) {
      debugPrint('Wallet error: $e');
    }
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
    _quantityController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  double get _totalPrice => widget.task.price * _quantity;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill all required fields correctly');
      return;
    }

    if (_selectedPlatform == null) {
      _showError('Please select a platform');
      return;
    }

    // Validate link based on platform
    if (!_validateLinkForPlatform()) {
      return;
    }

    final balanceCheck = await _walletService.checkWalletBalance(_totalPrice);
    if (balanceCheck['has_sufficient'] == false) {
      _showInsufficientBalanceDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _walletService.processOrderPayment(
        taskId: widget.task.id,
        taskTitle: widget.task.title,
        taskCategory: widget.task.category,
        platform: _selectedPlatform!,
        quantity: _quantity,
        gender: _selectedGender,
        stateId: _selectedState?.id,
        stateName: _selectedState?.name,
        lgaId: _selectedLga?.id,
        lgaName: _selectedLga?.name,
        religion: _selectedReligion,
        postLink: _linkController.text.trim(),
        caption: _captionController.text.trim(),
        unitPrice: widget.task.price,
        totalPrice: _totalPrice,
        mediaType: 'none',
        mediaUrls: null,
        mediaStoragePaths: null,
      );

      if (result['success'] == true) {
        await _loadWalletBalance();
        _showSuccessDialog();
      } else {
        _showError(result['message'] ?? 'Failed to submit order');
      }
    } catch (e) {
      _showError('Failed to submit order: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateLinkForPlatform() {
    if (_selectedPlatform == null) return true;

    final link = _linkController.text.trim();
    if (link.isEmpty) return true;

    final platformName = PlatformHelper.getPlatformDisplayName(
      _selectedPlatform!,
    );
    final platformLower = _selectedPlatform!.toLowerCase();

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

    return true;
  }

  String _getLinkHint() {
    if (_selectedPlatform == null) return 'Enter your link...';

    final platformLower = _selectedPlatform!.toLowerCase();

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

  void _navigateToFundWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FundWalletScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasSufficient = _currentBalance >= _totalPrice;

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
          'Create Engagement',
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
                    // Task Header
                    _buildTaskHeader(colorScheme, textTheme),
                    const SizedBox(height: 24),

                    // Platform Selection
                    _buildPlatformSection(colorScheme, textTheme),
                    const SizedBox(height: 20),

                    // Quantity
                    _buildQuantitySection(colorScheme, textTheme),
                    const SizedBox(height: 20),

                    // Target Demographics
                    _buildDemographicsSection(colorScheme, textTheme),
                    const SizedBox(height: 20),

                    // Location
                    _buildLocationSection(colorScheme, textTheme),
                    const SizedBox(height: 20),

                    // Social Media Link
                    _buildLinkSection(colorScheme, textTheme),
                    const SizedBox(height: 20),

                    // Caption
                    _buildCaptionSection(colorScheme, textTheme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Payment Bar
          _buildPaymentBar(hasSufficient, colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(ColorScheme colorScheme, TextTheme textTheme) {
    final platform =
        widget.task.platforms.isNotEmpty
            ? widget.task.platforms.first
            : 'social';
    final unitType = _getUnitType(widget.task);

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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: PlatformHelper.getPlatformColor(platform).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                TaskHelper.getTaskCategoryIcon(widget.task.category),
                color: PlatformHelper.getPlatformColor(platform),
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
                      const TextSpan(text: 'Pricing: '),
                      TextSpan(
                        text:
                            '₦${widget.task.price.toStringAsFixed(0)} per $unitType',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
                // Task Tags
                if (widget.task.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        widget.task.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Platform *',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPlatform,
              isExpanded: true,
              icon: Icon(
                Icons.expand_more,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              hint: Text(
                'Select Platform',
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              items:
                  widget.task.platforms.map((platform) {
                    return DropdownMenuItem<String>(
                      value: platform,
                      child: Row(
                        children: [
                          Icon(
                            PlatformHelper.getPlatformIcon(platform),
                            color: PlatformHelper.getPlatformColor(platform),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            PlatformHelper.getPlatformDisplayName(platform),
                            style: GoogleFonts.inter(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => _selectedPlatform = value),
            ),
          ),
        ),
        // Platform Chips
        if (widget.task.platforms.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.task.platforms.map((platform) {
                  final isSelected = _selectedPlatform == platform;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlatform = platform),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? PlatformHelper.getPlatformColor(platform)
                                : PlatformHelper.getPlatformColor(
                                  platform,
                                ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? PlatformHelper.getPlatformColor(platform)
                                  : PlatformHelper.getPlatformColor(
                                    platform,
                                  ).withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PlatformHelper.getPlatformIcon(platform),
                            size: 14,
                            color:
                                isSelected
                                    ? Colors.white
                                    : PlatformHelper.getPlatformColor(platform),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            PlatformHelper.getPlatformDisplayName(platform),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : PlatformHelper.getPlatformColor(
                                        platform,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantitySection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of ${_getUnitType(widget.task)}s *',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            prefixIcon: Icon(
              Icons.people,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity--;
                        _quantityController.text = _quantity.toString();
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () {
                    if (_quantity < 10000) {
                      setState(() {
                        _quantity++;
                        _quantityController.text = _quantity.toString();
                      });
                    }
                  },
                ),
              ],
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
            if (value == null || value.isEmpty) return 'Required';
            final quantity = int.tryParse(value);
            if (quantity == null || quantity < 1) return 'Minimum is 1';
            if (quantity > 10000) return 'Maximum is 10,000';
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Total: ₦${(_quantity * widget.task.price).toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDemographicsSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Audience',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Gender Selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gender',
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
              'Religion',
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
      ],
    );
  }

  Widget _buildLinkSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Media Link *',
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
            if (value == null || value.isEmpty) return 'Link is required';
            if (!value.contains('.')) return 'Please enter a valid URL';
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the link to your profile, post, or content',
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
            hintText: 'Add any special instructions for users...',
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
      ],
    );
  }

  Widget _buildPaymentBar(
    bool hasSufficient,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormFieldHelper.formatCurrency(_totalPrice),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Balance',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormFieldHelper.formatCurrency(_currentBalance),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: hasSufficient ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_quantity ${_getUnitType(widget.task)}${_quantity > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      if (_selectedPlatform != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          PlatformHelper.getPlatformDisplayName(
                            _selectedPlatform!,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : (hasSufficient
                                ? _submitOrder
                                : _navigateToFundWallet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasSufficient ? colorScheme.primary : Colors.orange,
                      foregroundColor: Colors.white,
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
                              hasSufficient ? 'CREATE ORDER' : 'FUND WALLET',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getUnitType(TaskModel task) {
    final title = task.title.toLowerCase();
    if (title.contains('follow')) return 'Follower';
    if (title.contains('like')) return 'Like';
    if (title.contains('comment')) return 'Comment';
    if (title.contains('subscribe')) return 'Subscriber';
    if (title.contains('view')) return 'View';
    if (title.contains('download')) return 'Download';
    if (title.contains('review')) return 'Review';
    if (title.contains('join')) return 'Member';
    if (title.contains('share')) return 'Share';
    return 'Engagement';
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

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
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
                  Icon(
                    Icons.account_balance_wallet,
                    size: 60,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Insufficient Balance',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You need ₦${(_totalPrice - _currentBalance).toStringAsFixed(0)} more to complete this order.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToFundWallet();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'FUND WALLET',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSuccessDialog() {
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
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Order Created!',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your engagement order has been submitted successfully.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FormFieldHelper.formatCurrency(_totalPrice),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
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
                ],
              ),
            ),
          ),
    );
  }
}
