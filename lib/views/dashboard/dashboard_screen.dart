import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'lastyear';
  DateTimeRange? _customDateRange;

  Map<String, dynamic>? _ticketCounts;
  List<dynamic> _categoriesChart = [];
  List<dynamic> _prioritiesChart = [];
  List<dynamic> _statutsChart = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String endpoint = '/dashboard/stats?filter=$_selectedFilter';
      if (_selectedFilter == 'custom' && _customDateRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(_customDateRange!.start);
        final end = DateFormat('yyyy-MM-dd').format(_customDateRange!.end);
        endpoint += '&start_date=$start&end_date=$end';
      }

      final res = await ApiService.get(endpoint);

      if (res['success'] == true || res['data'] != null || res['nouveau'] != null) {
        final data = res['data'] is Map<String, dynamic> ? res['data'] : res;

        final countsMap = (data['counts'] ?? data['stats']) as Map<String, dynamic>? ?? {
          'nouveau': data['nouveau'] ?? 0,
          'en_cours': data['encours'] ?? data['en_cours'] ?? 0,
          'en_attente': data['enattente'] ?? data['en_attente'] ?? 0,
          'resolu': data['resolus'] ?? data['resolu'] ?? 0,
          'ferme': data['fermes'] ?? data['ferme'] ?? 0,
        };

        final categoriesList = (data['categories'] as List?) ?? [];
        final prioritiesList = (data['priorities'] as List?) ?? [];

        final statutsList = (data['statuts'] as List?) ?? [
          {'name': 'Nouveau', 'count': countsMap['nouveau'] ?? 0, 'color': '#00BAD1'},
          {'name': 'En cours', 'count': countsMap['en_cours'] ?? 0, 'color': '#7367F0'},
          {'name': 'En attente', 'count': countsMap['en_attente'] ?? 0, 'color': '#FF9F43'},
          {'name': 'Résolu', 'count': countsMap['resolu'] ?? 0, 'color': '#28C76F'},
          {'name': 'Fermé', 'count': countsMap['ferme'] ?? 0, 'color': '#EA5455'},
        ];

        setState(() {
          _ticketCounts = countsMap;
          _categoriesChart = categoriesList;
          _prioritiesChart = prioritiesList;
          _statutsChart = statutsList;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Erreur de chargement du tableau de bord.';
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

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'custom';
      });
      _loadDashboardData();
    }
  }

  int _getStatCount(List<String> keys) {
    if (_ticketCounts == null) return 0;
    for (var k in keys) {
      if (_ticketCounts!.containsKey(k) && _ticketCounts![k] != null) {
        final val = _ticketCounts![k];
        if (val is num) return val.toInt();
        if (val is String) return int.tryParse(val) ?? 0;
      }
    }
    return 0;
  }

  Color _getCategoryColor(int index, String? hexStr, [String? name]) {
    final lowerName = (name ?? '').toLowerCase();
    if (lowerName.contains('question')) return const Color(0xFF828393);
    if (lowerName.contains('incident')) return const Color(0xFFFFB054);
    if (lowerName.contains('probl')) return const Color(0xFFFF5B5C);
    if (lowerName.contains('fonctionnalit')) return const Color(0xFF826AF9);
    if (lowerName.contains('modification')) return const Color(0xFF4F8CF6);

    if (hexStr != null && hexStr.isNotEmpty) {
      final lower = hexStr.toLowerCase();
      if (!['#ccc', '#cccccc', '#e2e8f0', '#f1f5f9', '#ffffff', '#000000'].contains(lower)) {
        final clean = lower.replaceAll('#', '');
        if (clean.length == 6) {
          return Color(int.parse("FF$clean", radix: 16));
        }
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
      case 'urgente':
        return const Color(0xFFFF5B5C);
      default:
        return const Color(0xFF7367F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final userRole = auth.userRole;

    final filterItems = [
      {'label': 'Aujourd\'hui', 'value': 'today'},
      {'label': 'Hier', 'value': 'yesterday'},
      {'label': 'Les 7 derniers jours', 'value': 'last7'},
      {'label': 'Les 30 derniers jours', 'value': 'last30'},
      {'label': 'Les 3 derniers mois', 'value': 'last3months'},
      {'label': 'L\'année dernière', 'value': 'lastyear'},
      {'label': 'Personnalisé', 'value': 'custom'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Filter Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vue d\'ensemble',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          items: filterItems.map((item) {
                            return DropdownMenuItem<String>(
                              value: item['value'],
                              child: Text(item['label']!),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              if (val == 'custom') {
                                _selectCustomDateRange();
                              } else {
                                setState(() {
                                  _selectedFilter = val;
                                });
                                _loadDashboardData();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, style: const TextStyle(color: AppTheme.danger), textAlign: TextAlign.center),
                    ),
                  )
                else ...[
                  // Stat Cards Grid (Matching Manager Icons & Colors)
                  Row(
                    children: [
                      Expanded(child: _buildWebStatCard('Tickets Nouveaux', _getStatCount(['nouveau']), const Color(0xFF00BAD1), Icons.mail_outline, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildWebStatCard('Tickets en cours', _getStatCount(['en_cours', 'encours']), const Color(0xFF7367F0), Icons.autorenew, isDark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildWebStatCard('Tickets en attente', _getStatCount(['en_attente', 'enattente']), const Color(0xFFFF9F43), Icons.access_time, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildWebStatCard('Tickets Résolus', _getStatCount(['resolu', 'resolus']), const Color(0xFF28C76F), Icons.check_circle_outline, isDark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildWebStatCard('Tickets Fermés', _getStatCount(['ferme', 'fermes']), const Color(0xFFFF5B5C), Icons.block, isDark),
                  const SizedBox(height: 24),

                  // GRAPHS WITH CENTERED KEYS
                  if (userRole == 'user') ...[
                    _buildUserCategoriesChartCard('Tickets par catégories', _categoriesChart, isDark),
                  ] else ...[
                    _buildAgentPriorityDonutCard('Tickets par Priorité', _prioritiesChart, isDark),
                    const SizedBox(height: 20),
                    _buildAgentCategoryBarCard('Tickets par Catégorie', _categoriesChart, isDark),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebStatCard(String title, int count, Color color, IconData icon, bool isDark) {
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
                Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2B2C40))),
                Text(title, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFF5E5873)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPriorityDonutCard(String title, List<dynamic> items, bool isDark) {
    int totalCount = 0;
    for (var item in items) {
      totalCount += ((item['count'] ?? 0) as num).toInt();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : const Color(0xFF5E5873))),
          ),
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
          // CENTERED LEGEND KEYS
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

  Widget _buildAgentCategoryBarCard(String title, List<dynamic> items, bool isDark) {
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

  Widget _buildUserCategoriesChartCard(String title, List<dynamic> items, bool isDark) {
    return _buildAgentCategoryBarCard(title, items, isDark);
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