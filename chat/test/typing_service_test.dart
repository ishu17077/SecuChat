import 'package:chat/chat.dart';
import 'package:chat/src/services/typing/typing_notification_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'firebase_test.mocks.dart';
import 'helpers.dart';

void main() {
  late final MockFirebaseDatabase firebaseDatabase;
  late final MockDatabaseReference databaseReference;
  late final MockDatabaseEvent databaseEvent;
  late final MockDataSnapshot dataSnapshot;
  late final ITypingNotification sut;
  late final Stream<MockDatabaseEvent> stream;
  final User user = User.fromJSON(userMap);
  setUpAll(() {
    firebaseDatabase = MockFirebaseDatabase();
    databaseReference = MockDatabaseReference();
    databaseEvent = MockDatabaseEvent();
    dataSnapshot = MockDataSnapshot();
    stream = Stream.value(databaseEvent);
    sut = TypingNotification(firebaseDatabase);
    when(firebaseDatabase.ref(any)).thenReturn(databaseReference);
    when(
      databaseReference.child(any),
    ).thenAnswer((realInvocation) => databaseReference);
    when(databaseReference.onValue).thenAnswer((_) => stream);
    when(databaseEvent.snapshot).thenReturn(dataSnapshot);
    when(databaseEvent.type).thenReturn(DatabaseEventType.childAdded);
    when(dataSnapshot.value).thenReturn({user.id: "start"});
  });

  group("Should send and recieve typing events", () {
    test("Should send typing event", () async {
      await sut.send(TypingEvent.fromJSON(typingEventMap));
      verify(databaseReference.set(any)).called(1);
    });

    test("Should recieve typing events", () async {
      Stream<TypingEvent> typingEvents = sut.subscribe(user: user);
      verify(databaseReference.onValue).called(1);
      final event = await typingEvents.first;
      expect(event.from, user.id);
    });
  });
}
