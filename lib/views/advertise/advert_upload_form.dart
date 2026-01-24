// views/advertise/advert_upload_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../services/wallet_service.dart';
import '../../services/state_service.dart';
import '../../models/task_models.dart';
import '../../models/location_models.dart';
import '../../utils/platform_helper.dart';
import '../../utils/task_helper.dart';
import '../../utils/form_field_helper.dart';
import '../settings/subpages/fund_wallet_view.dart';

class AdvertFormPage extends StatefulWidget {
  final TaskModel task;
  const AdvertFormPage({super.key, required this.task});

  @override
  State<AdvertFormPage> createState() => _AdvertFormPageState();
}

class _AdvertFormPageState extends State<AdvertFormPage> {
  final _formKey = GlobalKey<FormState>();
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
  MediaType _selectedMediaType = MediaType.photo;

  // Media handling
  final List<File> _selectedMediaFiles = [];
  final ImagePicker _picker = ImagePicker();

  // Video player controllers
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _videoIsPlaying = {};
  final Map<String, Duration?> _videoDurations = {};

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
    _initializeForm();
    _loadInitialData();

    _quantityController.addListener(() {
      if (mounted) {
        setState(() => _quantity = int.tryParse(_quantityController.text) ?? 0);
      }
    });
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoIsPlaying.clear();
    _videoDurations.clear();
    
    _quantityController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.task.platforms.isNotEmpty) {
      _selectedPlatform = widget.task.platforms.first;
    }
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

  Future<void> _initializeVideoController(File videoFile) async {
    final videoPath = videoFile.path;
    
    if (_videoControllers.containsKey(videoPath)) {
      return; // Already initialized
    }

    try {
      final VideoPlayerController controller = VideoPlayerController.file(videoFile);
      
      await controller.initialize();
      
      if (mounted) {
        setState(() {
          _videoControllers[videoPath] = controller;
          _videoIsPlaying[videoPath] = false;
          _videoDurations[videoPath] = controller.value.duration;
        });
      }

      // Add listener for video completion
      controller.addListener(() {
        if (mounted && controller.value.isInitialized) {
          if (controller.value.position >= controller.value.duration) {
            controller.pause();
            controller.seekTo(Duration.zero);
            if (mounted) {
              setState(() {
                _videoIsPlaying[videoPath] = false;
              });
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
    }
  }

  void _playPauseVideo(String videoPath) {
    final controller = _videoControllers[videoPath];
    if (controller != null && controller.value.isInitialized) {
      if (_videoIsPlaying[videoPath] == true) {
        controller.pause();
        setState(() {
          _videoIsPlaying[videoPath] = false;
        });
      } else {
        controller.play();
        setState(() {
          _videoIsPlaying[videoPath] = true;
        });
      }
    }
  }

  Future<void> _pickMedia() async {
    final mediaSource = await showModalBottomSheet<MediaSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Photo Library',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () => Navigator.pop(context, MediaSource.gallery),
            ),
            ListTile(
              leading: Icon(
                Icons.video_library,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Video Library',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () => Navigator.pop(context, MediaSource.gallery),
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Take ${_selectedMediaType == MediaType.photo ? 'Photo' : 'Video'}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () => Navigator.pop(context, MediaSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (mediaSource == null) return;

    try {
      if (_selectedMediaType == MediaType.photo) {
        final pickedFiles = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
        );

        if (pickedFiles.isNotEmpty) {
          final List<File> newFiles = [];
          for (var pickedFile in pickedFiles) {
            final file = File(pickedFile.path);
            final fileSize = await file.length();

            if (fileSize <= 10 * 1024 * 1024) {
              newFiles.add(file);
            } else {
              _showError('Image "${pickedFile.name}" exceeds 10MB limit');
            }
          }

          setState(() {
            _selectedMediaFiles.addAll(newFiles);
            if (_selectedMediaFiles.length > 10) {
              _selectedMediaFiles.removeRange(10, _selectedMediaFiles.length);
              _showError(
                'Maximum 10 photos allowed. Only first 10 photos were added.',
              );
            }
          });
        }
      } else if (_selectedMediaType == MediaType.video) {
        final pickedFile = await _picker.pickVideo(
          source: mediaSource == MediaSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
        );

        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final fileSize = await file.length();

          if (fileSize <= 100 * 1024 * 1024) {
            setState(() {
              _selectedMediaFiles.add(file);
              if (_selectedMediaFiles.length > 5) {
                _selectedMediaFiles.removeLast();
                _showError('Maximum 5 videos allowed');
              }
            });
            
            // Initialize video controller for preview
            _initializeVideoController(file);
          } else {
            _showError('Video "${pickedFile.name}" exceeds 100MB limit');
          }
        }
      }
    } catch (e) {
      _showError('Failed to pick media: ${e.toString()}');
    }
  }

  void _removeMedia(int index) {
    final file = _selectedMediaFiles[index];
    final filePath = file.path;
    
    // Dispose video controller if it's a video
    if (_videoControllers.containsKey(filePath)) {
      _videoControllers[filePath]!.dispose();
      _videoControllers.remove(filePath);
      _videoIsPlaying.remove(filePath);
      _videoDurations.remove(filePath);
    }
    
    setState(() => _selectedMediaFiles.removeAt(index));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  double get _totalPrice => widget.task.price * _quantity;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill all required fields correctly');
      return;
    }

    if (_selectedMediaFiles.isEmpty) {
      _showError('Please select at least one media file');
      return;
    }

    if (_selectedPlatform == null) {
      _showError('Please select a platform');
      return;
    }

    final balanceCheck = await _walletService.checkWalletBalance(_totalPrice);
    if (balanceCheck['has_sufficient'] == false) {
      _showInsufficientBalanceDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requirements = TaskHelper.getTaskRequirements(widget.task.category);

      final List<String> mediaStoragePaths =
          _selectedMediaFiles.map((f) => f.path).toList();
      final List<String> mediaUrls = [];

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
        caption: _captionController.text.trim(),
        mediaType: _selectedMediaType.name,
        mediaUrls: mediaUrls,
        mediaStoragePaths: mediaStoragePaths,
        postLink: null,
        unitPrice: widget.task.price,
        totalPrice: _totalPrice,
        metadata: {
          'submitted_at': DateTime.now().toIso8601String(),
          'file_count': _selectedMediaFiles.length,
          'platform': _selectedPlatform!,
          'platform_display_name': PlatformHelper.getPlatformDisplayName(
            _selectedPlatform!,
          ),
          'category': widget.task.category,
          'requirements': requirements,
          'media_files': {
            'urls': mediaUrls,
            'paths': mediaStoragePaths,
            'count': _selectedMediaFiles.length,
            'type': _selectedMediaType.name,
          },
        },
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
          'Create Advert',
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
                    _buildTaskHeader(theme, colorScheme),
                    const SizedBox(height: 24),
                    _buildMediaTypeSelector(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildMediaUploadSection(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildPlatformSection(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildQuantitySection(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildLocationSection(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildCaptionSection(colorScheme, textTheme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          _buildPaymentBar(hasSufficient, colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(ThemeData theme, ColorScheme colorScheme) {
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
              color: PlatformHelper.getPlatformColor(
                widget.task.platforms.isNotEmpty
                    ? widget.task.platforms.first
                    : 'social',
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                TaskHelper.getTaskCategoryIcon(widget.task.category),
                color: colorScheme.primary,
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
                        text: '₦${widget.task.price.toStringAsFixed(0)} per Advert Post',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeSelector(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Type *',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMediaTypeButton(
              'PHOTOS',
              Icons.photo_library,
              MediaType.photo,
              colorScheme,
            ),
            const SizedBox(width: 12),
            _buildMediaTypeButton(
              'VIDEOS',
              Icons.video_library,
              MediaType.video,
              colorScheme,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedMediaType == MediaType.photo
              ? 'Upload up to 10 photos (max 10MB each)'
              : 'Upload up to 5 videos (max 100MB each)',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaTypeButton(
    String label,
    IconData icon,
    MediaType type,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedMediaType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMediaType = type;
            _selectedMediaFiles.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : colorScheme.onSurface.withOpacity(0.7),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ) 
    );
  }
  
  Widget _buildMediaUploadSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final maxFiles = _selectedMediaType == MediaType.photo ? 10 : 5;
    final fileSizeLimit =
        _selectedMediaType == MediaType.photo ? '10MB' : '100MB';
    final remainingSlots = maxFiles - _selectedMediaFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Advert Media *',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (_selectedMediaFiles.isNotEmpty)
              Text(
                '${_selectedMediaFiles.length}/$maxFiles',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Media Upload Area
        GestureDetector(
          onTap: _selectedMediaFiles.length < maxFiles ? _pickMedia : null,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: _selectedMediaFiles.isEmpty
                  ? colorScheme.surface
                  : colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedMediaFiles.isEmpty
                    ? colorScheme.outline.withOpacity(0.3)
                    : colorScheme.primary.withOpacity(0.3),
                width: _selectedMediaFiles.isEmpty ? 1 : 2,
              ),
            ),
            child: _selectedMediaFiles.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedMediaType == MediaType.photo
                            ? Icons.photo_library_outlined
                            : Icons.video_library_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload ${_selectedMediaType.name}s',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Max $maxFiles • $fileSizeLimit each',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedMediaType == MediaType.photo
                              ? Icons.photo_library
                              : Icons.video_library,
                          size: 48,
                          color: colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_selectedMediaFiles.length} ${_selectedMediaType.name}${_selectedMediaFiles.length > 1 ? 's' : ''} selected',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (remainingSlots > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap to add ${remainingSlots} more',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),

        // Media Thumbnails
        if (_selectedMediaFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_selectedMediaFiles.length, (index) {
              return _buildMediaThumbnail(index, colorScheme);
            }),
          ),
        ],

        // Action Buttons
        if (_selectedMediaFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _selectedMediaFiles.length < maxFiles ? _pickMedia : null,
                  icon: Icon(Icons.add, color: colorScheme.primary),
                  label: Text(
                    'Add More',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Dispose all video controllers
                    for (final controller in _videoControllers.values) {
                      controller.dispose();
                    }
                    _videoControllers.clear();
                    _videoIsPlaying.clear();
                    _videoDurations.clear();
                    
                    setState(() => _selectedMediaFiles.clear());
                  },
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  label: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMediaThumbnail(int index, ColorScheme colorScheme) {
    final file = _selectedMediaFiles[index];
    final filePath = file.path;
    final isVideo = _selectedMediaType == MediaType.video;
    final controller = _videoControllers[filePath];
    final isPlaying = _videoIsPlaying[filePath] ?? false;
    final duration = _videoDurations[filePath];

    return GestureDetector(
      onTap: () {
        if (isVideo && controller != null && controller.value.isInitialized) {
          _playPauseVideo(filePath);
        }
      },
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              color: isVideo ? Colors.black.withOpacity(0.1) : colorScheme.surface,
            ),
            child: isVideo && controller != null && controller.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        VideoPlayer(controller),
                        // Video overlay
                        Container(
                          color: Colors.black.withOpacity(isPlaying ? 0 : 0.4),
                          child: Center(
                            child: Icon(
                              isPlaying ? Icons.pause_circle : Icons.play_circle,
                              size: 32,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        // Video duration badge
                        if (duration != null)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatDuration(duration),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : isVideo
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 24,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Loading...',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                color: colorScheme.onSurface.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // File Number Badge
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Remove Button
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
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
              items: widget.task.platforms.map((platform) {
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
      ],
    );
  }

  Widget _buildQuantitySection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Adverts *',
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
            hintText: 'How many posts?',
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            prefixIcon: Icon(
              Icons.people,
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
            if (value == null || value.isEmpty) return 'Required';
            final quantity = int.tryParse(value);
            if (quantity == null || quantity < 1) return 'Minimum is 1';
            if (quantity > 1000) return 'Maximum is 1000';
            return null;
          },
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
          child: _isLoadingStates
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

  Widget _buildCaptionSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption for Advertisers *',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _captionController,
          maxLines: 4,
          minLines: 3,
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'What should people write when posting this?',
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
          validator: (value) {
            if (value == null || value.isEmpty) return 'Caption is required';
            if (value.trim().length < 10)
              return 'At least 10 characters required';
            return null;
          },
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
                        '${_selectedMediaFiles.length} ${_selectedMediaType.name}${_selectedMediaFiles.length > 1 ? 's' : ''} • $_quantity posts',
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
                    onPressed: _isLoading
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
                    child: _isLoading
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
      builder: (context) => Dialog(
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
      builder: (context) => Dialog(
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
                'Your advert has been submitted successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  onPressed: () => Navigator.popUntil(
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

enum MediaType { photo, video }

enum MediaSource { camera, gallery }