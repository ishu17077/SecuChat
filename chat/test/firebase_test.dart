import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' hide Query;
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<DocumentChange<Map<String, dynamic>>>(),
  MockSpec<FirebaseDatabase>(),
  MockSpec<DatabaseReference>(),
  MockSpec<DatabaseEvent>(),
  MockSpec<DataSnapshot>(),
])
void main() {}

//! run mockito: flutter pub run build_runner build
