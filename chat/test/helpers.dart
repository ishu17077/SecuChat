import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Map<String, dynamic> userMap = {
  "name": "Dabua",
  "id": "dasdsd",
  "username": "dasdsd",
  "email": "dwddw@gmkef.com",
  "photo_url":
      "https://images.unsplash.com/photo-1603320045158-61d0dc0fbb33?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
  "last_seen": DateTime.now(),
  "active": false,
};

final Message message = Message(
  from: "2edwd",
  to: "dasdsd",
  contents: "Hey Baby!",
  time: DateTime.now(),
);

final Map<String, dynamic> messageMapFromServer = {
  "id": "dwdwdwd",
  "from": "2edwd",
  "to": userMap["id"],
  "contents": "Hey Baby!",
  "time": Timestamp.now(),
};

final Map<String, dynamic> receiptMap = {
  "message_id": "dwdwd",
  "recipient_id": userMap["id"],
  "id": "sdsdsdwdwdwd",
  "status": "sent",
  "time": Timestamp.now(),
};

final Map<String, dynamic> typingEventMap = {
  "id": "sdhasjhdhksajdjhlas",
  "to": "dasdsd",
  "from": "sdhichaskjchzak",
  "event": "start",
  "time": DateTime.now(),
};
