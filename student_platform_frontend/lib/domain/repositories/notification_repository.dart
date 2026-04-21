import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationsResponse?> getNotifications();
  Future<bool> createNotification(String title, String message, String targetType, int? targetGroupId);
  Future<bool> markAsRead(int id);
  Future<bool> markAllAsRead();
}
