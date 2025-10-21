import 'package:chat/chat.dart';
import 'package:chat/src/services/encryption/encryption_service.dart';
import 'package:chat/src/services/message/message_service_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'firebase_test.mocks.dart';
import 'helpers.dart';

void main() {
  late final MockFirebaseFirestore firebaseFirestore;
  late final MockCollectionReference collectionRef;
  late final MockDocumentReference docRef;
  late final MockQuerySnapshot querySnapshot;
  late final IEncryption encryption;
  late final IMessageService messageService;
  late final MockQuery query;
  late final MockDocumentChange documentChange;
  late final MockQueryDocumentSnapshot documentSnapshot;

  setUpAll(() {
    firebaseFirestore = MockFirebaseFirestore();
    collectionRef = MockCollectionReference();
    docRef = MockDocumentReference();
    querySnapshot = MockQuerySnapshot();
    documentChange = MockDocumentChange();
    query = MockQuery();
    encryption = EncryptionService();
    documentSnapshot = MockQueryDocumentSnapshot();
    messageService = MessageService(firebaseFirestore);
    when(firebaseFirestore.collection("messages")).thenReturn(collectionRef);
    when(query.snapshots()).thenAnswer((realInvocation) {
      return Stream.value(querySnapshot);
    });
    when(collectionRef.doc(any)).thenReturn(docRef);
    when(
      collectionRef.where(any, isEqualTo: anyNamed("isEqualTo")),
    ).thenReturn(query);
  });

  group("Send and recieve messages", () {
    test("Should send message", () async {
      when(collectionRef.add(any)).thenAnswer((realInv) async => docRef);

      messageService.send(message);

      verify(collectionRef.add(message.toJSON())).called(1);
    });

    test("Should recieve messages", () async {
      when(
        querySnapshot.docChanges,
      ).thenAnswer((realInvocation) => [documentChange]);
      when(documentChange.type).thenReturn(DocumentChangeType.added);
      when(documentChange.doc).thenReturn(documentSnapshot);
      when(documentSnapshot.data()).thenReturn(messageMapFromServer);

      final messageStream = messageService.messages(
        activeUser: User.fromJSON(userMap),
      );
      final message = await messageStream.first;
      expect(message.id, messageMapFromServer["id"]);
    });
  });
}
