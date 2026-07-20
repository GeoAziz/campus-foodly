import 'package:flutter/material.dart';

import '../../../constants.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _messages = <Map<String, String>>[
    {'role': 'bot', 'text': 'Hi! 👋 I\'m the Campus Foodly support bot. How can I help?'},
  ];
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(defaultPadding),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['role'] == 'bot';
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: defaultPadding),
                    padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.grey[200] : primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isBot ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input field
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: defaultPadding,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;

                    setState(() {
                      _messages.add({'role': 'user', 'text': text});
                      _controller.clear();
                      // TODO: Send to Claude API
                      _messages.add({
                        'role': 'bot',
                        'text': 'Thanks for your message! The AI support bot will respond here once Claude API is configured.'
                      });
                    });
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
