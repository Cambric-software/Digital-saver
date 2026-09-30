import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/digital_saver_ai.dart';
import '../services/ble_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DigitalSaverAI _ai;

  // AI Personality & Settings
  String _personalityTone = 'Empathetic & Supportive';
  String _medicalFocus = 'Cardiovascular & Vitals';
  String _responseLength = 'Balanced & Concise';
  String _preferredLanguage = 'English (Auto-detect)';
  final TextEditingController _customInstructionsController = TextEditingController();
  bool _includeWatchTelemetry = true;
  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ai = DigitalSaverAI();
    _loadAiSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAI();
    });
  }

  Future<void> _loadAiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _personalityTone = prefs.getString('ai_tone') ?? 'Empathetic & Supportive';
      _medicalFocus = prefs.getString('ai_focus') ?? 'Cardiovascular & Vitals';
      _responseLength = prefs.getString('ai_length') ?? 'Balanced & Concise';
      _preferredLanguage = prefs.getString('ai_language') ?? 'English (Auto-detect)';
      _customInstructionsController.text = prefs.getString('ai_custom_instructions') ?? '';
      _includeWatchTelemetry = prefs.getBool('ai_include_telemetry') ?? true;
      _loadingSettings = false;
    });
  }

  Future<void> _saveAiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_tone', _personalityTone);
    await prefs.setString('ai_focus', _medicalFocus);
    await prefs.setString('ai_length', _responseLength);
    await prefs.setString('ai_language', _preferredLanguage);
    await prefs.setString('ai_custom_instructions', _customInstructionsController.text.trim());
    await prefs.setBool('ai_include_telemetry', _includeWatchTelemetry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Personality & Instructions Saved!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _initAI() {
    _syncWatchData();
    if (_ai.chatHistory.isEmpty) {
      final greeting = _ai.greeting();
      _ai.chatHistory.add(AiMessage(role: MessageRole.assistant, text: greeting));
    }
  }

  void _syncWatchData() {
    if (!_includeWatchTelemetry) return;
    final ble = context.read<BleService>();
    _ai.setWatchStatus(
      battery: ble.batteryLevel > 0 ? '${ble.batteryLevel}%' : null,
      firmware: ble.watchInfo.fw.isNotEmpty ? ble.watchInfo.fw : null,
      connected: ble.isConnected,
    );
    if (ble.heartRate.bpm > 0) _ai.setHeartRate(ble.heartRate);
    if (ble.oxygen.spO2 > 0) _ai.setOxygen(ble.oxygen);
    _ai.setBloodPressure(ble.bloodPressure);
    _ai.setActivity(ble.activity);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _ai.isThinking) return;
    _messageController.clear();

    _syncWatchData();

    String enrichedPrompt = text;
    final customNotes = _customInstructionsController.text.trim();
    if (customNotes.isNotEmpty || _personalityTone != 'Empathetic & Supportive') {
      enrichedPrompt = '[Tone: $_personalityTone | Focus: $_medicalFocus | Lang: $_preferredLanguage'
          '${customNotes.isNotEmpty ? ' | Instructions: $customNotes' : ''}]\n\n$text';
    }

    await _ai.ask(enrichedPrompt);
    _scrollToBottom();
  }

  void _quickAsk(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _customInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Digital Saver AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  'Cambric Medical & Wellness Relay',
                  style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Clear Chat',
            onPressed: () {
              setState(() {
                _ai.chatHistory.clear();
                _ai.chatHistory.add(AiMessage(
                  role: MessageRole.assistant,
                  text: 'Chat history cleared. How can I assist you with your health today?',
                ));
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
            Tab(icon: Icon(Icons.tune_outlined), text: 'AI Personality & Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return ListenableBuilder(
      listenable: _ai,
      builder: (context, _) {
        return Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('How is my heart rate today?', Icons.favorite_border),
                  _chip('Explain my sleep quality', Icons.bedtime_outlined),
                  _chip('Give me today activity goal', Icons.directions_walk),
                  _chip('Check my Veyro sensor status', Icons.watch_outlined),
                ],
              ),
            ),
            Expanded(
              child: _ai.chatHistory.isEmpty
                  ? const Center(child: Text('Start a conversation with Digital Saver AI'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _ai.chatHistory.length,
                      itemBuilder: (context, index) {
                        final msg = _ai.chatHistory[index];
                        final isUser = msg.role == MessageRole.user;
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                            ? AppColors.primary
                            : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E293B)
                                : AppColors.surface),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: isUser
                                ? Colors.white
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_ai.isThinking)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Digital Saver AI is thinking...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.surface,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask about vitals, sleep, or symptoms...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: AppColors.primary),
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () => _quickAsk(text),
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_loadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Personality & Tone',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how Digital Saver AI interacts and speaks with you.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _personalityTone,
                  decoration: const InputDecoration(
                    labelText: 'Tone of Voice',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'Empathetic & Supportive',
                    'Clinical & Medical (Doctor-like)',
                    'Direct & Fact-Only',
                    'Motivational Fitness Coach',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _personalityTone = v);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _medicalFocus,
                  decoration: const InputDecoration(
                    labelText: 'Primary Health Focus',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'Cardiovascular & Vitals',
                    'Sleep & Stress Recovery',
                    'Athletic Training & Steps',
                    'General Wellness & Ergonomics',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _medicalFocus = v);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _preferredLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Conversation Language',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'English (Auto-detect)',
                    'العربية (Egyptian Arabic / Fusha)',
                    'Bilingual (English + Arabic terms)',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _preferredLanguage = v);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom Health Notes & Instructions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tell the AI about your chronic conditions, allergies, or how you want it to talk to you.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customInstructionsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'e.g., I have mild asthma. Speak simply. Always warn me if resting HR exceeds 110.',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include live watch vitals in prompts', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Sends current HR, steps, and battery to the AI relay', style: TextStyle(fontSize: 11)),
                  value: _includeWatchTelemetry,
                  onChanged: (v) => setState(() => _includeWatchTelemetry = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _saveAiSettings,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Personality & Instructions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
