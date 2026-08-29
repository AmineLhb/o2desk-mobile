import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  bool _isLoading = true;
  List<dynamic> _faqCategories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.get('/faqs');
      if (res['success'] == true || res['data'] != null) {
        final rawList = res['data'] as List? ?? [];
        // Filter out categories with no questions
        final filteredList = rawList.where((cat) {
          final faqs = cat['faqs'] as List? ?? [];
          return faqs.isNotEmpty;
        }).toList();

        setState(() {
          _faqCategories = filteredList;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Erreur lors du chargement de la FAQ.';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchFaqs,
          color: AppTheme.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.danger), textAlign: TextAlign.center),
                      ),
                    )
                  : _faqCategories.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('Aucune FAQ disponible pour le moment.', style: TextStyle(color: AppTheme.secondary))),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _faqCategories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final cat = _faqCategories[index];
                            final catTitle = cat['nom'] ?? cat['title'] ?? cat['name'] ?? 'Catégorie #${index + 1}';
                            final faqs = cat['faqs'] as List? ?? [];

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: ExpansionTile(
                                leading: const Icon(Icons.help_outline, color: AppTheme.primary),
                                title: Text(
                                  catTitle,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                                ),
                                children: faqs.map<Widget>((faq) {
                                  final question = faq['question'] ?? faq['titre'] ?? 'Question';
                                  final response = faq['response'] ?? faq['reponse'] ?? 'Aucune réponse disponible.';

                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 0.5)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.primary)),
                                        const SizedBox(height: 6),
                                        Text(response, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}