part of 'notifications_cubit.dart';

enum NotificationsStatus { idle, loading, success, error }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.idle,
    this.items = const [],
    this.unreadCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.errorMessage,
    this.preferences,
    this.isUpdatingPreferences = false,
  });

  final NotificationsStatus status;
  final List<NotificationItem> items;
  final int unreadCount;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;
  final String? errorMessage;
  final NotificationPreferences? preferences;
  final bool isUpdatingPreferences;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationItem>? items,
    int? unreadCount,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
    String? errorMessage,
    NotificationPreferences? preferences,
    bool? isUpdatingPreferences,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
      preferences: preferences ?? this.preferences,
      isUpdatingPreferences:
          isUpdatingPreferences ?? this.isUpdatingPreferences,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        unreadCount,
        hasMore,
        isLoadingMore,
        currentPage,
        errorMessage,
        preferences,
        isUpdatingPreferences,
      ];
}
