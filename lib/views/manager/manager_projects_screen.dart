import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ManagerProjectsScreen extends StatefulWidget {
  const ManagerProjectsScreen({super.key});

  @override
  State<ManagerProjectsScreen> createState() => _ManagerProjectsScreenState();
}

class _ManagerProjectsScreenState extends State<ManagerProjectsScreen> {
  bool _isLoading = true;
  List<dynamic> _projects = [];
  List<dynamic> _agents = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    _fetchAgents();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/projects');
      if (mounted) {
        setState(() {
          _projects = res['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAgents() async {
    try {
      final res = await ApiService.get('/agents');
      if (mounted) {
        setState(() {
          _agents = res['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  void _showProjectFormDialog([dynamic project]) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: project != null ? (project['nom'] ?? project['name'] ?? '') : '');
    final descController = TextEditingController(text: project != null ? (project['description'] ?? '') : '');
    String statusValue = project != null ? (project['statut'] ?? 'Actif') : 'Actif';

    List<int> selectedUserIds = [];
    if (project != null && project['users'] != null && project['users'] is List) {
      selectedUserIds = (project['users'] as List).map((u) => (u['id'] as num).toInt()).toList();
    }

    bool isSaving = false;
    AutovalidateMode autoValidateMode = AutovalidateMode.disabled;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          title: Text(project == null ? 'Ajouter un Projet' : 'Modifier un Projet'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: autoValidateMode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du projet *
                  Row(
                    children: [
                      Text('Nom du projet ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Refonte site web',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                    validator: (val) {
                      final text = val?.trim() ?? '';
                      if (text.isEmpty) return 'Veuillez saisir le nom du projet.';
                      if (text.length < 2) return 'Le nom doit contenir au moins 2 caractères.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Décrivez le projet...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Statut *
                  Row(
                    children: [
                      Text('Statut ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: ['Actif', 'En pause', 'Terminé', 'Annulé'].contains(statusValue) ? statusValue : 'Actif',
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Actif', child: Text('Actif')),
                      DropdownMenuItem(value: 'En pause', child: Text('En pause')),
                      DropdownMenuItem(value: 'Terminé', child: Text('Terminé')),
                      DropdownMenuItem(value: 'Annulé', child: Text('Annulé')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => statusValue = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Utilisateurs / Agents associés (Multi-Select)
                  Text('Utilisateurs / Agents associés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        selectedUserIds.isEmpty
                            ? 'Sélectionner des utilisateurs (${_agents.length} dispo)'
                            : '${selectedUserIds.length} utilisateur(s) sélectionné(s)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      leading: const Icon(Icons.people_outline, color: AppTheme.primary),
                      children: _agents.map((agent) {
                        final agentId = (agent['id'] as num).toInt();
                        final name = '${agent['prenom'] ?? agent['first_name'] ?? ''} ${agent['nom'] ?? agent['last_name'] ?? ''}'.trim();
                        final isSelected = selectedUserIds.contains(agentId);

                        return CheckboxListTile(
                          value: isSelected,
                          dense: true,
                          title: Text(name.isNotEmpty ? name : 'Agent #$agentId', style: const TextStyle(fontSize: 12)),
                          subtitle: Text(agent['email'] ?? '', style: const TextStyle(fontSize: 10)),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedUserIds.add(agentId);
                              } else {
                                selectedUserIds.remove(agentId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedUserIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedUserIds.map((id) {
                        final matched = _agents.firstWhere((a) => (a['id'] as num).toInt() == id, orElse: () => null);
                        final name = matched != null ? '${matched['prenom'] ?? matched['first_name'] ?? ''} ${matched['nom'] ?? matched['last_name'] ?? ''}'.trim() : 'ID #$id';
                        return Chip(
                          label: Text(name, style: const TextStyle(fontSize: 10)),
                          onDeleted: () {
                            setDialogState(() {
                              selectedUserIds.remove(id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => autoValidateMode = AutovalidateMode.onUserInteraction);
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        final body = {
                          'nom': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'statut': statusValue,
                          'users': selectedUserIds,
                        };
                        final res = project == null
                            ? await ApiService.post('/projects', body)
                            : await ApiService.put('/projects/${project['id']}', body);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Projet enregistré !')),
                          );
                          _fetchProjects();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProject(dynamic project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le projet'),
        content: Text('Voulez-vous vraiment supprimer le projet "${project['nom'] ?? project['name']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              try {
                final res = await ApiService.delete('/projects/${project['id']}');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'Projet supprimé !')),
                  );
                  _fetchProjects();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final filteredProjects = _projects.where((proj) {
      final name = (proj['nom'] ?? proj['name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Projets'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchProjects),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher un projet...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProjects.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun projet trouvé.',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchProjects,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredProjects.length,
                          itemBuilder: (context, index) {
                            final proj = filteredProjects[index];
                            final name = proj['nom'] ?? proj['name'] ?? 'Projet';
                            final status = proj['statut'] ?? 'Actif';

                            Color statusColor = const Color(0xFF00BAD1);
                            if (status == 'En pause') statusColor = const Color(0xFFFF9F43);
                            if (status == 'Terminé') statusColor = const Color(0xFF28C76F);
                            if (status == 'Annulé') statusColor = const Color(0xFFEA5455);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.folder_outlined, color: statusColor),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Statut: $status', style: const TextStyle(fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                                      onPressed: () => _showProjectFormDialog(proj),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                                      onPressed: () => _deleteProject(proj),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showProjectFormDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}