import 'package:juvapay/models/enums.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final NotificationPriority priority;
  final List<NotificationChannel> channels;
  final String? actionUrl;
  final String? actionLabel;
  final String? referenceId;
  final String? referenceType;
  final String? icon;
  final String? color;
  final Map<String, dynamic> metadata;
  final DateTime? expiresAt;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.priority,
    required this.channels,
    this.actionUrl,
    this.actionLabel,
    this.referenceId,
    this.referenceType,
    this.icon,
    this.color,
    this.metadata = const {},
    this.expiresAt,
    this.scheduledFor,
    required this.createdAt,
    this.readAt,
    this.archivedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (json['notification_type'] ?? 'SYSTEM').toLowerCase(),
        orElse: () => NotificationType.system,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'UNREAD').toLowerCase(),
        orElse: () => NotificationStatus.unread,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == (json['priority'] ?? 'MEDIUM').toLowerCase(),
        orElse: () => NotificationPriority.medium,
      ),
      channels:
          (json['channels'] as List<dynamic>? ?? [])
              .map(
                (e) => NotificationChannel.values.firstWhere(
                  (c) => c.name == (e as String).toLowerCase(),
                  orElse: () => NotificationChannel.inApp,
                ),
              )
              .toList(),
      actionUrl: json['action_url'],
      actionLabel: json['action_label'],
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      icon: json['icon'],
      color: json['color'],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'])
              : null,
      scheduledFor:
          json['scheduled_for'] != null
              ? DateTime.parse(json['scheduled_for'])
              : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      archivedAt:
          json['archived_at'] != null
              ? DateTime.parse(json['archived_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': type.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'priority': priority.name.toUpperCase(),
      'channels': channels.map((e) => e.name.toUpperCase()).toList(),
      'action_url': actionUrl,
      'action_label': actionLabel,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'icon': icon,
      'color': color,
      'metadata': metadata,
      'expires_at': expiresAt?.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
    List<NotificationChannel>? channels,
    String? actionUrl,
    String? actionLabel,
    String? referenceId,
    String? referenceType,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? archivedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      channels: channels ?? this.channels,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  bool get isUnread => status == NotificationStatus.unread;
  bool get isRead => status == NotificationStatus.read;
  bool get isArchived => status == NotificationStatus.archived;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isScheduled => scheduledFor != null;
  bool get canShow =>
      !isExpired && (!isScheduled || DateTime.now().isAfter(scheduledFor!));
}
