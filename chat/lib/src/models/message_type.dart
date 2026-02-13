enum MessageType { message, image, audio, document }

extension MessageTypeParsing on MessageType {
  String value() => this.name;

  static MessageType fromString(String messageType) {
    return MessageType.values.firstWhere(
      (value) => value.name == messageType,
      orElse: () => MessageType.message,
    );
  }
}
