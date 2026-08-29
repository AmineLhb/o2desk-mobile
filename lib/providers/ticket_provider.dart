import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  TicketModel? _currentTicket;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatusFilter = 'Tous';
  String _searchQuery = '';

  List<TicketModel> get tickets => _tickets;
  TicketModel? get currentTicket => _currentTicket;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatusFilter => _selectedStatusFilter;

  List<TicketModel> get filteredTickets {
    return _tickets.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.reference.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_selectedStatusFilter == 'Tous') return matchesSearch;
      return matchesSearch && t.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();
  }

  void setFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get('/tickets');
      if (res['success'] == true && res['data'] != null) {
        final rawData = res['data'];
        List list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          list = rawData['data'] as List;
        }
        _tickets = list.map((json) => TicketModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTicketDetails(dynamic idOrRef) async {
    _isLoading = true;
    _currentTicket = null;
    notifyListeners();

    try {
      final res = await ApiService.get('/tickets/$idOrRef');
      if (res['success'] == true && res['ticket'] != null) {
        _currentTicket = TicketModel.fromJson(res['ticket']);
      } else if (res['success'] == true && res['data'] != null) {
        _currentTicket = TicketModel.fromJson(res['data']);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTicket({
    required String title,
    required String message,
    required int priorityId,
    int? categoryId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'titre': title,
        'message': message,
        'ticket_priority_id': priorityId,
        if (categoryId != null) 'category_id': categoryId,
      };

      final res = await ApiService.post('/tickets', payload);
      if (res['success'] == true) {
        await fetchTickets();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> replyToTicket(int ticketId, String message) async {
    try {
      final res = await ApiService.post('/tickets/$ticketId/reply', {'message': message});
      if (res['success'] == true) {
        await fetchTicketDetails(ticketId);
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    return false;
  }

  Future<bool> updateStatus(int ticketId, String newStatus) async {
    try {
      final res = await ApiService.post('/tickets/$ticketId/status', {'statut': newStatus});
      if (res['success'] == true) {
        await fetchTicketDetails(ticketId);
        await fetchTickets();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    return false;
  }
}