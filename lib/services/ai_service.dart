import 'package:google_generative_ai/google_generative_ai.dart';

// IMPORTANT: Replace with your actual API key
// For production, use environment variables or a secure backend
const String _GEMINI_API_KEY = 'AIzaSyA-17gjtuzrkLq4eoKkjjL5cWQSvGVCG70';

class GeminiAIService {
  late final GenerativeModel _model;
  late ChatSession _chatSession; // Declare a ChatSession

  GeminiAIService() {
    // Initialize the GenerativeModel
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite', // Using gemini-pro, or 'gemini-1.5-flash-latest' as discussed
      apiKey: _GEMINI_API_KEY,
    );

    final history = [
      Content(
        'user',
        [
          TextPart('now you are a travel guide assistant, you will just answers and recommendations for travelling related questions'),
        ],
      ),
      Content(
        'model',
        [
          TextPart('**Formulating the Persona**\n\nI\'ve successfully identified the user\'s primary need: a travel guide assistant persona. Now, I\'m fleshing out its core attributes. I\'m focusing on defining its role—a travel guide assistant—and its primary function: providing travel-related answers and recommendations. I will make sure to offer great recommendations.\n\n\n**Clarifying the Persona**\n\nI\'m now zeroing in on the finer points of the travel guide persona. My focus is now on the character\'s tone and scope. I\'m aiming for a helpful, enthusiastic, and knowledgeable voice, like a real travel planner. I want to be strictly travel-focused, as requested, delivering answers that are clear, concise, and easy to digest. I\'m exploring how to best format responses to match a traveler\'s expectations.\n\n\n**Refining Confirmation Message**\n\nI\'ve worked on the confirmation message, crafting several drafts. The most recent version sounds enthusiastic and welcoming. I\'m now ready to adopt the travel guide assistant persona, confirming understanding of the instructions and inviting the user to start asking travel-related questions. I\'m prepared to provide insightful answers and tailored recommendations for their travel planning.\n\n\n**Defining Confirmation Draft**\n\nI\'ve refined the final confirmation message.  It\'s now more engaging, friendly, and travel-oriented, and it welcomes questions. I\'ve considered several drafts and opted for one that is concise but still enthusiastic. This prepares me to adopt the persona and guide users. I am set to assist with all travel-related questions.\n\n\n'),
          TextPart('Excellent! I\'ve got my virtual passport ready and my guidebooks open.\n\nConsider me your personal travel guide assistant. I\'m here to provide helpful answers and tailored recommendations for all your travel questions.\n\nWhether you\'re dreaming of a destination, planning the logistics, or looking for hidden gems, just ask away.\n\nWhere are we off to first?'),
        ],
      ),
    ];

    // Initialize the chat session with optional initial history
    _chatSession = _model.startChat(history: history ?? []);
  }

  Future<String> getGeminiResponse(String prompt) async {
    try {
      // Use the chat session to send messages
      // This already correctly takes a single Content object
      final response = await _chatSession.sendMessage(Content.text(prompt));

      if (response.text != null) {
        return response.text!;
      } else {
        return "Sorry, I couldn't generate a response.";
      }
    } catch (e) {
      print("Error getting Gemini response: $e");
      return "An error occurred while connecting to the AI. Please try again.";
    }
  }

  // You can also add stream support for real-time typing effect
  Stream<String> getGeminiStreamResponse(String prompt) {
    try {
      return _chatSession.sendMessageStream(Content.text(prompt)).map((event) {
        return event.text ?? '';
      });
    } catch (e) {
      print("Error streaming Gemini response: $e");
      return Stream.value("An error occurred while streaming the AI response.");
    }
  }

  // Method to get current chat history (useful for saving or debugging)
  List<Content> getCurrentChatHistory() {
    return _chatSession.history.toList();
  }
}