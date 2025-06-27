import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../models/message_model.dart';
import '../services/ai_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatUser _currentUser =
  ChatUser(id: '1', firstName: 'You');
  final ChatUser _aiChatbot =
  ChatUser(id: '2', firstName: 'AI Assistant', profileImage: 'https://cdn-icons-png.flaticon.com/512/8943/8943261.png');

  final List<ChatMessage> _messages = <ChatMessage>[]; // Initialize as empty
  final GeminiAIService _geminiService = GeminiAIService();
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Initialize messages here if they haven't been initialized yet
    if (_messages.isEmpty) {
      _messages.insert(
        0,
        ChatMessage(
          user: _aiChatbot,
          createdAt: DateTime.now(),
          text: l10n.helloMessage,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          l10n.aiChatbot,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: DashChat(
        currentUser: _currentUser,
        onSend: (ChatMessage m) {
          setState(() {
            _messages.insert(0, m); // Add user message
          });
          // Call your AI integration here
          _getAiResponse(m.text);
        },
        messages: _messages,
        inputOptions: InputOptions(
          // 'alwaysShowSendButton' is not a valid parameter in newer versions.
          // The send button visibility is typically managed by DashChat 2 automatically.
          sendButtonBuilder: (onSend) {
            return FloatingActionButton(
              onPressed: onSend,
              mini: true,
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              child: const Icon(Icons.send, color: Colors.white),
            );
          },
          inputDecoration: InputDecoration(
            hintText: l10n.typeMessageHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          ),
        ),
        messageOptions: MessageOptions(
          currentUserContainerColor: Colors.blue[100]!, // Use ! for null assertion
          containerColor: Colors.grey[200]!,       // Use ! for null assertion
          currentUserTextColor: Colors.blue[900],
          textColor: Colors.black87,
          showTime: true,
          // 'showCurrentUserTime' is not a valid parameter in newer versions.
          // 'showTime' handles time display for both users.
        ),
        typingUsers: [],
      ),
    );
  }

  Future<void> _getAiResponse(String userMessage) async {
    setState(() {
      _isTyping = true; // Show typing indicator
    });

    try {
      // For streaming responses (better user experience)
      final responseStream = _geminiService.getGeminiStreamResponse(userMessage);
      String fullResponse = '';
      ChatMessage? currentAiMessage; // To update the existing message in DashChat

      // Check if the last message is from the AI, to update it in place for streaming
      if (_messages.isNotEmpty && _messages.first.user.id == _aiChatbot.id) {
        currentAiMessage = _messages.first; // Assume AI's previous message if exists
        setState(() {
          currentAiMessage!.text = ''; // Clear previous text to build stream
        });
      } else {
        // If not, create a new message for the AI's response
        currentAiMessage = ChatMessage(user: _aiChatbot, createdAt: DateTime.now(), text: '');
        setState(() {
          _messages.insert(0, currentAiMessage!);
        });
      }

      await for (final chunk in responseStream) {
        setState(() {
          fullResponse += chunk;
          currentAiMessage!.text = fullResponse; // Update message in UI
        });
      }
    } catch (e) {
      if (e.toString().contains("Unhandled format for Content: {role: model}")) {
        // Ignore this specific error
        print("Ignored error: $e");
      } else {
        // Handle other errors
        print("Error getting AI response: $e");
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              user: _aiChatbot, // The AI chatbot user
              createdAt: DateTime.now(),
              text: "Error: Could not get AI response. Please try again. ($e)", // Include error details
            ),
          );
        });
      }
    } finally {
      // Always set _isTyping to false after the response (or error)
      setState(() {
        _isTyping = false;
      });
    }
  }
}