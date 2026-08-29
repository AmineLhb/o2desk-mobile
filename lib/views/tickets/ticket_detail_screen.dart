import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _isLoading = true;
  bool _isSending = false;
  bool _isChangingStatus = false;
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  final _replyController = TextEditingController();
  final List<PlatformFile> _replyFiles = [];

  @override
  void initState() {
    super.initState();
    _fetchTicketDetails();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    return AppTheme.getStatusText(status);
  }

  Future<void> _fetchTicketDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/tickets/${widget.ticketId}');
      if (mounted) {
        setState(() {
          _ticket = res['data'] ?? res['ticket'];
          _messages = res['messages'] ?? _ticket?['messages'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _changeTicketStatus(String newStatus) async {
    setState(() => _isChangingStatus = true);
    try {
      final res = await ApiService.post('/tickets/${widget.ticketId}/status', {'statut': newStatus});
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Statut mis à jour !')),
          );
        }
        _fetchTicketDetails();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Impossible de modifier le statut.')),
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
      if (mounted) setState(() => _isChangingStatus = false);
    }
  }

  void _showStatusPickerSheet(String currentStatus) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final statusOptions = ['Nouveau', 'En cours', 'En attente', 'Résolu', 'Fermé'];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Changer le statut du ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...statusOptions.map((st) {
                  final isCurrent = st == currentStatus;
                  final color = AppTheme.getStatusColor(st);
                  return ListTile(
                    leading: Icon(
                      isCurrent ? Icons.check_circle : Icons.circle_outlined,
                      color: color,
                    ),
                    title: Text(
                      st,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? color : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _changeTicketStatus(st);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickReplyFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt', 'zip'],
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _replyFiles.addAll(result);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de sélectionner le fichier.')),
        );
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty && _replyFiles.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final endpoint = '/tickets/${widget.ticketId}/reply';
      Map<String, dynamic> res;

      if (_replyFiles.isNotEmpty) {
        res = await ApiService.postMultipart(
          endpoint,
          {'message': text},
          _replyFiles,
        );
      } else {
        res = await ApiService.post(endpoint, {'message': text});
      }

      if (res['success'] == true || res['data'] != null) {
        _replyController.clear();
        setState(() {
          _replyFiles.clear();
        });
        _fetchTicketDetails();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Erreur lors de l\'envoi.')),
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
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openFileUrl(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir l\'URL.')),
          );
        }
      }
    } catch (_) {}
  }

  void _consultAttachment(dynamic fileObj) {
    String filename = 'Document';
    String fileUrl = '';
    int? fileId;

    if (fileObj is Map<String, dynamic>) {
      filename = fileObj['filename'] ?? fileObj['original_filename'] ?? 'Fichier';
      fileUrl = fileObj['url'] ?? fileObj['file_url'] ?? '';
      fileId = fileObj['id'];
    } else if (fileObj is String) {
      fileUrl = fileObj;
      filename = fileUrl.split('/').last;
    }

    if (fileUrl.isEmpty) return;

    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final extName = filename.contains('.') ? filename.split('.').last.toUpperCase() : 'FILE';
    final isPdf = extName == 'PDF' || filename.toLowerCase().endsWith('.pdf');
    final isImage = ['JPG', 'JPEG', 'PNG', 'GIF', 'WEBP'].contains(extName);

    if (isImage) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(20),
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    child: const Text('Erreur de chargement de l\'image'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openFileUrl(fileUrl);
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Télécharger l\'image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isPdf) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return InAppPdfViewerModal(
            fileUrl: fileUrl,
            filename: filename,
            isDark: isDark,
            onDownload: () => _openFileUrl(fileUrl),
          );
        },
      );
    } else {
      final docIcon = _getDocumentIcon(filename);
      final docColor = _getDocumentColor(filename);

      String previewTextUrl = fileUrl;
      if (fileUrl.contains('/uploads/')) {
        previewTextUrl = fileUrl.replaceAll('/uploads/', '/preview-text/');
      } else if (fileId != null) {
        previewTextUrl = fileUrl.replaceAll(RegExp(r'/files/\d+'), '/files/$fileId/preview-text');
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return FutureBuilder<http.Response>(
                future: http.get(Uri.parse(previewTextUrl)),
                builder: (context, snapshot) {
                  String extractedText = '';
                  bool isLoading = snapshot.connectionState == ConnectionState.waiting;

                  if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                    try {
                      final json = jsonDecode(snapshot.data!.body);
                      if (json['success'] == true && json['html'] != null) {
                        extractedText = (json['html'] as String)
                            .replaceAll(RegExp(r'</p><p>'), '\n\n')
                            .replaceAll(RegExp(r'<[^>]*>'), '');
                      }
                    } catch (_) {}
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: docColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Icon(docIcon, color: docColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(filename, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('Aperçu $extName', style: TextStyle(fontSize: 11, color: docColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                child: SelectableText(
                                  extractedText.isNotEmpty ? extractedText : 'Aucun contenu texte extrait.',
                                  style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _openFileUrl(fileUrl);
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Télécharger le fichier'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  IconData _getDocumentIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['zip', 'rar'].contains(ext)) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  Color _getDocumentColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return const Color(0xFFEA5455);
    if (['doc', 'docx'].contains(ext)) return const Color(0xFF7367F0);
    if (['xls', 'xlsx'].contains(ext)) return const Color(0xFF28C76F);
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final roleStr = (auth.userRole ?? auth.user?.role ?? 'user').toString().toLowerCase();
    final isManager = roleStr.contains('manager');
    final isUser = roleStr == 'user';
    final isAgent = roleStr.contains('agent') || roleStr.contains('admin') || (!isUser && !isManager);
    final canChangeStatus = isAgent;

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final currentUserId = auth.user?.id?.toString();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du Ticket')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du Ticket')),
        body: const Center(child: Text('Ticket introuvable.')),
      );
    }

    final ref = _ticket!['reference'] ?? _ticket!['ref'] ?? 'TKT';
    final sujet = _ticket!['sujet'] ?? _ticket!['titre'] ?? _ticket!['title'] ?? 'Sans sujet';
    final status = _ticket!['statut'] ?? _ticket!['status'] ?? 'Nouveau';
    final isClosed = ['Fermé', 'Résolu', 'Clôturé'].contains(status);
    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.lightTextDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (canChangeStatus) ...[
            IconButton(
              icon: _isChangingStatus
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.white : AppTheme.primary))
                  : Icon(Icons.published_with_changes, color: isDark ? Colors.white : const Color(0xFF2B2C40), size: 24),
              tooltip: 'Changer le statut',
              onPressed: () => _showStatusPickerSheet(status),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Card (Sujet on left, Dynamic Color Status Badge on right - Exact Screenshot)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sujet,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.getStatusColor(status),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Discussion & Réponses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_messages.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucun message pour le moment.')))
                  else
                    ..._messages.map((m) {
                      final msgUserId = (m['user_id'] ?? m['user']?['id'])?.toString();
                      final msgAgentId = (m['agent_id'] ?? m['agent']?['id'])?.toString();
                      final isAgentMsg = msgAgentId != null;

                      bool isMyMessage = false;
                      if (isAgent || isManager) {
                        if (msgAgentId != null && (currentUserId == null || msgAgentId == currentUserId)) {
                          isMyMessage = true;
                        }
                      } else {
                        if (msgUserId != null && (currentUserId == null || msgUserId == currentUserId)) {
                          isMyMessage = true;
                        }
                      }

                      final isRight = isMyMessage;
                      final senderName = (m['agent'] != null && m['agent'] is Map)
                          ? '${m['agent']['first_name'] ?? m['agent']['prenom'] ?? ''} ${m['agent']['last_name'] ?? m['agent']['nom'] ?? ''} (Agent)'.trim()
                          : (m['user'] != null && m['user'] is Map)
                              ? '${m['user']['first_name'] ?? m['user']['prenom'] ?? ''} ${m['user']['last_name'] ?? m['user']['nom'] ?? ''}'.trim()
                              : m['user_name'] ?? m['sender_name'] ?? (isAgentMsg ? 'Agent' : 'Client');

                      final content = m['message'] ?? m['content'] ?? '';
                      final files = (m['attachments'] as List<dynamic>?) ?? (m['files'] as List<dynamic>?) ?? [];

                      final cardBgColor = isDark
                          ? (isRight ? const Color(0xFF1E293B) : AppTheme.darkSurface)
                          : (isRight ? const Color(0xFFF0F7FF) : Colors.white);
                      final borderColor = isDark
                          ? AppTheme.darkBorder
                          : (isRight ? AppTheme.primary.withOpacity(0.3) : const Color(0xFFEBEBEB));

                      return Align(
                        alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: isRight ? 36 : 0,
                            right: isRight ? 0 : 36,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAgentMsg ? Icons.support_agent : Icons.person,
                                    size: 15,
                                    color: isAgentMsg ? const Color(0xFF7367F0) : AppTheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    senderName.isNotEmpty ? senderName : (isAgentMsg ? 'Agent' : 'Client'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isAgentMsg ? const Color(0xFF7367F0) : AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                content,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark ? Colors.white : const Color(0xFF2B2C40),
                                ),
                              ),
                              if (files.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: files.map((f) {
                                    final fName = f is Map ? (f['filename'] ?? f['original_filename'] ?? 'Fichier') : 'Fichier';
                                    return ActionChip(
                                      avatar: const Icon(Icons.attach_file, size: 14, color: AppTheme.primary),
                                      label: Text(fName, style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _consultAttachment(f),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),

          // Bottom Bar (Reply Bar, Manager Consultation Bar, or Closed Safe Area Bar)
          if (!isClosed && !isManager)
            SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_replyFiles.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          children: _replyFiles.map((f) {
                            return Chip(
                              avatar: const Icon(Icons.attach_file, size: 14),
                              label: Text(f.name, style: const TextStyle(fontSize: 11)),
                              onDeleted: () {
                                setState(() {
                                  _replyFiles.remove(f);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: AppTheme.primary),
                          onPressed: _pickReplyFiles,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            decoration: const InputDecoration(
                              hintText: 'Écrire une réponse...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isSending
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: AppTheme.primary),
                          onPressed: _isSending ? null : _sendReply,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (isManager)
            SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : const Color(0xFFF8F9FA),
                  border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Mode Manager : Consultation du ticket uniquement.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
            )
          else if (isClosed)
            SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : const Color(0xFFF8F9FA),
                  border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Ce ticket est $status (Lecture seule).',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// MULTI-PAGE SCROLLABLE IN-APP PDF VIEWER MODAL
class InAppPdfViewerModal extends StatefulWidget {
  final String fileUrl;
  final String filename;
  final bool isDark;
  final VoidCallback onDownload;

  const InAppPdfViewerModal({
    super.key,
    required this.fileUrl,
    required this.filename,
    required this.isDark,
    required this.onDownload,
  });

  @override
  State<InAppPdfViewerModal> createState() => _InAppPdfViewerModalState();
}

class _InAppPdfViewerModalState extends State<InAppPdfViewerModal> {
  String? _localPdfPath;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndPreparePdf();
  }

  Future<void> _downloadAndPreparePdf() async {
    try {
      final res = await http.get(Uri.parse(widget.fileUrl));
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final cleanName = widget.filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '_');
        final file = File('${dir.path}/$cleanName');
        await file.writeAsBytes(res.bodyBytes);

        if (mounted) {
          setState(() {
            _localPdfPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Impossible de charger le fichier PDF (Erreur ${res.statusCode}).';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du téléchargement du PDF.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEA5455).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEA5455), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.filename, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        _totalPages > 0 ? 'Page ${_currentPage + 1} sur $_totalPages' : 'Document PDF',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFEA5455), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (_totalPages > 1) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () {
                            _pdfViewController?.setPage(_currentPage - 1);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages - 1
                        ? () {
                            _pdfViewController?.setPage(_currentPage + 1);
                          }
                        : null,
                  ),
                ],
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // In-App Scrollable Multi-Page PDF Viewer
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 12),
                        Text('Chargement du document PDF...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      )
                    : PDFView(
                        filePath: _localPdfPath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: false,
                        pageSnap: false,
                        onViewCreated: (controller) {
                          _pdfViewController = controller;
                        },
                        onRender: (pages) {
                          setState(() {
                            _totalPages = pages ?? 0;
                          });
                        },
                        onPageChanged: (page, total) {
                          setState(() {
                            _currentPage = page ?? 0;
                            _totalPages = total ?? 0;
                          });
                        },
                        onError: (error) {
                          setState(() {
                            _errorMessage = error.toString();
                          });
                        },
                      ),
          ),

          // Bottom Download Button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark ? AppTheme.darkSurface : Colors.white,
                border: Border(top: BorderSide(color: widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: widget.onDownload,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text('Télécharger le fichier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA5455),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}