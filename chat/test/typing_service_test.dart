import 'package:chat/chat.dart';
import 'package:chat/src/services/typing/typing_notification_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'firebase_test.mocks.dart';
import 'helpers.dart';

void main() {
  late final MockFirebaseFirestore firebaseFirestore;
  late final MockCollectionReference collectionReference;
  late final MockDocumentReference docRef;
  late final MockDocumentChange docChange;
  late final MockDocumentSnapshot documentSnapshot;
  late final MockQuery query;
  late final MockQuerySnapshot querySnapshot;
  late final ITypingNotification sut;
  final User user = User.fromJSON(userMap);
  setUpAll(() {
    firebaseFirestore = MockFirebaseFirestore();
    collectionReference = MockCollectionReference();
    docRef = MockDocumentReference();
    docChange = MockDocumentChange();
    documentSnapshot = MockDocumentSnapshot();
    querySnapshot = MockQuerySnapshot();
    query = MockQuery();
    sut = TypingNotification(firebaseFirestore);
    when(
      firebaseFirestore.collection("typing_events"),
    ).thenReturn(collectionReference);
    when(
      collectionReference.add(any),
    ).thenAnswer((realInvocation) async => docRef);

    when(collectionReference.doc(any)).thenReturn(docRef);
    when(
      collectionReference.orderBy(any, descending: anyNamed('descending')),
    ).thenReturn(query);
    when(
      query.orderBy(any, descending: anyNamed('descending')),
    ).thenReturn(query);
    when(
      collectionReference.where(
        "from",
        arrayContains: anyNamed("arrayContains"),
      ),
    ).thenReturn(query);
    when(query.where("to", isEqualTo: user.id)).thenReturn(query);
    when(
      query.snapshots(),
    ).thenAnswer((realInvocation) => Stream.value(querySnapshot));
    when(docChange.type).thenReturn(DocumentChangeType.added);
    when(querySnapshot.docChanges).thenReturn([docChange]);
    when(docChange.doc).thenReturn(documentSnapshot);
    when(documentSnapshot.data()).thenReturn(typingEventMap);
  });

  group("Should send and recieve typing events", () {
    test("Should send typing event", () async {
      when(documentSnapshot.id).thenReturn(user.id!);
      final bool isSent = await sut.send(TypingEvent.fromJSON(typingEventMap));
      verify(collectionReference.add(any)).called(1);
      expect(isSent, true);
    });

    test("Should recieve typing events", () async {
      Stream<TypingEvent> typingEvents = sut.subscribe(user: user);
      TypingEvent typingEvent = await typingEvents.first;
      expect(typingEvent.id, typingEventMap["id"]);
    });
  });
}
