class Message {
  final String text;
  final bool isUser; // true if sent by user, false if from AI

  Message({required this.text, required this.isUser});
}