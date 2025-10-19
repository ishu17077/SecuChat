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
  String get id => _id;
  late String _id;

  TypingEvent({required this.from, required this.to, required this.event});

  Map<String, dynamic> toJSON() => {
    "from": from,
    "to": to,
    "event": event.value(),
  };

  factory TypingEvent.fromJSON(Map<String, dynamic> map) {
    TypingEvent typingEvent = TypingEvent(
      from: map["from"]!,
      to: map["to"]!,
      event: TypingParser.fromString(map["event"] ?? "stop"),
    );
    typingEvent._id = map["id"];
    return typingEvent;
  }
}
