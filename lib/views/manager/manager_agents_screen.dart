import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ManagerAgentsScreen extends StatefulWidget {
  const ManagerAgentsScreen({super.key});

  @override
  State<ManagerAgentsScreen> createState() => _ManagerAgentsScreenState();
}

class _ManagerAgentsScreenState extends State<ManagerAgentsScreen> {
  bool _isLoading = true;
  List<dynamic> _agents = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/agents');
      if (mounted) {
        setState(() {
          _agents = res['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAgentFormDialog([dynamic agent]) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController(text: agent != null ? (agent['first_name'] ?? agent['prenom'] ?? '') : '');
    final lastNameCtrl = TextEditingController(text: agent != null ? (agent['last_name'] ?? agent['nom'] ?? '') : '');
    final emailCtrl = TextEditingController(text: agent != null ? (agent['email'] ?? '') : '');
    final phoneCtrl = TextEditingController(text: agent != null ? (agent['phone'] ?? '') : '');
    bool isSaving = false;
    AutovalidateMode autoValidateMode = AutovalidateMode.disabled;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          title: Text(agent == null ? 'Ajouter un Agent' : 'Modifier l\'Agent'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: autoValidateMode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Prénom ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: firstNameCtrl,
                    decoration: const InputDecoration(hintText: 'Prénom de l\'agent', prefixIcon: Icon(Icons.person_outline)),
                    validator: (val) {
                      final text = val?.trim() ?? '';
                      if (text.isEmpty) return 'Le prénom est obligatoire.';
                      if (text.length < 2) return 'Au moins 2 caractères.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Nom ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: lastNameCtrl,
                    decoration: const InputDecoration(hintText: 'Nom de l\'agent', prefixIcon: Icon(Icons.person_outline)),
                    validator: (val) {
                      final text = val?.trim() ?? '';
                      if (text.isEmpty) return 'Le nom est obligatoire.';
                      if (text.length < 2) return 'Au moins 2 caractères.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Email ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'exemple@domaine.com', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (val) {
                      final text = val?.trim() ?? '';
                      if (text.isEmpty) return 'L\'email est obligatoire.';
                      if (!text.contains('@') || !text.contains('.')) return 'Adresse email invalide.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Téléphone ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '+212 600000000', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (val) {
                      final text = val?.trim() ?? '';
                      if (text.isEmpty) return 'Le téléphone est obligatoire.';
                      if (text.length < 8) return 'Numéro de téléphone invalide.';
                      return null;
                    },
                  ),
                  if (agent == null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Un e-mail d\'activation sera envoyé à l\'agent pour créer son mot de passe.',
                              style: TextStyle(fontSize: 11, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => autoValidateMode = AutovalidateMode.onUserInteraction);
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isSaving = true);
                      try {
                        final body = {
                          'first_name': firstNameCtrl.text.trim(),
                          'last_name': lastNameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                        };
                        final res = agent == null
                            ? await ApiService.post('/agents', body)
                            : await ApiService.post('/agents/${agent['id']}', body);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Agent enregistré !')),
                          );
                          _fetchAgents();
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

  void _viewAgentDetails(dynamic agent) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final name = '${agent['prenom'] ?? agent['first_name'] ?? ''} ${agent['nom'] ?? agent['last_name'] ?? ''}'.trim();
    final email = agent['email'] ?? '';
    final phone = agent['phone'] ?? 'Non spécifié';
    final activeCount = agent['active_tickets_count'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isNotEmpty ? name : 'Agent', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Téléphone: $phone', style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tickets Actifs:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeCount > 0 ? AppTheme.primary : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$activeCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAgentFormDialog(agent);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier l\'agent'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final filteredAgents = _agents.where((agent) {
      final name = '${agent['prenom'] ?? agent['first_name'] ?? ''} ${agent['nom'] ?? agent['last_name'] ?? ''}'.toLowerCase();
      final email = (agent['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Agents'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAgents),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher un agent...',
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
                : filteredAgents.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun agent trouvé.',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchAgents,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredAgents.length,
                          itemBuilder: (context, index) {
                            final agent = filteredAgents[index];
                            final name = '${agent['prenom'] ?? agent['first_name'] ?? ''} ${agent['nom'] ?? agent['last_name'] ?? ''}'.trim();
                            final email = agent['email'] ?? '';
                            final activeCount = agent['active_tickets_count'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _viewAgentDetails(agent),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                ),
                                title: Text(name.isNotEmpty ? name : 'Agent', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: activeCount > 0 ? AppTheme.primary.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$activeCount tks',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: activeCount > 0 ? AppTheme.primary : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                                      onPressed: () => _showAgentFormDialog(agent),
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
        onPressed: () => _showAgentFormDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}