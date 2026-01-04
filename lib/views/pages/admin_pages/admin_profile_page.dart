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

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Image picker
  final ImagePicker _picker = ImagePicker();

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
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      // Cancel edit - show confirmation
      _showDiscardDialog();
    } else {
      // Enter edit mode
      HapticFeedback.lightImpact();
      setState(() => _isEditMode = true);
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Discard Changes?'),
            content: const Text(
              'Are you sure you want to discard all changes?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isEditMode = false;
                    _messData =
                        _originalMessData != null
                            ? Map<String, dynamic>.from(_originalMessData!)
                            : null;
                    _userData = Map<String, dynamic>.from(_originalUserData!);
                    _populateControllers();
                  });
                },
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _saveChanges() async {
    // Validate
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
      // Update mess details
      await ApiService.postForm('messes/update_mess_details.php', {
        'mess_id': _messData!['id'].toString(),
        'name': _messNameController.text.trim(),
        'mess_type': _messTypeController.text,
        'description': _descriptionController.text.trim(),
        'phone': _messPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        //'fssai_license': _fssaiController.text.trim(),
        'open_time':
            _openingTime != null
                ? '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}:00'
                : '',
        'close_time':
            _closingTime != null
                ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}:00'
                : '',
      });

      // Update owner details
      await ApiService.postForm('users/update_user_details.php', {
        'uid': _userData!['uid'],
        'name': _ownerNameController.text.trim(),
        'email': _ownerEmailController.text.trim(),
        'phone': _ownerPhoneController.text.trim(),
      });

      // Reload data
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

      Navigator.pop(context); // Close bottom sheet

      setState(() => _isUploadingImage = true);

      final File imageFile = File(pickedFile.path);
      final fileSize = await imageFile.length();

      if (fileSize > 32 * 1024 * 1024) {
        _showSnackbar('Image too large. Max 32MB allowed', isError: true);
        setState(() => _isUploadingImage = false);
        return;
      }

      // Upload to ImgBB
      final imageUrl = await ImageService.uploadToImgBB(imageFile);

      if (imageUrl == null || imageUrl == 'SIZE_EXCEEDED') {
        _showSnackbar('Failed to upload image', isError: true);
        setState(() => _isUploadingImage = false);
        return;
      }

      // Update mess image URL
      await ApiService.postForm('messes/update_mess_image.php', {
        'mess_id': _messData!['id'].toString(),
        'image_url': imageUrl,
      });

      // Reload data
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Update Mess Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF00695C),
                    ),
                    title: const Text('Take Photo'),
                    onTap: () => _pickAndUploadImage(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF00695C),
                    ),
                    title: const Text('Choose from Gallery'),
                    onTap: () => _pickAndUploadImage(ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close, color: Colors.red),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isOpeningTime
              ? (_openingTime ?? TimeOfDay.now())
              : (_closingTime ?? TimeOfDay.now()),
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
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadProfileData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildMessImageSection(),
                        const SizedBox(height: 20),
                        _buildMessInfoCard(),
                        const SizedBox(height: 16),
                        _buildOwnerInfoCard(),
                        const SizedBox(height: 16),
                        if (!_isEditMode) _buildStatisticsCard(),
                        if (!_isEditMode) const SizedBox(height: 16),
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
            Container(height: 250, color: Colors.white),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 27, 84, 78),
      title: const Text('Profile', style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(
            _isEditMode ? Icons.close : Icons.edit,
            color: Colors.white,
          ),
          onPressed: _toggleEditMode,
        ),
      ],
    );
  }

  Widget _buildMessImageSection() {
    final hasImage =
        _messData?['image_url'] != null &&
        _messData!['image_url'].toString().isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        Hero(
          tag: 'mess_image',
          child: GestureDetector(
            onTap:
                hasImage
                    ? () => _showFullImage(context, _messData!['image_url'])
                    : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    hasImage
                        ? CachedNetworkImage(
                          imageUrl: _messData!['image_url'],
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => _buildPlaceholder(),
                        )
                        : _buildPlaceholder(),
              ),
            ),
          ),
        ),
        if (_isUploadingImage)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (_isEditMode && !_isUploadingImage)
          Positioned(
            bottom: 12,
            right: 28,
            child: FloatingActionButton.small(
              backgroundColor: const Color.fromARGB(255, 27, 84, 78),
              onPressed: _showImagePickerSheet,
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color.fromARGB(255, 27, 84, 78).withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color.fromARGB(255, 27, 84, 78),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 27, 84, 78),
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
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
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

  Widget _buildMessInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mess Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 27, 84, 78),
              ),
            ),
            const SizedBox(height: 20),
            _buildEditableField(
              icon: Icons.store,
              label: 'Mess Name',
              controller: _messNameController,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              icon: Icons.restaurant,
              label: 'Mess Type',
              value: _messTypeController.text,
              items: const ['veg', 'non-veg', 'veg | non-veg'],
              onChanged:
                  _isEditMode
                      ? (val) {
                        setState(() => _messTypeController.text = val!);
                      }
                      : null,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              icon: Icons.description,
              label: 'Description',
              controller: _descriptionController,
              enabled: _isEditMode,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              icon: Icons.phone,
              label: 'Mess Phone',
              controller: _messPhoneController,
              enabled: _isEditMode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            // const SizedBox(height: 16),
            // _buildEditableField(
            //   icon: Icons.badge,
            //   label: 'FSSAI License (Optional)',
            //   controller: _fssaiController,
            //   enabled: _isEditMode,
            //   maxLength: 14,
            // ),
            const SizedBox(height: 16),
            _buildEditableField(
              icon: Icons.location_on,
              label: 'Address',
              controller: _addressController,
              enabled: _isEditMode,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTimeField(
              icon: Icons.access_time,
              label: 'Opening Time',
              time: _openingTime,
              onTap: _isEditMode ? () => _selectTime(context, true) : null,
            ),
            const SizedBox(height: 16),
            _buildTimeField(
              icon: Icons.access_time,
              label: 'Closing Time',
              time: _closingTime,
              onTap: _isEditMode ? () => _selectTime(context, false) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Owner Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 27, 84, 78),
              ),
            ),
            const SizedBox(height: 20),
            _buildEditableField(
              icon: Icons.person,
              label: 'Owner Name',
              controller: _ownerNameController,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              icon: Icons.email,
              label: 'Email',
              controller: _ownerEmailController,
              enabled: _isEditMode,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              icon: Icons.phone,
              label: 'Phone',
              controller: _ownerPhoneController,
              enabled: _isEditMode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              icon: Icons.calendar_today,
              label: 'Registered Since',
              value:
                  _userData?['created_at'] != null
                      ? DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(_userData!['created_at']))
                      : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    // Calculate stats from orders (placeholder - implement with actual order data)
    final rating = _messData?['rating']?.toString() ?? '0.0';
    final totalOrders = 0; // Fetch from orders table
    final completed = 0;
    final cancelled = 0;

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Performance Stats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('⭐', rating, 'Rating'),
                _buildStatItem('📦', totalOrders.toString(), 'Total'),
                _buildStatItem('✅', completed.toString(), 'Done'),
                _buildStatItem('❌', cancelled.toString(), 'Cancel'),
              ],
            ),
          ],
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
            fontWeight: FontWeight.bold,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Logout',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C04B),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
                  _isSaving
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey[800],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: enabled ? Colors.grey[300]! : Colors.transparent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 27, 84, 78),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterText: '',
          ),
        ),
      ],
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
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: onChanged != null ? Colors.grey[50] : Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    onChanged != null ? Colors.grey[300]! : Colors.transparent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 27, 84, 78),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: onTap != null ? Colors.grey[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: onTap != null ? Colors.grey[300]! : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null ? time.format(context) : 'Not set',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: time != null ? Colors.black : Colors.grey[400],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
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
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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
