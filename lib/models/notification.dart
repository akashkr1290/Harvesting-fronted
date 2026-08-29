// Mirrors com.harvestflow.api.dto.notification.NotificationResponse.
class AppNotification {
  final String id;
  final String category;
  final String title;
  final String message;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.createdAt,
    required this.readAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromApi(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedEntityType: json['relatedEntityType'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
    );
  }
}
