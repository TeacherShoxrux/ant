import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final ApiService _apiService = ApiService();

  NotificationCubit() : super(NotificationInitial());

  Future<void> fetchNotifications() async {
    // Only show loading if we haven't loaded anything yet to avoid flicker
    if (state is! NotificationLoaded) {
      emit(NotificationLoading());
    }
    
    try {
      final data = await _apiService.getNotifications();
      if (data != null) {
        final List list = data['notifications'];
        final int count = data['unreadCount'];
        
        emit(NotificationLoaded(
          notifications: list.map((n) => NotificationModel.fromJson(n)).toList(),
          unreadCount: count,
        ));
      } else {
        emit(const NotificationError('Xabarlarni yuklashda xatolik'));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final success = await _apiService.markAsRead(id);
      if (success) {
        await fetchNotifications();
      }
    } catch (e) {
      // Handle
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        await fetchNotifications();
      }
    } catch (e) {
      // Handle
    }
  }

  Future<bool> sendNotification(String title, String message, String targetType, int? targetGroupId) async {
    try {
      final success = await _apiService.createNotification(title, message, targetType, targetGroupId);
      if (success) {
        await fetchNotifications();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
