import 'package:chat/chat.dart';
import 'package:flutter/material.dart';

abstract class IOnboardingRouter {
  void onSessionSuccess(BuildContext context, User me);
  void navigateHome(BuildContext context, User me);
}

class OnboardingRouter implements IOnboardingRouter {
  final Function(User user) onSessionConnected;
  final Function(User user) showHome;

  OnboardingRouter(this.onSessionConnected, this.showHome);

  @override
  void onSessionSuccess(BuildContext context, User me) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => onSessionConnected(me)),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void navigateHome(BuildContext context, User me) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => showHome(me)),
      (Route<dynamic> route) => false,
    );
  }
}
