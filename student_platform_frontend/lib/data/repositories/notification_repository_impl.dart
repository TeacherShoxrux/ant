import '../../domain/repositories/notification_repository.dart';
import '../data_sources/remote/api_service.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiService _apiService;

  NotificationRepositoryImpl(this._apiService);

  @override
  Future<NotificationsResponse?> getNotifications() async {
    final response = await _apiService.getNotifications();
    if (response.isSuccessful && response.body != null) {
      return NotificationsResponse.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<bool> createNotification(String title, String message, String targetType, int? targetGroupId) async {
    final response = await _apiService.createNotification({
      'title': title,
      'message': message,
      'targetType': targetType,
      'targetGroupId': targetGroupId,
    });
    return response.isSuccessful;
  }

  @override
  Future<bool> markAsRead(int id) async {
    final response = await _apiService.markAsRead(id);
    return response.isSuccessful;
  }

  @override
  Future<bool> markAllAsRead() async {
    final response = await _apiService.markAllAsRead();
    return response.isSuccessful;
  }
}
