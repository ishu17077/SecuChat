import 'package:chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'firebase_test.mocks.dart';
import 'helpers.dart';

void main() {
  late final MockFirebaseFirestore firebaseFirestore;
  late final MockCollectionReference collectionReference;
  late final MockDocumentChange documentChange;
  late final MockDocumentReference documentReference;
  late final MockQuerySnapshot querySnapshot;
  late final MockQuery query;
  late final MockDocumentSnapshot documentSnapshot;
  late final IUserService sut;
  late final User user;
  setUpAll(() {
    firebaseFirestore = MockFirebaseFirestore();
    collectionReference = MockCollectionReference();
    documentChange = MockDocumentChange();
    documentSnapshot = MockDocumentSnapshot();
    documentReference = MockDocumentReference();
    querySnapshot = MockQuerySnapshot();
    query = MockQuery();
    sut = UserService(firebaseFirestore);
    user = User.fromJSON(userMap);
    when(firebaseFirestore.collection("users")).thenReturn(collectionReference);
    when(collectionReference.doc(any)).thenAnswer((_) => documentReference);
    when(documentReference.get()).thenAnswer((_) async => documentSnapshot);
    when(documentSnapshot.data()).thenReturn(userMap);
    when(documentSnapshot.exists).thenReturn(true);
    when(query.get()).thenAnswer((_) async => querySnapshot);
    when(collectionReference.doc(any)).thenReturn(documentReference);
    when(documentReference.id).thenReturn(userMap["id"]);
  });

  group("Should connect and disconnect logged in user", () {
    test("Create or update logged in user", () async {
      final connectedUser = await sut.connect(user);
      verify(collectionReference.doc(any)).called(2);
      verify(documentReference.update(any)).called(1);
      expect(connectedUser.id, user.id);
    });

    test("Should disconnect user", () async {
      await sut.disconnect(user);

      verify(collectionReference.doc(any)).called(1);
      verify(documentReference.update(any)).called(1);
    });

    test("Should fetch online users", () async {
      when(
        collectionReference.where(any, isEqualTo: anyNamed("isEqualTo")),
      ).thenReturn(query);
      when(querySnapshot.docChanges).thenReturn([documentChange]);
      when(documentChange.doc).thenReturn(documentSnapshot);
      when(documentSnapshot.data()).thenReturn(userMap);
      List<User> activeUsers = await sut.online();

      expect(activeUsers.first.id, user.id);
    });
  });
}
