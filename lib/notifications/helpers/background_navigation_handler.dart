class BackgroundNavigationHandler {
  static final BackgroundNavigationHandler _instance =
      BackgroundNavigationHandler._internal();
  factory BackgroundNavigationHandler() => _instance;
  BackgroundNavigationHandler._internal();

  String? pendingChatId;
  String? pendingUserId;

  void setPendingNavigation(String chatId, String userId) {
    pendingChatId = chatId;
    pendingUserId = userId;
  }

  void clearPendingNavigation() {
    pendingChatId = null;
    pendingUserId = null;
  }
}
