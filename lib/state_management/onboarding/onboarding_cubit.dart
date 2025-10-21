import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/state_management/onboarding/onboarding_state.dart';
import 'package:secuchat/viewmodels/auth/auth_view_model.dart';
import 'package:secuchat/viewmodels/auth/email_sign_in_view_model.dart';
import 'package:secuchat/viewmodels/auth/google_sign_in_view_model.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

enum AuthType { google, email }

class OnboardingCubit extends Cubit<OnboardingState> {
  final AuthViewModel _authViewModel;
  final GoogleSignInViewModel _googleSignInViewModel;
  final EmailSignInViewModel _emailSignInViewModel;
  //TODO: Impl Image uploader

  OnboardingCubit(this._authViewModel, this._emailSignInViewModel,
      this._googleSignInViewModel)
      : super(OnboardingInitial());
//TODO: Impl auth type
  Future<void> connect(User user) async {
    emit(OnboardingLoading());
    //TODO: impl photo
    _authViewModel.isSignedIn.listen((isSignedIn) async => isSignedIn
        ? await _updateUserToOnline(user)
        : await _updateUserToOffline(user));
  }

  Future<void> signInWithGoogle() async {
    emit(OnboardingLoading());
    try {
      final user = await _googleSignInViewModel.signIn();
      if (user == null) {
        emit(OnboardingFailure("Authentication interrupted!"));
        return;
      }
      emit(OnboardingSuccess(user));
      return;
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
    }
  }

  Future<void> signInWithEmail(
      {required String email, required String password}) async {
    emit(OnboardingLoading());
    try {
      final user =
          await _emailSignInViewModel.signIn(email: email, password: password);
      if (user == null) {
        emit(OnboardingFailure("Invalid E-mail/password"));
        return;
      }
      emit(OnboardingSuccess(user));
      return;
    } catch (e) {
      emit(OnboardingFailure("Invalid E-mail/password"));
    }
  }

  Future<void> signUpWithEmail(
      {required String email,
      required String name,
      required String password,
      required String username,
      String? photoUrl}) async {
    emit(OnboardingLoading());
    try {
      final user = await _emailSignInViewModel.signUp(
        name: name,
        username: username,
        email: email,
        password: password,
      );
      if (user == null) {
        emit(OnboardingFailure("Invalid Email/Password"));
        return;
      }

      emit(OnboardingSuccess(user));
      return;
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
      return;
    }
  }

  Future<void> _updateUserToOnline(User user) async {
    user.active = true;
    user.lastSeen = DateTime.now();
    try {
      await _authViewModel.connectUser(user);
      emit(OnboardingSuccess(user));
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
      return;
    }
  }

  Future<void> _updateUserToOffline(User user) async {
    user.active = false;
    user.lastSeen = DateTime.now();
    try {
      await _authViewModel.disconnectUser(user);
      emit(OnboardingSuccess(user));
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
      return;
    }
  }
}
