import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl = 'http://192.168.11.111/o2desk3/public/api/v1';
  static bool _hasProbed = false;

  static List<String> generateCandidateUrls() {
    return [
      'http://192.168.11.111/o2desk3/public/api/v1',
      'https://o2desk-app.loca.lt/o2desk3/public/api/v1',
      'http://192.168.1.111/o2desk3/public/api/v1',
      'http://10.0.2.2/o2desk3/public/api/v1',
    ];
  }

  static Future<void> loadBaseUrl() async {
    if (!_hasProbed) {
      await autoProbeWorkingUrl();
    }
  }

  static Future<bool> autoProbeWorkingUrl({bool force = false}) async {
    if (_hasProbed && !force) return true;
    
    final candidates = generateCandidateUrls();
    for (final url in candidates) {
      try {
        final res = await http
            .get(Uri.parse('$url/categories'), headers: {
              'Accept': 'application/json',
              'Bypass-Tunnel-Reminder': 'true',
            })
            .timeout(const Duration(milliseconds: 600));
        if (res.statusCode < 500) {
          baseUrl = url;
          _hasProbed = true;
          return true;
        }
      } catch (_) {}
    }

    baseUrl = 'https://o2desk-app.loca.lt/o2desk3/public/api/v1';
    _hasProbed = true;
    return false;
  }

  static Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
    };
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    await loadBaseUrl();
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(auth: auth);
      final response = await http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12));
      return _handleResponse(response);
    } on SocketException catch (_) {
      await autoProbeWorkingUrl(force: true);
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = await _getHeaders(auth: auth);
        final response = await http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12));
        return _handleResponse(response);
      } catch (_) {
        throw Exception('Impossible de se connecter au serveur O2DESK ($baseUrl).');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    await loadBaseUrl();
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(auth: auth);
      final response = await http.put(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12));
      return _handleResponse(response);
    } on SocketException catch (_) {
      await autoProbeWorkingUrl(force: true);
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = await _getHeaders(auth: auth);
        final response = await http.put(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12));
        return _handleResponse(response);
      } catch (_) {
        throw Exception('Impossible de se connecter au serveur O2DESK ($baseUrl).');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint, {bool auth = true}) async {
    await loadBaseUrl();
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(auth: auth);
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 12));
      return _handleResponse(response);
    } on SocketException catch (_) {
      await autoProbeWorkingUrl(force: true);
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = await _getHeaders(auth: auth);
        final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 12));
        return _handleResponse(response);
      } catch (_) {
        throw Exception('Impossible de se connecter au serveur O2DESK ($baseUrl).');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<PlatformFile> files, {
    bool auth = true,
  }) async {
    await loadBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    request.headers['Accept'] = 'application/json';
    request.headers['Bypass-Tunnel-Reminder'] = 'true';
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    for (final file in files) {
      if (file.path != null && file.path!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('files[]', file.path!));
      }
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(String endpoint, {bool auth = true}) async {
    await loadBaseUrl();
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(auth: auth);
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 12));
      return _handleResponse(response);
    } on SocketException catch (_) {
      await autoProbeWorkingUrl(force: true);
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = await _getHeaders(auth: auth);
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 12));
        return _handleResponse(response);
      } catch (_) {
        throw Exception('Impossible de se connecter au serveur O2DESK ($baseUrl).');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur.');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'data': data};
      } else {
        throw Exception(data['message'] ?? 'Erreur du serveur (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur du serveur ou réponse invalide.');
    }
  }
}