import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../tickets/ticket_detail_screen.dart';
import '../tickets/ticket_list_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'last3months';
  String? _selectedAgentId;
  DateTimeRange? _customDateRange;
  Map<String, dynamic> _statsData = {};
  List<dynamic> _agentsList = [];

  final List<Map<String, String>> _periods = [
    {'value': 'today', 'label': 'Aujourd\'hui'},
    {'value': 'yesterday', 'label': 'Hier'},
    {'value': 'last7', 'label': 'Les 7 derniers jours'},
    {'value': 'last30', 'label': 'Les 30 derniers jours'},
    {'value': 'last3months', 'label': 'Les 3 derniers mois'},
    {'value': 'lastyear', 'label': 'L\'année dernière'},
    {'value': 'custom', 'label': 'Personnalisé'},
  ];

  static const List<Color> _projectPalette = [
    Color(0xFF7367F0),
    Color(0xFF00BAD1),
    Color(0xFFFF9F43),
    Color(0xFF28C76F),
    Color(0xFFEA5455),
    Color(0xFF826AF9),
    Color(0xFF4F8CF6),
  ];

  @override
  void initState() {
    super.initState();
    _fetchAgentsList();
    _fetchManagerDashboardData();
  }

  Future<void> _fetchAgentsList() async {
    try {
      final res = await ApiService.get('/agents');
      if (mounted) {
        setState(() {
          _agentsList = res['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'custom';
      });
      _fetchManagerDashboardData();
    }
  }

  Future<void> _fetchManagerDashboardData() async {
    setState(() => _isLoading = true);
    try {
      String url = '/dashboard/stats?filter=$_selectedPeriod';
      if (_selectedAgentId != null && _selectedAgentId!.isNotEmpty) {
        url += '&agent=$_selectedAgentId';
      }
      if (_selectedPeriod == 'custom' && _customDateRange != null) {
        final start = _customDateRange!.start.toIso8601String().split('T').first;
        final end = _customDateRange!.end.toIso8601String().split('T').first;
        url += '&start_date=$start&end_date=$end';
      }

      final statsRes = await ApiService.get(url);
      if (mounted) {
        setState(() {
          _statsData = statsRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getCategoryColor(int index, String? hexStr, [String? name]) {
    final lowerName = (name ?? '').toLowerCase();
    if (lowerName.contains('question')) return const Color(0xFF828393);
    if (lowerName.contains('incident')) return const Color(0xFFFFB054);
    if (lowerName.contains('probl')) return const Color(0xFFFF5B5C);
    if (lowerName.contains('fonctionnalit')) return const Color(0xFF826AF9);
    if (lowerName.contains('modification')) return const Color(0xFF4F8CF6);

    if (hexStr != null && hexStr.isNotEmpty) {
      final clean = hexStr.toLowerCase().replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse("FF$clean", radix: 16));
      }
    }
    const categoryPalette = [
      Color(0xFF828393),
      Color(0xFFFFB054),
      Color(0xFFFF5B5C),
      Color(0xFF826AF9),
      Color(0xFF4F8CF6),
      Color(0xFF00BAD1),
      Color(0xFF28C76F),
    ];
    return categoryPalette[index % categoryPalette.length];
  }

  Color _getPriorityColor(String name) {
    switch (name.toLowerCase()) {
      case 'faible':
      case 'low':
        return const Color(0xFF808390);
      case 'moyen':
      case 'medium':
        return const Color(0xFF00BAD1);
      case 'haut':
      case 'high':
        return const Color(0xFFFF9F43);
      case 'urgent':
        return const Color(0xFFFF5B5C);
      default:
        return AppTheme.primary;
    }
  }

  Color _getStatusColor(String status) {
    return AppTheme.getStatusColor(status);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final nouveau = _statsData['nouveau'] ?? 0;
    final encours = _statsData['encours'] ?? 0;
    final enattente = _statsData['enattente'] ?? 0;
    final resolus = _statsData['resolus'] ?? 0;
    final fermes = _statsData['fermes'] ?? 0;
    final projectsActifs = _statsData['projects_actifs'] ?? 0;
    final agentsActifs = _statsData['agents_actifs'] ?? 0;
    final usersCount = _statsData['users_count'] ?? 0;
    final unassigned = _statsData['unassigned'] ?? 0;

    final priorities = (_statsData['priorities'] as List<dynamic>?) ?? [];
    final categories = (_statsData['categories'] as List<dynamic>?) ?? [];
    final projects = (_statsData['projects'] as List<dynamic>?) ?? [];
    final evolution = (_statsData['evolution'] as Map<dynamic, dynamic>?) ?? {};
    final lastTickets = (_statsData['last_tickets'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tableau de bord Manager', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Vue globale & statistiques', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchManagerDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchManagerDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dual Filters Row (Agent Select + Period Select)
                    Row(
                      children: [
                        // Agent Select Filter
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedAgentId,
                                isExpanded: true,
                                dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF2B2C40)),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Tous les agents', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  ..._agentsList.map((agent) {
                                    final name = '${agent['prenom'] ?? agent['first_name'] ?? ''} ${agent['nom'] ?? agent['last_name'] ?? ''}'.trim();
                                    return DropdownMenuItem<String?>(
                                      value: agent['id'].toString(),
                                      child: Text(name.isNotEmpty ? name : 'Agent', maxLines: 1, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedAgentId = val);
                                  _fetchManagerDashboardData();
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Period Select Filter
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPeriod,
                                isExpanded: true,
                                dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF2B2C40)),
                                items: _periods.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p['value'],
                                    child: Text(p['label']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val == 'custom') {
                                    _selectCustomDateRange();
                                  } else if (val != null) {
                                    setState(() => _selectedPeriod = val);
                                    _fetchManagerDashboardData();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Unassigned Alert Box
                    if (unassigned > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFEEBA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$unassigned ticket(s) sans agent assigné sur la période sélectionnée.',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 8 Manager Cards Grid
                    Row(
                      children: [
                        Expanded(child: _buildManagerCard('Tickets Nouveaux', '$nouveau', const Color(0xFF00BAD1), Icons.mail_outline, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildManagerCard('Tickets en cours', '$encours', const Color(0xFF7367F0), Icons.autorenew, isDark)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildManagerCard('Tickets en attente', '$enattente', const Color(0xFFFF9F43), Icons.access_time, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildManagerCard('Tickets Résolus', '$resolus', const Color(0xFF28C76F), Icons.check_circle_outline, isDark)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildManagerCard('Tickets Fermés', '$fermes', const Color(0xFFFF5B5C), Icons.block, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildManagerCard('Projets actifs', '$projectsActifs', const Color(0xFF2B2C40), Icons.folder_outlined, isDark)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildManagerCard('Agents actifs', '$agentsActifs', const Color(0xFF00BAD1), Icons.people_outline, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildManagerCard('Utilisateurs', '$usersCount', const Color(0xFF828393), Icons.person_outline, isDark)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Graph 1: Évolution des tickets
                    _buildEvolutionChartCard(evolution, isDark),
                    const SizedBox(height: 16),

                    // Graph 2: Tickets par Priorité (Donut)
                    _buildPriorityDonutCard(priorities, isDark),
                    const SizedBox(height: 16),

                    // Graph 3: Tickets par Projet (CIRCULAR DONUT)
                    _buildProjectDonutCard('Tickets par Projet', projects, isDark),
                    const SizedBox(height: 16),

                    // Graph 4: Tickets par Catégorie
                    _buildCategoryBarCard('Tickets par Catégorie', categories, isDark),
                    const SizedBox(height: 20),

                    // List of Derniers Tickets
                    _buildLastTicketsCard(lastTickets, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildManagerCard(String title, String count, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2B2C40))),
                Text(title, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFF5E5873)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChartCard(Map<dynamic, dynamic> evolution, bool isDark) {
    final labels = (evolution['labels'] as List<dynamic>?) ?? [];
    final counts = (evolution['counts'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Évolution des tickets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF5E5873))),
          const SizedBox(height: 14),
          if (labels.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucune donnée d\'évolution.')))
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(labels.length, (i) {
                  final val = ((counts[i] ?? 0) as num).toInt();
                  final maxVal = (counts.reduce((a, b) => (a as num) > (b as num) ? a : b) as num).toInt();
                  final ratio = maxVal > 0 ? (val / maxVal).clamp(0.1, 1.0) : 0.1;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$val', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 85 * ratio,
                          width: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i].toString().split(' ').first,
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriorityDonutCard(List<dynamic> items, bool isDark) {
    int totalCount = 0;
    for (var item in items) {
      totalCount += ((item['count'] ?? 0) as num).toInt();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tickets par Priorité', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF5E5873))),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(150, 150),
                    painter: _PriorityDonutPainter(items: items, totalCount: totalCount, getPriorityColor: _getPriorityColor),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                      Text('$totalCount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2B2C40))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: items.map((item) {
                final name = (item['name'] ?? '').toString();
                final count = ((item['count'] ?? 0) as num).toInt();
                final color = _getPriorityColor(name);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$name: $count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2B2C40))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // CIRCULAR DONUT CHART FOR TICKETS PAR PROJET
  Widget _buildProjectDonutCard(String title, List<dynamic> items, bool isDark) {
    int totalCount = 0;
    for (var item in items) {
      totalCount += ((item['count'] ?? 0) as num).toInt();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF5E5873))),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucune donnée de projet.')))
          else ...[
            Center(
              child: SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(150, 150),
                      painter: _ProjectDonutPainter(items: items, totalCount: totalCount, palette: _projectPalette),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                        Text('$totalCount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2B2C40))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final name = (item['name'] ?? 'Projet').toString();
                  final count = ((item['count'] ?? 0) as num).toInt();
                  final color = _projectPalette[idx % _projectPalette.length];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('$name: $count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2B2C40))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBarCard(String title, List<dynamic> items, bool isDark) {
    int maxVal = 1;
    for (var item in items) {
      final val = ((item['count'] ?? 0) as num).toInt();
      if (val > maxVal) maxVal = val;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF5E5873))),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final name = (item['name'] ?? '').toString();
            final count = ((item['count'] ?? 0) as num).toInt();
            final color = _getCategoryColor(idx, item['color'], name);
            final ratio = maxVal > 0 ? (count / maxVal).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2B2C40))),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final barWidth = count == 0 ? 26.0 : (totalWidth * ratio).clamp(26.0, totalWidth);
                      return Container(
                        height: 22,
                        width: barWidth,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLastTicketsCard(List<dynamic> tickets, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Derniers tickets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF5E5873))),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketListScreen()));
                },
                child: const Text('Voir tout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tickets.isEmpty)
            const Text('Aucun ticket récent.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...tickets.map((t) {
              final ref = t['reference'] ?? 'TKT';
              final title = t['sujet'] ?? t['title'] ?? 'Ticket';
              final status = (t['statut'] ?? 'Nouveau').toString();
              final statusColor = _getStatusColor(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () {
                    if (t['id'] != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: t['id'])));
                    }
                  },
                  title: Text('$ref - $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _PriorityDonutPainter extends CustomPainter {
  final List<dynamic> items;
  final int totalCount;
  final Color Function(String) getPriorityColor;

  _PriorityDonutPainter({required this.items, required this.totalCount, required this.getPriorityColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);
    if (totalCount == 0) return;

    double startAngle = -pi / 2;
    for (var item in items) {
      final name = (item['name'] ?? '').toString();
      final count = ((item['count'] ?? 0) as num).toInt();
      if (count == 0) continue;

      final sweepAngle = (count / totalCount) * 2 * pi;
      final arcPaint = Paint()
        ..color = getPriorityColor(name)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle - 0.04, false, arcPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ProjectDonutPainter extends CustomPainter {
  final List<dynamic> items;
  final int totalCount;
  final List<Color> palette;

  _ProjectDonutPainter({required this.items, required this.totalCount, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);
    if (totalCount == 0) return;

    double startAngle = -pi / 2;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final count = ((item['count'] ?? 0) as num).toInt();
      if (count == 0) continue;

      final sweepAngle = (count / totalCount) * 2 * pi;
      final color = palette[i % palette.length];
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle - 0.04, false, arcPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}