import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import 'gemini_api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chatbot App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF3FFF00)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/splash1.jpg'), // Replace with your image path
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiApiService geminiService = GeminiApiService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "message": userInput});
      _isLoading = true;
    });

    _controller.clear();

    String geminiResponse = await geminiService.getGeminiResponse(userInput);
    geminiResponse = _sanitizeText(geminiResponse);

    setState(() {
      _messages.add({"role": "bot", "message": geminiResponse});
      _isLoading = false;
    });
  }

  String _sanitizeText(String text) {
    return text.replaceAll(RegExp(r'\*+'), '').trim();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index); // Remove user message
      if (index < _messages.length && _messages[index]["role"] == "bot") {
        _messages.removeAt(index); // Remove corresponding bot response
      }
    });
  }

  void _regenerateMessage(int index) async {
    setState(() {
      _isLoading = true;
    });

    final userInput = _messages[index - 1]["message"]!;
    final newResponse = await geminiService.getGeminiResponse(userInput);

    setState(() {
      _messages[index]["message"] = _sanitizeText(newResponse);
      _isLoading = false;
    });
  }

  Future<void> _showDeleteDialog(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Do you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteMessage(index);
    }
  }

  Future<void> _showRegenerateDialog(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Regenerate Response"),
        content: const Text("Do you want to regenerate this response?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _regenerateMessage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'KAPIL ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3FFF00),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
           Expanded(
  child: ListView.builder(
    itemCount: _messages.length,
    itemBuilder: (context, index) {
      final message = _messages[index];
      bool isUserMessage = message['role'] == 'user';
      String messageText = message['message']!;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(
          mainAxisAlignment:
              isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUserMessage) const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUserMessage ? Colors.white : const Color(0xFF3FFF00),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isUserMessage
                        ? const Radius.circular(12)
                        : const Radius.circular(0),
                    bottomRight: isUserMessage
                        ? const Radius.circular(0)
                        : const Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        messageText,
                        style: TextStyle(
                          fontSize: 16,
                          color: isUserMessage
                              ? const Color(0xFF3FFF00)
                              : Colors.black,
                        ),
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                      onPressed: () => _copyToClipboard(messageText),
                    ),
                    if (isUserMessage)
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 18, color: Color.fromARGB(255, 0, 0, 0)),
                        onPressed: () => _showDeleteDialog(index),
                      ),
                    if (!isUserMessage)
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            size: 18, color: Color.fromARGB(255, 245, 245, 246)),
                        onPressed: () => _showRegenerateDialog(index),
                      ),
                  ],
                ),
              ),
            ),
            if (isUserMessage) const SizedBox(width: 10),
          ],
        ),
      );
    },
  ),
),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
Padding(
  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0), // Add more bottom padding
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Type a message...",
            hintStyle: const TextStyle(color: Color(0xFF3FFF00)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFF3FFF00)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFF3FFF00)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFF3FFF00), width: 2.0),
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.send),
        onPressed: _sendMessage,
        color: const Color(0xFF3FFF00),
      ),
    ],
  ),
),

          ],
        ),
      ),
    );
  }
} 