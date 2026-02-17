import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:Tiffinity/services/image_service.dart';
import 'package:Tiffinity/services/api_service.dart';
import 'package:Tiffinity/views/auth/welcome_page.dart';
import 'package:intl/intl.dart';
import 'package:Tiffinity/views/pages/admin_pages/admin_location_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'earnings_details_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>
    with SingleTickerProviderStateMixin {
  // Data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _messData;
  Map<String, dynamic>? _originalMessData;
  Map<String, dynamic>? _originalUserData;

  // State
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // Controllers for mess data
  final _messNameController = TextEditingController();
  final _messTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _messPhoneController = TextEditingController();
  //final _fssaiController = TextEditingController();
  final _addressController = TextEditingController();

  // Controllers for owner data
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  // Time variables
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  String? _messLocation;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  Color get _primaryColor => const Color(0xFF1B5450);
  Color get _accentColor => const Color(0xFF00C04B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadProfileData();
  }

  @override
  void dispose() {
    _messNameController.dispose();
    _messTypeController.dispose();
    _descriptionController.dispose();
    _messPhoneController.dispose();
    //_fssaiController.dispose();
    _addressController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.currentUser;
      if (user != null) {
        final mess = await MessService.getMessByOwner(user['uid']);
        setState(() {
          _userData = user;
          _messData = mess;
          _originalMessData =
          mess != null ? Map<String, dynamic>.from(mess) : null;
          _originalUserData = Map<String, dynamic>.from(user);
          _isLoading = false;
        });
        _populateControllers();
        _animationController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    if (_messData != null) {
      _messNameController.text = _messData!['name'] ?? '';
      _messTypeController.text = _messData!['mess_type'] ?? 'veg | non-veg';
      _descriptionController.text = _messData!['description'] ?? '';
      _messPhoneController.text = _messData!['phone'] ?? '';
      //_fssaiController.text = _messData!['fssai_license'] ?? '';
      _addressController.text = _messData!['address'] ?? '';

      // Parse times
      if (_messData!['open_time'] != null) {
        final parts = _messData!['open_time'].toString().split(':');
        if (parts.length >= 2) {
          _openingTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      if (_messData!['close_time'] != null) {
        final parts = _messData!['close_time'].toString().split(':');
        if (parts.length >= 2) {
          _closingTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }

    if (_userData != null) {
      _ownerNameController.text = _userData!['name'] ?? '';
      _ownerEmailController.text = _userData!['email'] ?? '';
      _ownerPhoneController.text = _userData!['phone'] ?? '';
    }

    if (_messData != null &&
        _messData!['latitude'] != null &&
        _messData!['longitude'] != null) {
      String shopNo = _messData!['shop_no'] ?? '';
      String landmark = _messData!['landmark'] ?? '';
      String pincode = _messData!['pincode'] ?? '';

      List<String> locationParts = [];
      if (shopNo.isNotEmpty) locationParts.add(shopNo);
      if (landmark.isNotEmpty) locationParts.add(landmark);
      if (pincode.isNotEmpty) locationParts.add(pincode);

      _messLocation =
      locationParts.isNotEmpty ? locationParts.join(', ') : 'Location set';
    }
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      _showDiscardDialog();
    } else {
      HapticFeedback.lightImpact();
      setState(() => _isEditMode = true);
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to discard all changes?',
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditMode = false;
                _messData = _originalMessData != null
                    ? Map<String, dynamic>.from(_originalMessData!)
                    : null;
                _userData = Map<String, dynamic>.from(_originalUserData!);
                _populateControllers();
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_messNameController.text.trim().isEmpty) {
      _showSnackbar('Mess name is required', isError: true);
      return;
    }
    if (_messPhoneController.text.trim().length != 10) {
      _showSnackbar('Phone number must be 10 digits', isError: true);
      return;
    }
    if (_ownerEmailController.text.trim().isEmpty ||
        !_ownerEmailController.text.contains('@')) {
      _showSnackbar('Valid email is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.postForm('messes/update_mess_details.php', {
        'mess_id': _messData!['id'].toString(),
        'name': _messNameController.text.trim(),
        'mess_type': _messTypeController.text,
        'description': _descriptionController.text.trim(),
        'phone': _messPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        //'fssai_license': _fssaiController.text.trim(),
        'open_time': _openingTime != null
            ? '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}:00'
            : '',
        'close_time': _closingTime != null
            ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}:00'
            : '',
      });

      await ApiService.postForm('users/update_user_details.php', {
        'uid': _userData!['uid'],
        'name': _ownerNameController.text.trim(),
        'email': _ownerEmailController.text.trim(),
        'phone': _ownerPhoneController.text.trim(),
      });

      await _loadProfileData();

      setState(() {
        _isSaving = false;
        _isEditMode = false;
      });

      _showSnackbar('Profile updated successfully!', isError: false);
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackbar('Failed to update: $e', isError: true);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      Navigator.pop(context);

      setState(() => _isUploadingImage = true);

      final File imageFile = File(pickedFile.path);
      final fileSize = await imageFile.length();

      if (fileSize > 32 * 1024 * 1024) {
        _showSnackbar('Image too large. Max 32MB allowed', isError: true);
        setState(() => _isUploadingImage = false);
        return;
      }

      final imageUrl = await ImageService.uploadToImgBB(imageFile);

      if (imageUrl == null || imageUrl == 'SIZE_EXCEEDED') {
        _showSnackbar('Failed to upload image', isError: true);
        setState(() => _isUploadingImage = false);
        return;
      }

      await ApiService.postForm('messes/update_mess_image.php', {
        'mess_id': _messData!['id'].toString(),
        'image_url': imageUrl,
      });

      await _loadProfileData();

      setState(() => _isUploadingImage = false);
      _showSnackbar('Image updated successfully!', isError: false);
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnackbar('Error: $e', isError: true);
    }
  }

  void _showImagePickerSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 20).copyWith(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Update Mess Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: _primaryColor.withOpacity(0.08),
                    child: Icon(
                      Icons.camera_alt,
                      color: _primaryColor,
                    ),
                  ),
                  title: const Text('Take Photo'),
                  onTap: () => _pickAndUploadImage(ImageSource.camera),
                ),
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: _primaryColor.withOpacity(0.08),
                    child: Icon(
                      Icons.photo_library,
                      color: _primaryColor,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () => _pickAndUploadImage(ImageSource.gallery),
                ),
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.red.withOpacity(0.06),
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
      isOpeningTime ? (_openingTime ?? TimeOfDay.now()) : (_closingTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authService = AuthService();
        await authService.logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomePage()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          _showSnackbar('Logout failed: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: _buildLoadingSkeleton());
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadProfileData,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadProfileData,
            color: _primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildMessImageSection(),
                        const SizedBox(height: 16),
                        _buildHeaderChipRow(),
                        const SizedBox(height: 16),
                        _buildMessInfoCard(),
                        const SizedBox(height: 16),
                        _buildOwnerInfoCard(),
                        const SizedBox(height: 16),
                        if (!_isEditMode) _buildLocationCard(),
                        const SizedBox(height: 16),
                        if (!_isEditMode) _buildEarningSummaryCard(),
                        const SizedBox(height: 16),
                        if (!_isEditMode) _buildLogoutButton(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isEditMode) _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 260, color: Colors.white),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      backgroundColor: _primaryColor,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mess Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              Text(
                _messData?['name'] ?? 'Your mess details',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              _isEditMode ? Icons.close_rounded : Icons.edit_rounded,
              color: Colors.white,
            ),
            onPressed: _toggleEditMode,
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, const Color(0xFF0E3C37)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildMessImageSection() {
    final hasImage =
        _messData?['image_url'] != null && _messData!['image_url'].toString().isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        Hero(
          tag: 'mess_image',
          child: GestureDetector(
            onTap:
            hasImage ? () => _showFullImage(context, _messData!['image_url']) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withOpacity(0.04),
                  width: 1,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? CachedNetworkImage(
                      imageUrl: _messData!['image_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholder(),
                    )
                        : _buildPlaceholder(),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _messData?['name'] ?? 'Mess',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _messData?['mess_type'] ?? 'veg | non-veg',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!_isEditMode)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (_messData?['rating']?.toString() ??
                                          '0.0'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isUploadingImage)
          Container(
            height: 190,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (_isEditMode && !_isUploadingImage)
          Positioned(
            bottom: 18,
            right: 32,
            child: FloatingActionButton.extended(
              heroTag: 'edit_image',
              backgroundColor: Colors.white.withOpacity(0.95),
              elevation: 3,
              label: Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: _primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Change',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onPressed: _showImagePickerSheet,
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderChipRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Chip(
            avatar: CircleAvatar(
              backgroundColor: _primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: _primaryColor, size: 18),
            ),
            label: Text(
              _userData?['name'] ?? 'Owner',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            backgroundColor: _accentColor.withOpacity(0.08),
            label: Text(
              _isEditMode ? 'Edit mode enabled' : 'View mode',
              style: TextStyle(
                color: _isEditMode ? _accentColor : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _primaryColor.withOpacity(0.08),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _primaryColor,
              child: Text(
                _messData?['name']?[0].toUpperCase() ?? 'M',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _messData?['name'] ?? 'Mess',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Hero(
          tag: 'mess_image',
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildCardShell({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withOpacity(0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: _primaryColor, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMessInfoCard() {
    return _buildCardShell(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child:
            Icon(Icons.storefront_rounded, color: _primaryColor, size: 20),
          ),
          title: const Text(
            'Mess Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _messData?['name'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            const SizedBox(height: 4),
            _buildEditableField(
              icon: Icons.store,
              label: 'Mess Name',
              controller: _messNameController,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 14),
            _buildDropdownField(
              icon: Icons.restaurant,
              label: 'Mess Type',
              value: _messTypeController.text,
              items: const ['veg', 'non-veg', 'veg | non-veg'],
              onChanged: _isEditMode
                  ? (val) {
                setState(() => _messTypeController.text = val!);
              }
                  : null,
            ),
            const SizedBox(height: 14),
            _buildEditableField(
              icon: Icons.description,
              label: 'Description',
              controller: _descriptionController,
              enabled: _isEditMode,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _buildEditableField(
              icon: Icons.phone,
              label: 'Mess Phone',
              controller: _messPhoneController,
              enabled: _isEditMode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 14),
            _buildEditableField(
              icon: Icons.location_on,
              label: 'Address',
              controller: _addressController,
              enabled: _isEditMode,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            _buildTimeField(
              icon: Icons.access_time,
              label: 'Opening Time',
              time: _openingTime,
              onTap: _isEditMode ? () => _selectTime(context, true) : null,
            ),
            const SizedBox(height: 14),
            _buildTimeField(
              icon: Icons.access_time_filled_rounded,
              label: 'Closing Time',
              time: _closingTime,
              onTap: _isEditMode ? () => _selectTime(context, false) : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    return _buildCardShell(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child:
            Icon(Icons.person_rounded, color: _primaryColor, size: 20),
          ),
          title: const Text(
            'Owner Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _userData?['name'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            const SizedBox(height: 4),
            _buildEditableField(
              icon: Icons.person,
              label: 'Owner Name',
              controller: _ownerNameController,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 14),
            _buildEditableField(
              icon: Icons.email,
              label: 'Email',
              controller: _ownerEmailController,
              enabled: _isEditMode,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildEditableField(
              icon: Icons.phone_android,
              label: 'Phone',
              controller: _ownerPhoneController,
              enabled: _isEditMode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 14),
            _buildReadOnlyField(
              icon: Icons.calendar_today,
              label: 'Registered Since',
              value: _userData?['created_at'] != null
                  ? DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(_userData!['created_at']))
                  : 'N/A',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildCardShell(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Colors.green),
          ),
          title: const Text(
            'Mess Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _messLocation ?? 'Set your mess location',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Change Mess Location',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _messLocation ?? 'Set your mess location',
                style: const TextStyle(fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final messId = _messData?['id'];

                if (messId != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminLocationPage(
                        messId: int.parse(messId.toString()),
                        ownerName: _userData?['name'] ?? 'Owner',
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadProfileData();
                  }
                } else {
                  _showSnackbar('Mess ID not found', isError: true);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningSummaryCard() {
    // Later you can compute these from orders API
    final todayEarning = 0;
    final monthEarning = 0;
    final totalEarning = 0;
    final pendingPayout = 0;

    if (_messData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF009688)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EarningsDetailsPage(
                messId: _messData!['id'].toString(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Earning Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to view transactions & completed orders',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Today + Pending
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today\'s Earning',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹$todayEarning',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_clock,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Pending: ₹$pendingPayout',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // This month + total
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'This Month',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹$monthEarning',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Total Earning',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹$totalEarning',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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


  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        onPressed: _handleLogout,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: Colors.red.shade600,
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(icon, label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey[800],
          ),
          decoration: _inputDecoration(enabled: enabled),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required bool enabled}) {
    return InputDecoration(
      filled: true,
      fillColor:
      enabled ? Colors.grey[50] : Colors.grey[100]!.withOpacity(0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: enabled ? Colors.grey[300]! : Colors.transparent,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _primaryColor,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      counterText: '',
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(icon, label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
              .toList(),
          onChanged: onChanged,
          decoration: _inputDecoration(enabled: onChanged != null),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required IconData icon,
    required String label,
    required TimeOfDay? time,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(icon, label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? Colors.grey[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled ? Colors.grey[300]! : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null ? time.format(context) : 'Not set',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: time != null ? Colors.black : Colors.grey[500],
                  ),
                ),
                if (enabled)
                  Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(icon, label),
        const SizedBox(height: 6),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
