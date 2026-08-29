import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoadingData = true;
  bool _isSubmitting = false;

  List<dynamic> _categories = [];
  List<dynamic> _priorities = [];
  List<dynamic> _projects = [];

  int? _selectedCategoryId;
  int? _selectedPriorityId;
  int? _selectedProjectId;

  List<PlatformFile> _selectedFiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });

    try {
      final catRes = await ApiService.get('/categories');
      final prioRes = await ApiService.get('/priorities');
      final projRes = await ApiService.get('/projects');

      setState(() {
        _categories = catRes['data'] as List? ?? [];
        _priorities = prioRes['data'] as List? ?? [];
        _projects = projRes['data'] as List? ?? [];
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement des formulaires: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur sélection fichier: $e')),
      );
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fields = {
        'titre': _titreController.text.trim(),
        'message': _messageController.text.trim(),
        'priority_id': _selectedPriorityId.toString(),
        'ticket_priority_id': _selectedPriorityId.toString(),
        'category_id': _selectedCategoryId.toString(),
        'project_id': _selectedProjectId.toString(),
      };

      final res = _selectedFiles.isNotEmpty
          ? await ApiService.postMultipart('/tickets', fields, _selectedFiles)
          : await ApiService.post('/tickets', fields);

      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket créé avec succès !')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Erreur lors de la création du ticket.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLabel(String labelText, bool isRequired, bool isDark) {
    return RichText(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Ticket'),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, style: const TextStyle(color: AppTheme.danger), textAlign: TextAlign.center),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Sujet / Titre Field (Required)
                          _buildLabel('Sujet / Titre du ticket', true, isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titreController,
                            style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                            decoration: const InputDecoration(
                              hintText: 'ex: Problème d\'accès au tableau de bord',
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Le sujet est obligatoire.' : null,
                          ),
                          const SizedBox(height: 16),

                          // 2. Priorité Dropdown (Required with disabled initial item for validation test)
                          _buildLabel('Priorité', true, isDark),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int?>(
                            value: _selectedPriorityId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                            dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                enabled: false,
                                child: Text('Sélectionnez une priorité...', style: TextStyle(color: Colors.grey)),
                              ),
                              ..._priorities.map((item) {
                                return DropdownMenuItem<int?>(
                                  value: item['id'] as int,
                                  child: Text(item['nom'] ?? 'Priorité'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedPriorityId = val;
                              });
                            },
                            validator: (val) => val == null ? 'La priorité est obligatoire.' : null,
                          ),
                          const SizedBox(height: 16),

                          // 3. Catégorie Dropdown (Required with disabled initial item)
                          _buildLabel('Catégorie', true, isDark),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int?>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                            dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                enabled: false,
                                child: Text('Sélectionnez une catégorie...', style: TextStyle(color: Colors.grey)),
                              ),
                              ..._categories.map((item) {
                                return DropdownMenuItem<int?>(
                                  value: item['id'] as int,
                                  child: Text(item['nom'] ?? 'Catégorie'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                            validator: (val) => val == null ? 'La catégorie est obligatoire.' : null,
                          ),
                          const SizedBox(height: 16),

                          // 4. Projet Dropdown (Required with disabled initial item)
                          _buildLabel('Projet', true, isDark),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int?>(
                            value: _selectedProjectId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                            dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                enabled: false,
                                child: Text('Sélectionnez un projet...', style: TextStyle(color: Colors.grey)),
                              ),
                              ..._projects.map((item) {
                                return DropdownMenuItem<int?>(
                                  value: item['id'] as int,
                                  child: Text(item['nom'] ?? 'Projet'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedProjectId = val;
                              });
                            },
                            validator: (val) => val == null ? 'Le projet est obligatoire.' : null,
                          ),
                          const SizedBox(height: 16),

                          // 5. Message / Description Field (Required)
                          _buildLabel('Message / Description', true, isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                            decoration: const InputDecoration(
                              hintText: 'Décrivez votre demande ou problème avec précision...',
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Le message est obligatoire.' : null,
                          ),
                          const SizedBox(height: 18),

                          // 6. Pièce(s) jointe(s) (Optional File Picker)
                          _buildLabel('Pièce(s) jointe(s)', false, isDark),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickFiles,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.cloud_upload_outlined, color: AppTheme.primary),
                                  SizedBox(width: 8),
                                  Text('Joindre un fichier', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedFiles.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedFiles.map((f) {
                                return Chip(
                                  avatar: const Icon(Icons.attach_file, size: 16),
                                  label: Text(f.name, style: const TextStyle(fontSize: 11)),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedFiles.remove(f);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                              onPressed: _isSubmitting ? null : _submitTicket,
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Créer le ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}