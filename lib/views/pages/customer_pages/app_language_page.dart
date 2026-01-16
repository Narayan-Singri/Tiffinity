import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Tiffinity/services/language_service.dart';
import 'package:Tiffinity/models/app_strings.dart';

class AppLanguagePage extends StatefulWidget {
  const AppLanguagePage({super.key});

  @override
  State<AppLanguagePage> createState() => _AppLanguagePageState();
}

class _AppLanguagePageState extends State<AppLanguagePage> {
  String _selectedLanguage = 'English';
  bool _isLoading = true;

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'हिंदी', 'code': 'hi'},
    {'name': 'ગુજરાતી', 'code': 'gu'},
    {'name': 'मराठी', 'code': 'mr'},
    {'name': 'తెలుగు', 'code': 'te'},
    {'name': 'தமிழ்', 'code': 'ta'},
    {'name': 'ಕನ್ನಡ', 'code': 'kn'},
    {'name': 'മലയാളം', 'code': 'ml'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('app_language') ?? 'English';
      setState(() {
        _selectedLanguage = language;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLanguage(String language) async {
    try {
      setState(() => _selectedLanguage = language);
      
      final languageService = LanguageService();
      await languageService.setLanguage(language);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to $language'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().currentLanguage,
      builder: (context, languageCode, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.getString('app_language', languageCode)),
            backgroundColor: const Color.fromARGB(255, 27, 84, 78),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: const Color(0xFFF5F7F8),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 16),
                        child: Text(
                          AppStrings.getString('select_language', languageCode),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D3142),
                              ),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _languages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final language = _languages[index];
                          final isSelected =
                              _selectedLanguage == language['name'];

                          return _buildLanguageCard(
                            language: language['name']!,
                            isSelected: isSelected,
                            onTap: () => _saveLanguage(language['name']!),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.teal.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.getString('language_info', languageCode),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLanguageCard({
    required String language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.teal
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Language Icon/Circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.teal.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.language,
                color: isSelected ? Colors.teal : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Language Name
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3142),
                ),
              ),
            ),
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.teal
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected
                    ? Colors.teal
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
