import 'package:chat/chat.dart' as chat;
import 'package:secuchat/viewmodels/auth/auth_view_model.dart';

class EmailSignInViewModel extends AuthViewModel {
  EmailSignInViewModel(
      super.auth, super.userService, super.localCache, super._encryption);

  Future<chat.User?> signIn({
    required String email,
    required String password,
  }) async {
    final userCreds =
        await auth.signInWithEmailAndPassword(email: email, password: password);
    if (userCreds.user == null) {
      throw Exception("Unable to sign In!");
    }

    final chat.User user = chat.User(
        name: '',
        email: '',
        username: '',
        publicKeyJwb: await encryptionViewmodel.generateKeys(),
        lastSeen: DateTime.now(),
        active: true,
        id: userCreds.user!.uid);
    final actualUser = await connectUser(user);
    return actualUser;
  }

  Future<chat.User?> signUp(
      {required String name,
      required String username,
      required String email,
      required String password,
      String? photoUrl}) async {
    final userCreds = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (userCreds.user == null) {
      throw Exception("Unable to fetch user!");
    }

    final chat.User user = chat.User(
        name: name,
        email: email,
        username: username,
        publicKeyJwb: await encryptionViewmodel.generateKeys(),
        lastSeen: DateTime.now(),
        active: true,
        photoUrl: photoUrl,
        id: userCreds.user!.uid);

    await super.connectUser(user) == null
        ? () {
            signOut();
            throw Exception("Cannot connect user to Database!");
          }
        : null;
    return (await super.connectUser(user));
  }
}
