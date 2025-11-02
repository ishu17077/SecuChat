import 'package:cloud_firestore/cloud_firestore.dart';

enum Typing { start, stop }

extension TypingParser on Typing {
  String value() => this.name;

  static fromString(String event) {
    return Typing.values.firstWhere(
      (element) => element.name == event,
      orElse: () => Typing.stop,
    );
  }
}

class TypingEvent {
  final String from;
  final String to;
  final Typing event;
  final DateTime time;
  String get id => _id;
  late String _id;

  TypingEvent({
    required this.from,
    required this.to,
    required this.event,
    required this.time,
  });

  Map<String, dynamic> toJSON() => {
    "from": from,
    "to": to,
    "time": time,
    "event": event.value(),
  };

  factory TypingEvent.fromJSON(Map<String, dynamic> map) {
    TypingEvent typingEvent = TypingEvent(
      from: map["from"]!,
      to: map["to"]!,
      time: (map["time"] is DateTime
          ? map["time"]
          : map["time"] is Timestamp
          ? (map["time"] as Timestamp).toDate()
          : DateTime.parse(map["time"]!)),
      event: TypingParser.fromString(map["event"] ?? "stop"),
    );
    typingEvent._id = map["id"];
    return typingEvent;
  }
}
