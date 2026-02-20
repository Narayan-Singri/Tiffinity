import 'package:flutter/material.dart';

class OtpBoxes extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const OtpBoxes({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 6,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: 10,
        color: Color(0xFF0B4F45),
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '------',
        hintStyle: TextStyle(
          letterSpacing: 10,
          color: Colors.black.withOpacity(0.25),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.teal.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.teal.shade100),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF009688), width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
