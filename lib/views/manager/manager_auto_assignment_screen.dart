import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ManagerAutoAssignmentScreen extends StatefulWidget {
  const ManagerAutoAssignmentScreen({super.key});

  @override
  State<ManagerAutoAssignmentScreen> createState() => _ManagerAutoAssignmentScreenState();
}

class _ManagerAutoAssignmentScreenState extends State<ManagerAutoAssignmentScreen> {
  bool _isLoading = true;
  List<dynamic> _rules = [];
  List<dynamic> _projects = [];
  List<dynamic> _agents = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final rulesRes = await ApiService.get('/manager/auto-assignment');
      final projectsRes = await ApiService.get('/projects');
      final agentsRes = await ApiService.get('/agents');

      if (mounted) {
        setState(() {
          _rules = rulesRes['data'] ?? [];
          _projects = projectsRes['data'] ?? [];
          _agents = agentsRes['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _toggleRule(int id) async {
    try {
      final res = await ApiService.post('/manager/auto-assignment/$id/toggle', {});
      if (res['success'] == true && mounted) {
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteRule(int id) async {
    try {
      final res = await ApiService.delete('/manager/auto-assignment/$id');
      if (res['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Règle supprimée.')),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildRequiredLabel(String text, bool isDark) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog() {
    int? selectedProjectId;
    int? selectedAgentId;
    final formKey = GlobalKey<FormState>();
    AutovalidateMode autoValidateMode = AutovalidateMode.disabled;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          title: const Text('Nouvelle Règle d\'Assignation'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: autoValidateMode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequiredLabel('Projet', isDark),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: selectedProjectId,
                    hint: const Text('Sélectionner un projet'),
                    isExpanded: true,
                    items: _projects.map((p) {
                      final id = p['id'] as int;
                      final name = (p['nom'] ?? p['name'] ?? 'Projet').toString();
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedProjectId = val),
                    validator: (val) => val == null ? 'Veuillez sélectionner un projet.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildRequiredLabel('Agent', isDark),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: selectedAgentId,
                    hint: const Text('Sélectionner un agent'),
                    isExpanded: true,
                    items: _agents.map((a) {
                      final id = a['id'] as int;
                      final name = '${a['prenom'] ?? a['first_name'] ?? ''} ${a['nom'] ?? a['last_name'] ?? ''}'.trim();
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(name.isNotEmpty ? name : 'Agent', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedAgentId = val),
                    validator: (val) => val == null ? 'Veuillez sélectionner un agent.' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                setDialogState(() {
                  autoValidateMode = AutovalidateMode.onUserInteraction;
                });
                if (formKey.currentState!.validate()) {
                  try {
                    final res = await ApiService.post('/manager/auto-assignment', {
                      'project_id': selectedProjectId,
                      'agent_id': selectedAgentId,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Règle créée avec succès !')));
                        _fetchData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Erreur lors de l\'ajout.')));
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                    }
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attribution Automatique'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_mode_outlined, size: 54, color: AppTheme.primary),
                      const SizedBox(height: 12),
                      Text('Aucune règle d\'attribution automatique.', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddRuleDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une règle'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rules.length,
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      final project = rule['project'] ?? {};
                      final agent = rule['agent'] ?? {};
                      final isActif = rule['actif'] == true || rule['actif'] == 1;

                      final projName = project['nom'] ?? project['name'] ?? 'Tous les projets';
                      final agentName = '${agent['prenom'] ?? agent['first_name'] ?? ''} ${agent['nom'] ?? agent['last_name'] ?? ''}'.trim();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.flash_on, color: AppTheme.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Projet: $projName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('Agent: ${agentName.isNotEmpty ? agentName : "Agent"}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isActif,
                                activeColor: AppTheme.primary,
                                onChanged: (_) => _toggleRule(rule['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _deleteRule(rule['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddRuleDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}