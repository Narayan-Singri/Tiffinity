import 'package:flutter/material.dart';

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.dropdownItems,
    this.dropdownValue,
    this.onDropdownChanged,
    this.keyboardType, // ✅ ADDED
    this.maxLength, // ✅ ADDED
  });

  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  // Dropdown support
  final List<String>? dropdownItems;
  final String? dropdownValue;
  final void Function(String?)? onDropdownChanged;

  // ✅ NEW PARAMETERS
  final TextInputType? keyboardType;
  final int? maxLength;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dropdownItems != null && widget.dropdownItems!.isNotEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(27.0),
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(width: 3.0),
          ),
          prefixIcon: Icon(widget.icon),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.dropdownValue,
            isDense: true,
            onChanged: widget.onDropdownChanged,
            items:
                widget.dropdownItems!
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            dropdownColor: Colors.white,
            menuMaxHeight: 200,
          ),
        ),
      );
    }

    // 🔹 TextField Mode
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType, // ✅ ADDED
      maxLength: widget.maxLength, // ✅ ADDED
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(27.0),
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(width: 3.0),
        ),
        prefixIcon: Icon(widget.icon),
        counterText: widget.maxLength != null ? '' : null, // Hide counter
        suffixIcon:
            widget.isPassword
                ? IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                )
                : null,
      ),
    );
  }
}
