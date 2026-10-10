enum MessageType { text, image, audio, video, document, sticker, gif }

extension MessageTypeParsing on MessageType {
  String value() => this.name;

  static MessageType fromString(String messageType) {
    return MessageType.values.firstWhere(
      (value) => value.name == messageType,
      orElse: () => MessageType.text,
    );
  }
}
