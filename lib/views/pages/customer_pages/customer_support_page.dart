import 'package:flutter/material.dart';
import 'package:Tiffinity/services/language_service.dart';
import 'package:Tiffinity/models/app_strings.dart';

class CustomerSupportPage extends StatefulWidget {
  const CustomerSupportPage({super.key});

  @override
  State<CustomerSupportPage> createState() => _CustomerSupportPageState();
}

class _CustomerSupportPageState extends State<CustomerSupportPage> {
  String? _selectedCategory;
  final List<String> _categories = [
    'General',
    'Order Issues',
    'Payment',
    'Delivery',
    'Account',
  ];

  final Map<String, List<Map<String, String>>> _supportData = {
    'General': [
      {
        'question': 'What is Tiffinity?',
        'answer':
            'Tiffinity is a tiffin (lunch box) delivery service that provides delicious meals.',
      },
      {
        'question': 'How do I create an account?',
        'answer':
            'Download the app, sign up with your email/phone, and start ordering.',
      },
    ],
    'Order Issues': [
      {
        'question': 'How can I modify my order?',
        'answer':
            'You can modify your order within 30 minutes of placing it from the My Orders section.',
      },
      {
        'question': 'Can I cancel my order?',
        'answer': 'Yes, you can cancel orders before they are prepared.',
      },
    ],
    'Payment': [
      {
        'question': 'What payment methods do you accept?',
        'answer': 'We accept Credit/Debit Cards, UPI, and Wallet payments.',
      },
      {
        'question': 'Is my payment secure?',
        'answer': 'Yes, all payments are encrypted and processed securely.',
      },
    ],
    'Delivery': [
      {
        'question': 'How long does delivery take?',
        'answer':
            'Standard delivery takes 30-45 minutes from the time of order.',
      },
      {
        'question': 'Can I track my order?',
        'answer': 'Yes, you can track your order in real-time from the app.',
      },
    ],
    'Account': [
      {
        'question': 'How do I reset my password?',
        'answer':
            'Go to login, click "Forgot Password", and follow the instructions.',
      },
      {
        'question': 'How do I update my profile?',
        'answer':
            'Go to Profile > Account Settings and update your information.',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().currentLanguage,
      builder: (context, languageCode, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Help & Support'),
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: const Color(0xFFF5F7F8),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Contact',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildContactRow(Icons.phone, 'Phone', '+91 9876543210'),
                      const SizedBox(height: 10),
                      _buildContactRow(
                        Icons.email_outlined,
                        'Email',
                        'support@tiffinity.com',
                      ),
                      const SizedBox(height: 10),
                      _buildContactRow(
                        Icons.access_time,
                        'Hours',
                        '9:00 AM - 10:00 PM',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // FAQ Categories
                const Text(
                  'FAQs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.teal : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.teal,
                                  width: isSelected ? 0 : 1,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected ? Colors.white : Colors.teal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // FAQ Items
                if (_selectedCategory != null)
                  ..._supportData[_selectedCategory]!.map(
                    (faq) => _buildFAQItem(faq['question']!, faq['answer']!),
                  ),

                const SizedBox(height: 24),

                // Contact Support Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showContactDialog(context),
                    icon: const Icon(Icons.send),
                    label: const Text('Send us a Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Live Chat Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showChatDialog(context),
                    icon: const Icon(Icons.chat),
                    label: const Text('Start Live Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        final messageController = TextEditingController();

        return AlertDialog(
          title: const Text('Send us a Message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Your Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Your Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Your Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message sent successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Live Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_outlined, size: 48, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'A support agent will be with you shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
