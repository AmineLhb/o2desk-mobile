import 'category_model.dart';
import 'priority_model.dart';
import 'message_model.dart';
import 'user_model.dart';

class TicketFileModel {
  final int id;
  final String filename;
  final String filepath;
  final int filesize;

  TicketFileModel({required this.id, required this.filename, required this.filepath, required this.filesize});

  factory TicketFileModel.fromJson(Map<String, dynamic> json) {
    return TicketFileModel(
      id: json['id'] ?? 0,
      filename: json['filename'] ?? '',
      filepath: json['filepath'] ?? '',
      filesize: json['filesize'] ?? 0,
    );
  }
}

class TicketModel {
  final int id;
  final String reference;
  final String title;
  final String status;
  final int? userId;
  final int? priorityId;
  final String createdAt;
  final UserModel? user;
  final PriorityModel? priority;
  final List<CategoryModel> categories;
  final List<MessageModel> messages;
  final List<TicketFileModel> files;
  final List<UserModel> agents;

  TicketModel({
    required this.id,
    required this.reference,
    required this.title,
    required this.status,
    this.userId,
    this.priorityId,
    required this.createdAt,
    this.user,
    this.priority,
    required this.categories,
    required this.messages,
    required this.files,
    required this.agents,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    var catList = <CategoryModel>[];
    if (json['categories'] != null) {
      catList = (json['categories'] as List).map((c) => CategoryModel.fromJson(c)).toList();
    }

    var msgList = <MessageModel>[];
    if (json['messages'] != null) {
      msgList = (json['messages'] as List).map((m) => MessageModel.fromJson(m)).toList();
    }

    var fileList = <TicketFileModel>[];
    if (json['files'] != null) {
      fileList = (json['files'] as List).map((f) => TicketFileModel.fromJson(f)).toList();
    }

    var agentList = <UserModel>[];
    if (json['agents'] != null) {
      agentList = (json['agents'] as List).map((a) => UserModel.fromJson(a)).toList();
    }

    return TicketModel(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      title: json['titre'] ?? json['title'] ?? '',
      status: json['statut'] ?? 'Ouvert',
      userId: json['user_id'],
      priorityId: json['ticket_priority_id'],
      createdAt: json['created_at'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      priority: json['priority'] != null ? PriorityModel.fromJson(json['priority']) : null,
      categories: catList,
      messages: msgList,
      files: fileList,
      agents: agentList,
    );
  }
}