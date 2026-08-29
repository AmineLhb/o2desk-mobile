import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  List<dynamic> _filteredTickets = [];
  String _selectedStatusFilter = 'Tous';
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.get('/tickets');
      if (res['success'] == true || res['data'] != null) {
        dynamic list = res['data'];
        if (list is Map<String, dynamic> && list.containsKey('data')) {
          list = list['data'];
        }
        setState(() {
          _tickets = list is List ? list : [];
          _applyFilters();
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Erreur lors du chargement des tickets.';
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

  void _applyFilters() {
    setState(() {
      _filteredTickets = _tickets.where((ticket) {
        final status = (ticket['statut'] ?? ticket['status'] ?? '').toString();
        final ref = (ticket['reference'] ?? '').toString().toLowerCase();
        final titre = (ticket['titre'] ?? '').toString().toLowerCase();

        bool matchesStatus = true;
        if (_selectedStatusFilter != 'Tous') {
          matchesStatus = status.toLowerCase() == _selectedStatusFilter.toLowerCase();
        }

        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          matchesSearch = ref.contains(query) || titre.contains(query);
        }

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final b = StringBuffer();
      if (hex.length == 6 || hex.length == 7) b.write('ff');
      b.write(hex.replaceFirst('#', ''));
      return Color(int.parse(b.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Color _getStatusChipColor(String status) {
    switch (status.toLowerCase()) {
      case 'tous':
        return AppTheme.primary;
      case 'nouveau':
      case 'ouvert':
        return const Color(0xFF00BAD1);
      case 'en attente':
        return const Color(0xFFFF9F43);
      case 'en cours':
      case 'en traitement':
        return const Color(0xFF7367F0);
      case 'résolu':
      case 'traité':
        return const Color(0xFF28C76F);
      case 'fermé':
      case 'clôturé':
        return const Color(0xFFEA5455);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _applyFilters();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Solid Filter Chips for Statuses
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tous', 'Nouveau', 'En attente', 'En cours', 'Résolu', 'Fermé'].map((status) {
                        final isSelected = _selectedStatusFilter == status;
                        final chipColor = _getStatusChipColor(status);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            selectedColor: chipColor,
                            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : chipColor,
                            ),
                            side: BorderSide(color: chipColor.withOpacity(isSelected ? 1.0 : 0.6)),
                            onSelected: (_) {
                              setState(() {
                                _selectedStatusFilter = status;
                                _applyFilters();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Tickets List Area
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchTickets,
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
                        : _filteredTickets.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 60),
                                  Center(child: Text('Aucun ticket trouvé.', style: TextStyle(color: AppTheme.secondary))),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredTickets.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final ticket = _filteredTickets[index];
                                  final ref = ticket['reference'] ?? '';
                                  final titre = ticket['titre'] ?? 'Sans titre';
                                  final status = ticket['statut'] ?? ticket['status'] ?? 'Nouveau';

                                  // Calculate responses count accurately
                                                                    int responsesCount = 0;
                                  if (ticket['responses_count'] != null) {
                                    responsesCount = (ticket['responses_count'] is int)
                                        ? ticket['responses_count'] as int
                                        : int.tryParse(ticket['responses_count'].toString()) ?? 0;
                                  } else if (ticket['messages'] is List) {
                                    responsesCount = (ticket['messages'] as List)
                                        .where((m) => m is Map && m['agent_id'] != null)
                                        .length;
                                  }

                                  // Priority Badge Colors (Vivid High Contrast Web Style)
                                  final priorityObj = ticket['priority'];
                                  final priorityName = priorityObj?['nom'] ?? 'Normale';
                                  final priorityTextHex = priorityObj?['color']?['text_hex'] ?? priorityObj?['color']?['badge_hex'];
                                  final priorityColor = _parseHex(priorityTextHex, AppTheme.primary);

                                  // Category Badge
                                  final categoriesList = ticket['categories'] as List? ?? [];
                                  final firstCat = categoriesList.isNotEmpty ? categoriesList.first : null;
                                  final catName = firstCat?['nom'];
                                  final catTextHex = firstCat?['color']?['text_hex'] ?? firstCat?['color']?['badge_hex'];
                                  final catColor = _parseHex(catTextHex, const Color(0xFF00BAD1));

                                  return Card(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        if (ticket['id'] != null) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket['id'])),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(ref, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.getStatusColor(status),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              titre,
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                // Priority Crisp Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: priorityColor.withOpacity(isDark ? 0.25 : 0.16),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: priorityColor.withOpacity(0.4)),
                                                  ),
                                                  child: Text(
                                                    priorityName,
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priorityColor),
                                                  ),
                                                ),
                                                if (catName != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: catColor.withOpacity(isDark ? 0.25 : 0.16),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: catColor.withOpacity(0.4)),
                                                    ),
                                                    child: Text(
                                                      catName,
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
                                                    ),
                                                  ),
                                                ],
                                                const Spacer(),
                                                // Responses Count Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.chat_bubble_outline, size: 13, color: AppTheme.primary),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '$responsesCount ${responsesCount > 1 ? "réponses" : "réponse"}',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}