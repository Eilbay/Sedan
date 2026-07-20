import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/features/notifications/data/data_sources/notifications_remote_data_source.dart';
import 'package:optombai/features/notifications/data/models/notification_item.dart';
import 'package:optombai/features/notifications/data/models/notification_preferences.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required NotificationsRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const NotificationsState());

  final NotificationsRemoteDataSource _dataSource;

  Future<void> loadFirstPage() async {
    emit(state.copyWith(
      status: NotificationsStatus.loading,
      errorMessage: null,
    ));
    try {
      final page = await _dataSource.fetchList(page: 1);
      emit(state.copyWith(
        status: NotificationsStatus.success,
        items: page.items,
        currentPage: 1,
        hasMore: page.next != null,
      ));
      await refreshUnreadCount();
    } on AppException catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: e.messages.firstOrNull ?? 'Не удалось загрузить',
      ));
    } catch (_) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Не удалось загрузить',
      ));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    final next = state.currentPage + 1;
    try {
      final page = await _dataSource.fetchList(page: next);
      emit(state.copyWith(
        items: [...state.items, ...page.items],
        currentPage: next,
        hasMore: page.next != null,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _dataSource.fetchUnreadCount();
      emit(state.copyWith(unreadCount: count));
    } catch (_) {
      // Non-critical; badge stays stale until next refresh.
    }
  }

  Future<void> markAsRead(String id) async {
    final updated = state.items
        .map((it) => it.id == id ? it.copyWith(isRead: true) : it)
        .toList();
    final newUnread =
        state.unreadCount > 0 ? state.unreadCount - 1 : state.unreadCount;
    emit(state.copyWith(items: updated, unreadCount: newUnread));
    try {
      await _dataSource.markRead(id);
    } catch (_) {
      // Optimistic UI: leave local state as-is, next refresh will reconcile.
    }
  }

  Future<void> markAllRead() async {
    final unreadIds = state.items
        .where((it) => !it.isRead && it.type.belongsToNotifications)
        .map((it) => it.id)
        .where((id) => id.isNotEmpty)
        .toList();
    final updated = state.items.map((it) => it.copyWith(isRead: true)).toList();
    emit(state.copyWith(items: updated, unreadCount: 0));
    try {
      for (final id in unreadIds) {
        await _dataSource.markRead(id);
      }
    } catch (_) {}
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await _dataSource.fetchPreferences();
      emit(state.copyWith(preferences: prefs));
    } catch (_) {}
  }

  Future<void> updatePreferences(Map<String, dynamic> patch) async {
    final current = state.preferences;
    if (current == null) return;

    emit(state.copyWith(isUpdatingPreferences: true));
    try {
      final updated = await _dataSource.updatePreferences(patch);
      emit(state.copyWith(
        preferences: updated,
        isUpdatingPreferences: false,
      ));
    } catch (_) {
      emit(state.copyWith(isUpdatingPreferences: false));
    }
  }

  void clear() {
    emit(const NotificationsState());
  }
}
