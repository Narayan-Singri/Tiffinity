import 'package:flutter/material.dart';
import 'package:Tiffinity/services/language_service.dart';
import 'package:Tiffinity/models/app_strings.dart';
import 'customer_support_page.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  String? _selectedCategory;
  String _searchQuery = '';

  final Map<String, List<Map<String, String>>> _faqData = {
    'Getting Started': [
      {
        'question': 'What is Tiffinity?',
        'answer':
            'Tiffinity is a tiffin (lunch box) delivery service that connects you with local mess services and home-cooked meal providers. We deliver fresh, hot meals directly to your doorstep.',
      },
      {
        'question': 'How do I create an account?',
        'answer':
            'Download the Tiffinity app, tap on "Sign Up", enter your mobile number or email, verify with OTP, and complete your profile. It\'s that simple!',
      },
      {
        'question': 'Is there a delivery charge?',
        'answer':
            'Delivery charges vary based on your location and order value. Orders above ₹500 often qualify for free delivery.',
      },
      {
        'question': 'What areas do you serve?',
        'answer':
            'We are currently operational in major cities across India. Enter your location in the app to check service availability in your area.',
      },
    ],
    'Orders & Subscriptions': [
      {
        'question': 'How do I place an order?',
        'answer':
            'Select your location, browse available mess services, choose your meal, customize if needed, add to cart, and proceed to checkout.',
      },
      {
        'question': 'Can I modify my order after placing it?',
        'answer':
            'Yes, you can modify your order within 30 minutes of placing it. Go to "My Orders", select the order, and tap "Modify Order".',
      },
      {
        'question': 'How do subscriptions work?',
        'answer':
            'Subscriptions allow you to get meals delivered regularly for a fixed period (7, 14, or 30 days). Subscribe to save time and money with daily meal delivery.',
      },
      {
        'question': 'Can I pause my subscription?',
        'answer':
            'Yes, you can pause your subscription from the "My Subscriptions" section. Pausing doesn\'t cancel it; you can resume anytime.',
      },
      {
        'question': 'What if I want to cancel my order?',
        'answer':
            'Orders can be cancelled before they are prepared. A small cancellation fee may apply if the mess has already started preparing your meal.',
      },
    ],
    'Payment & Wallet': [
      {
        'question': 'What payment methods do you accept?',
        'answer':
            'We accept all major payment methods including Credit/Debit Cards, UPI, Net Banking, and Wallet payments (Paytm, Google Pay, PhonePe).',
      },
      {
        'question': 'Is my payment information secure?',
        'answer':
            'Absolutely! All payments are encrypted and processed through secure payment gateways. We never store your card details.',
      },
      {
        'question': 'How does the Tiffinity Wallet work?',
        'answer':
            'Add money to your Tiffinity Wallet and use it for faster checkouts. You can also earn cashback and rewards that get credited to your wallet.',
      },
      {
        'question': 'What if my payment fails?',
        'answer':
            'If your payment fails, the amount will be auto-refunded to your source account within 3-5 business days. You can try placing the order again.',
      },
      {
        'question': 'Can I get a refund?',
        'answer':
            'Yes, refunds are processed for cancelled orders or if there\'s an issue with your meal. Refunds are credited to your Tiffinity Wallet or original payment method within 5-7 days.',
      },
    ],
    'Delivery': [
      {
        'question': 'How long does delivery take?',
        'answer':
            'Standard delivery takes 30-45 minutes from the time of order confirmation. Subscription meals are delivered at your chosen time slot.',
      },
      {
        'question': 'Can I track my order?',
        'answer':
            'Yes! You can track your order in real-time from the "My Orders" section. You\'ll see the delivery partner\'s location and estimated arrival time.',
      },
      {
        'question': 'What if I\'m not available during delivery?',
        'answer':
            'You can add delivery instructions like "Leave at gate" or provide an alternate contact number. For subscriptions, we can deliver to a specific location.',
      },
      {
        'question': 'Can I change my delivery address?',
        'answer':
            'Yes, you can add, edit, or delete addresses from "My Addresses" section. Make sure to select the correct address before placing an order.',
      },
      {
        'question': 'What if my food arrives cold or damaged?',
        'answer':
            'Please report the issue immediately through the app. We\'ll either send a replacement or provide a full refund.',
      },
    ],
    'Food & Menus': [
      {
        'question': 'Can I customize my meal?',
        'answer':
            'Yes, many mess services allow customization. You can choose rice/roti, add extra items, or specify preferences like less spicy.',
      },
      {
        'question': 'Do you have vegetarian and non-vegetarian options?',
        'answer':
            'Yes! You can filter mess services by Veg, Non-Veg, or Both. Each mess clearly indicates their food type.',
      },
      {
        'question': 'Are there options for special diets?',
        'answer':
            'Many of our partner mess services offer diet-specific meals like low-calorie, high-protein, Jain food, etc. Check the menu details.',
      },
      {
        'question': 'How fresh is the food?',
        'answer':
            'All meals are prepared fresh by our partner mess services. We ensure food is delivered hot and within safe time limits.',
      },
      {
        'question': 'Can I see the menu in advance?',
        'answer':
            'Yes, each mess service displays their daily/weekly menu. Subscription services often share a complete monthly menu.',
      },
    ],
    'Account & Profile': [
      {
        'question': 'How do I reset my password?',
        'answer':
            'Go to the login screen, tap "Forgot Password", enter your registered mobile/email, and follow the OTP verification process.',
      },
      {
        'question': 'How do I update my profile information?',
        'answer':
            'Go to Profile > tap on your profile details, make changes to your name, email, or phone, and save.',
      },
      {
        'question': 'Can I delete my account?',
        'answer':
            'Yes, but this action is permanent. Contact support via "Help & Support" to request account deletion.',
      },
      {
        'question': 'How do I verify my email/phone?',
        'answer':
            'Go to Profile > Contact Details, tap "Verify" next to your email or phone, and enter the OTP sent to you.',
      },
    ],
    'Offers & Rewards': [
      {
        'question': 'How do I apply a promo code?',
        'answer':
            'At checkout, look for the "Apply Coupon" section, enter your promo code, and tap "Apply". The discount will be reflected in your total.',
      },
      {
        'question': 'Where can I find active offers?',
        'answer':
            'Check the "Offers" section on the home page or look for banners while browsing mess services.',
      },
      {
        'question': 'Do referral rewards expire?',
        'answer':
            'Referral rewards are typically valid for 30 days from the date of credit. Check the terms in the "Invite Friends" section.',
      },
      {
        'question': 'Can I combine multiple offers?',
        'answer':
            'Usually, only one offer can be applied per order unless specified otherwise in the offer terms.',
      },
    ],
  };

  List<Map<String, dynamic>> get _allFAQs {
    List<Map<String, dynamic>> all = [];
    _faqData.forEach((category, questions) {
      for (var q in questions) {
        all.add({
          'category': category,
          'question': q['question']!,
          'answer': q['answer']!,
        });
      }
    });
    return all;
  }

  List<Map<String, dynamic>> get _filteredFAQs {
    if (_searchQuery.isEmpty) {
      if (_selectedCategory == null) return _allFAQs;
      return _allFAQs
          .where((faq) => faq['category'] == _selectedCategory)
          .toList();
    }

    return _allFAQs.where((faq) {
      final question = faq['question'].toString().toLowerCase();
      final answer = faq['answer'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return question.contains(query) || answer.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().currentLanguage,
      builder: (context, languageCode, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Frequently Asked Questions'),
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: const Color(0xFFF5F7F8),
          body: Column(
            children: [
              // Search Bar
              Container(
                color: const Color(0xFF00695C),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _selectedCategory = null; // Clear category when searching
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // Category Filter
              if (_searchQuery.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildCategoryChip('All', null),
                        ..._faqData.keys.map(
                          (category) => _buildCategoryChip(category, category),
                        ),
                      ],
                    ),
                  ),
                ),

              // FAQ List
              Expanded(
                child:
                    _filteredFAQs.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No FAQs found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFAQs.length,
                          itemBuilder: (context, index) {
                            final faq = _filteredFAQs[index];
                            return _buildFAQCard(
                              faq['category'],
                              faq['question'],
                              faq['answer'],
                            );
                          },
                        ),
              ),

              // Still have questions?
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Still have questions?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerSupportPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Contact Support'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(String category, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
