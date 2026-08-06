import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/digital_saver_ai.dart';
import '../services/cambric_auth_service_v2.dart';
import '../models/health_models.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DigitalSaverAI _ai = DigitalSaverAI();
  
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAI();
    _messages.add({
      'role': 'assistant',
      'content': 'Hello! I\'m your Digital Saver AI assistant. I can help you understand your health data, answer questions about your Onyx watch, and provide personalized health insights. How can I help you today?',
    });
  }
  
  void _initializeAI() {
    // AI is ready to answer questions
    // Health data can be loaded from storage when needed
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messageController.clear();
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    // Process with AI (with delay to simulate thinking)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final response = _ai.ask(text);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _quickAsk(String question) {
    _messageController.text = question;
    _sendMessage();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Digital Saver AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'content': 'Hello! I\'m your Digital Saver AI assistant. I can help you understand your health data, answer questions about your Onyx watch, and provide personalized health insights. How can I help you today?',
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _quickActionChip('How\'s my heart?', Icons.favorite, () => _quickAsk("How's my heart rate?")),
                _quickActionChip('Sleep quality', Icons.bedtime, () => _quickAsk("How did I sleep?")),
                _quickActionChip('Steps today', Icons.directions_walk, () => _quickAsk("How many steps today?")),
                _quickActionChip('Watch status', Icons.watch, () => _quickAsk("Is my watch connected?")),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessage(msg['content']!, isUser);
              },
            ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text('AI is thinking...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything about your health...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _quickActionChip(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
      ),
    );
  }
  
  Widget _buildMessage(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
