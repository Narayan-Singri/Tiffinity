import 'package:flutter/material.dart';
import 'package:Tiffinity/services/subscription_service.dart';

class CreatePlanPage extends StatefulWidget {
  final int messId;

  const CreatePlanPage({super.key, required this.messId});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedDuration = 30;
  bool _isLoading = false;

  final List<int> _durations = [30, 60, 90, 180, 365];

  Color get _primaryColor => const Color.fromARGB(255, 27, 84, 78);

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await SubscriptionService.createPlan(
        messId: widget.messId,
        name: _nameController.text.trim(),
        durationDays: _selectedDuration,
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success'] == true || result.isNotEmpty) {
          _showSnackbar('Plan created successfully!', isError: false);
          Navigator.pop(context, true);
        } else {
          _showSnackbar('Error: ${result['message'] ?? 'Failed to create plan'}', isError: true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackbar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 100), // Padding for the floating button
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ============================================
  // APP BAR (Professional Rounded Design)
  // ============================================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor,
      elevation: 2,
      shadowColor: Colors.black38,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 48, bottom: 16), // Adjusted for back button
        title: const Text(
          'Create Plan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(60),
            bottomRight: Radius.circular(60),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 18, 65, 60),
                      Color.fromARGB(255, 27, 84, 78)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Premium subtle watermark
              Positioned(
                right: -20,
                top: 10,
                child: Icon(
                  Icons.add_task,
                  size: 130,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // FORM CARD
  // ============================================
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_document, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Plan Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name Field
          _buildFieldLabel(Icons.label_outline, 'Plan Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: _inputDecoration(hint: 'e.g., Monthly Standard, Premium 90 Days'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter plan name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Price Field
          _buildFieldLabel(Icons.currency_rupee, 'Price (₹)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _priceController,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            decoration: _inputDecoration(hint: 'e.g., 2000'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter price';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter valid price';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Duration Selector
          _buildFieldLabel(Icons.access_time, 'Duration (Days)'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _durations.map((days) {
              final isSelected = _selectedDuration == days;
              return ChoiceChip(
                label: Text('$days Days'),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() => _selectedDuration = days);
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: _primaryColor,
                side: BorderSide(
                  color: isSelected ? _primaryColor : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Description Field
          _buildFieldLabel(Icons.description_outlined, 'Description (Optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: _inputDecoration(hint: 'Add plan benefits and details...'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI HELPERS
  // ============================================
  Widget _buildFieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ============================================
  // FLOATING BOTTOM BUTTON
  // ============================================
  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'CREATE PLAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}