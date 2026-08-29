import 'user_model.dart';

class MessageModel {
  final int id;
  final int ticketId;
  final String message;
  final int? userId;
  final int? agentId;
  final String createdAt;
  final UserModel? userSender;
  final UserModel? agentSender;

  MessageModel({
    required this.id,
    required this.ticketId,
    required this.message,
    this.userId,
    this.agentId,
    required this.createdAt,
    this.userSender,
    this.agentSender,
  });

  bool get isAgentReply => agentId != null;

  String get senderName {
    if (agentSender != null) return '${agentSender!.fullName} (Agent)';
    if (userSender != null) return userSender!.fullName;
    return isAgentReply ? 'Support Agent' : 'Client';
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      message: json['message'] ?? '',
      userId: json['user_id'],
      agentId: json['agent_id'],
      createdAt: json['created_at'] ?? '',
      userSender: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      agentSender: json['agent'] != null ? UserModel.fromJson(json['agent']) : null,
    );
  }
}