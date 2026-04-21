import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;

  NotificationCubit(this._repository) : super(NotificationInitial());

  Future<void> fetchNotifications() async {
    emit(NotificationLoading());
    try {
      final response = await _repository.getNotifications();
      if (response != null) {
        emit(NotificationLoaded(
          notifications: response.notifications,
          unreadCount: response.unreadCount,
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
      final success = await _repository.markAsRead(id);
      if (success) {
        await fetchNotifications(); // Refresh
      }
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _repository.markAllAsRead();
      if (success) {
        await fetchNotifications();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> sendNotification(String title, String message, String targetType, int? targetGroupId) async {
    try {
      final success = await _repository.createNotification(title, message, targetType, targetGroupId);
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
