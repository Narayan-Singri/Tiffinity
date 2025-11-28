import 'package:Tiffinity/views/pages/admin_pages/admin_widget_tree.dart';
import 'package:Tiffinity/views/widgets/auth_field.dart';
import 'package:Tiffinity/views/widgets/auth_gradient_button.dart';
import 'package:Tiffinity/services/mess_service.dart';
import 'package:flutter/material.dart';
import 'package:Tiffinity/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Model for a timing slot
class TimeSlot {
  TextEditingController openingController;
  TextEditingController closingController;

  TimeSlot({String? opening, String? closing})
    : openingController = TextEditingController(text: opening),
      closingController = TextEditingController(text: closing);
}

class AdminSetupPage extends StatefulWidget {
  final String userId;
  const AdminSetupPage({super.key, required this.userId});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final messNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  String _messType = "Veg";
  bool _isLoading = false;

  //Image picker
  File? _messImage;
  final ImagePicker _picker = ImagePicker();

  // List of time slots (first mandatory)
  List<TimeSlot> timeSlots = [TimeSlot()];

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Mess Photo'),
          content: const Text('Choose where to upload photo from:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickMessImageFromDevice();
              },
              child: const Text('Device'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickMessImageFromCamera();
              },
              child: const Text('Camera'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickMessImageFromDevice() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;

        if (fileSize > 32 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Image too large: ${fileSizeMB.toStringAsFixed(2)}MB\nMax: 32MB allowed',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() => _messImage = file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Image selected: ${fileSizeMB.toStringAsFixed(2)}MB',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _pickMessImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / 1024 / 1024;

        if (fileSize > 32 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Image too large: ${fileSizeMB.toStringAsFixed(2)}MB\nMax: 32MB allowed',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() => _messImage = file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Image selected: ${fileSizeMB.toStringAsFixed(2)}MB',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _saveMessDetails() async {
    if (_messImage == null) {
      _showError("Please upload a mess image (Required Field)");
      return;
    }

    if (messNameController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        timeSlots.any(
          (slot) =>
              slot.openingController.text.trim().isEmpty ||
              slot.closingController.text.trim().isEmpty,
        )) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_messImage != null) {
        print('🖼️ Uploading mess image...');
        imageUrl = await ImageService.uploadToImgBB(_messImage!);

        if (imageUrl == 'SIZE_EXCEEDED') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Image too large! Maximum 32MB allowed.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Image upload failed. Check internet.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Create mess using MySQL API
      final result = await MessService.createMess(
        ownerId: widget.userId,
        name: messNameController.text.trim(),
        description: descriptionController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        messType: _messType,
        imageUrl: imageUrl,
        isOnline: true,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminWidgetTree()),
          (route) => false,
        );
      } else {
        _showError(result['message'] ?? 'Failed to save mess details');
      }
    } catch (e) {
      _showError("Failed to save details: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Widget _buildTimeField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          controller.text = time.format(context);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(width: 3.0),
        ),
        contentPadding: const EdgeInsets.all(20.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Mess Details.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _messImage == null
                                    ? Colors.red
                                    : const Color.fromARGB(255, 27, 84, 78),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          children: [
                            if (_messImage != null) ...{
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_messImage!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            } else ...{
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: Icon(
                                  Icons.restaurant,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 12),
                            },
                            ElevatedButton.icon(
                              onPressed: _showImageSourceDialog,
                              icon: const Icon(Icons.image),
                              label: Text(
                                _messImage == null
                                    ? 'Upload Mess Image'
                                    : 'Change Image',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  27,
                                  84,
                                  78,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_messImage == null)
                              const Text(
                                '* Required Field',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AuthField(
                        hintText: "Mess Name",
                        icon: Icons.store,
                        controller: messNameController,
                      ),
                      const SizedBox(height: 20),
                      AuthField(
                        hintText: "Phone Number",
                        icon: Icons.phone,
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                      const SizedBox(height: 20),
                      AuthField(
                        hintText: "Description",
                        icon: Icons.description,
                        controller: descriptionController,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mess Type',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            RadioListTile(
                              title: const Text(
                                "Veg",
                                style: TextStyle(fontSize: 16),
                              ),
                              value: "Veg",
                              groupValue: _messType,
                              onChanged:
                                  (value) => setState(() => _messType = value!),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(vertical: -4),
                            ),
                            RadioListTile(
                              title: const Text(
                                "Non-Veg",
                                style: TextStyle(fontSize: 16),
                              ),
                              value: "Non-Veg",
                              groupValue: _messType,
                              onChanged:
                                  (value) => setState(() => _messType = value!),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(vertical: -4),
                            ),
                            RadioListTile(
                              title: const Text(
                                "Veg | Non-Veg",
                                style: TextStyle(fontSize: 16),
                              ),
                              value: "Veg | Non-Veg",
                              groupValue: _messType,
                              onChanged:
                                  (value) => setState(() => _messType = value!),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(vertical: -4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTimeField(
                                      timeSlots[0].openingController,
                                      "Opening Time",
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 2,
                                    color: Colors.grey.shade400,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    alignment: Alignment.center,
                                  ),
                                  Expanded(
                                    child: _buildTimeField(
                                      timeSlots[0].closingController,
                                      "Closing Time",
                                    ),
                                  ),
                                ],
                              ),
                              if (timeSlots.length == 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        timeSlots.add(TimeSlot());
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (timeSlots.length > 1)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeField(
                                        timeSlots[1].openingController,
                                        "Opening Time",
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 2,
                                      color: Colors.grey.shade400,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      alignment: Alignment.center,
                                    ),
                                    Expanded(
                                      child: _buildTimeField(
                                        timeSlots[1].closingController,
                                        "Closing Time",
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        timeSlots.removeAt(1);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AuthField(
                        hintText: "Address",
                        icon: Icons.location_on,
                        controller: addressController,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              AuthGradientButton(
                text: "Save & Continue",
                isLoading: _isLoading,
                onTap: _saveMessDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    messNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    for (var slot in timeSlots) {
      slot.openingController.dispose();
      slot.closingController.dispose();
    }
    super.dispose();
  }
}
