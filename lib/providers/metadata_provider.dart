import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/priority_model.dart';
import '../services/api_service.dart';

class MetadataProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<PriorityModel> _priorities = [];
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _faqs = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<PriorityModel> get priorities => _priorities;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<dynamic> get faqs => _faqs;
  bool get isLoading => _isLoading;

  Future<void> fetchAllMetadata() async {
    _isLoading = true;
    notifyListeners();

    try {
      final catRes = await ApiService.get('/categories');
      if (catRes['success'] == true) {
        _categories = (catRes['data'] as List).map((c) => CategoryModel.fromJson(c)).toList();
      }

      final prioRes = await ApiService.get('/priorities');
      if (prioRes['success'] == true) {
        _priorities = (prioRes['data'] as List).map((p) => PriorityModel.fromJson(p)).toList();
      }

      await fetchDashboardStats();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    try {
      final statsRes = await ApiService.get('/dashboard/stats');
      if (statsRes['success'] == true) {
        _dashboardStats = statsRes['stats'];
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchFaqs() async {
    try {
      final faqRes = await ApiService.get('/faqs');
      if (faqRes['success'] == true) {
        _faqs = faqRes['data'];
      }
    } catch (_) {}
    notifyListeners();
  }
}