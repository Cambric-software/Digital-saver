import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/digital_saver_ai.dart';
import '../services/ble_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DigitalSaverAI _ai;
  bool _aiReady = false;

  @override
  void initState() {
    super.initState();
    _ai = DigitalSaverAI();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAI();
    });
  }

  void _initAI() {
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

    // Show greeting
    final greeting = _ai.greeting();
    _ai.chatHistory.add(AiMessage(role: MessageRole.assistant, text: greeting));

    setState(() => _aiReady = true);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _ai.isThinking) return;
    _messageController.clear();

    // Refresh live watch data before asking
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

    await _ai.ask(text);
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ai,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Digital Saver AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  GeminiConfig.apiKey.isNotEmpty ? 'Powered by Gemini' : 'Configure API key for full AI',
                  style: TextStyle(
                    fontSize: 10,
                    color: GeminiConfig.apiKey.isNotEmpty ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            ]),
            actions: [
              if (GeminiConfig.apiKey.isEmpty)
                IconButton(
                  icon: const Icon(Icons.key_outlined, color: AppColors.warning),
                  tooltip: 'API key not set',
                  onPressed: _showApiKeyHelp,
                ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear conversation',
                onPressed: () {
                  _ai.clearConversation();
                  _initAI();
                },
              ),
            ],
          ),
          body: Column(children: [
            // Quick-action chips
            Container(
              height: 52,
              color: AppColors.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _chip('How\'s my heart?', Icons.favorite, () => _quickAsk("How's my heart rate right now?")),
                  _chip('My sleep', Icons.bedtime, () => _quickAsk('How did I sleep last night?')),
                  _chip('Step goal', Icons.directions_walk, () => _quickAsk('Am I close to my step goal today?')),
                  _chip('Watch help', Icons.watch, () => _quickAsk('Help me troubleshoot my Veyro watch.')),
                  _chip('Improve HRV', Icons.show_chart, () => _quickAsk('How can I improve my HRV?')),
                  _chip('What is SpO2?', Icons.air, () => _quickAsk('What does SpO2 mean and why does it matter?')),
                ],
              ),
            ),
            const Divider(height: 1),

            // Message list
            Expanded(
              child: !_aiReady
                  ? const Center(child: CircularProgressIndicator())
                  : _ai.chatHistory.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          itemCount: _ai.chatHistory.length,
                          itemBuilder: (ctx, i) => _MessageBubble(msg: _ai.chatHistory[i]),
                        ),
            ),

            // Thinking indicator
            if (_ai.isThinking)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                alignment: Alignment.centerLeft,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text('Gemini is thinking...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ]),
                  ),
                ]),
              ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about your health…',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: _ai.isThinking ? const LinearGradient(colors: [Colors.grey, Colors.grey]) : AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _ai.isThinking ? null : _sendMessage,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _chip(String label, IconData icon, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      avatar: Icon(icon, size: 14, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      onPressed: onTap,
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
  );

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
      ),
      const SizedBox(height: 16),
      const Text('Digital Saver AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Ask anything about your health,\nyour Veyro watch, or wellness tips.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
    ]),
  );

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.key, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Set up Gemini API Key'),
        ]),
        content: const SingleChildScrollView(
          child: Text(
            'To enable full Gemini AI responses:\n\n'
            '1. Go to https://aistudio.google.com/ and get a free API key.\n\n'
            '2. Run the app with:\n'
            '   flutter run --dart-define=GEMINI_API_KEY=your_key\n\n'
            '3. Or set GeminiConfig.apiKey directly in lib/services/gemini_service.dart.\n\n'
            'Without a key, the AI uses a local fallback with basic responses.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: isUser ? null : AppShadows.card,
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
              child: const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
