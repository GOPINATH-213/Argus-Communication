import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({super.key});

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _endSession() async {
    final notifier = ref.read(chatProvider.notifier);
    await notifier.endAndSaveSession();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Auto scroll to bottom when new messages arrive
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _endSession();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _endSession,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatState.topic,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '${chatState.remainingTurns} turns left today',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _endSession,
              child: const Text('End', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Column(
          children: [
            // Error Display Card
            if (chatState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.red.shade900,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Message Bubble list
            Expanded(
              child: chatState.messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accentGold),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        return _buildChatBubble(msg);
                      },
                    ),
            ),

            // Loading / Evaluating Indicator
            if (chatState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGold),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      chatState.messages.isEmpty
                          ? 'Starting session...'
                          : 'Evaluating grammar and vocabulary...',
                      style: TextStyle(color: AppTheme.accentGold.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Speech Control Bar
            _buildSpeechControlPanel(chatState),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(MessageModel msg) {
    final isUser = msg.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? AppTheme.secondaryNavy : AppTheme.primaryNavy;
    final textColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                IconButton(
                  icon: Icon(
                    msg.isUser ? Icons.volume_mute : Icons.volume_up,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                  onPressed: () => ref.read(chatProvider.notifier).speak(msg.text),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isUser ? Colors.transparent : AppTheme.secondaryNavy.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          // User Correction and Review Trigger
          if (isUser && (msg.correctedText != null || msg.praise != null)) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showCorrectionDetailsSheet(context, msg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppTheme.accentGold, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'View coach suggestions & Tamil guide',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeechControlPanel(ChatState chatState) {
    final isListening = chatState.isListening;
    final isSpeaking = chatState.isSpeaking;

    String instruction = "Speak or type in English or Tamil";
    if (isListening) instruction = "Listening... Speak now";
    if (isSpeaking) instruction = "Coach is speaking...";
    if (chatState.isLoading) instruction = "Evaluating...";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.secondaryNavy.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            instruction,
            style: TextStyle(
              fontSize: 13,
              color: isListening ? AppTheme.accentGold : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Mic Button
              GestureDetector(
                onTap: () {
                  if (chatState.isLoading) return;
                  final notifier = ref.read(chatProvider.notifier);
                  if (isListening) {
                    notifier.stopSpeechToText();
                  } else if (isSpeaking) {
                    notifier.stopSpeaking();
                  } else {
                    notifier.startSpeechToText();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? AppTheme.accentGold : AppTheme.secondaryNavy,
                    boxShadow: [
                      BoxShadow(
                        color: isListening
                            ? AppTheme.accentGold.withValues(alpha: 0.4)
                            : AppTheme.secondaryNavy.withValues(alpha: 0.2),
                        blurRadius: isListening ? 12 : 6,
                        spreadRadius: isListening ? 2 : 1,
                      )
                    ],
                  ),
                  child: Icon(
                    isListening
                        ? Icons.mic
                        : isSpeaking
                            ? Icons.volume_off
                            : Icons.mic_none,
                    size: 24,
                    color: isListening ? AppTheme.primaryNavy : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text Field
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !chatState.isLoading && !isListening,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Type in English or Tamil...",
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    fillColor: AppTheme.secondaryNavy.withValues(alpha: 0.4),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppTheme.accentGold, width: 1),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      ref.read(chatProvider.notifier).submitUserResponse(val.trim());
                      _textController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Send Button
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.accentGold),
                onPressed: chatState.isLoading || isListening
                    ? null
                    : () {
                        final val = _textController.text;
                        if (val.trim().isNotEmpty) {
                          ref.read(chatProvider.notifier).submitUserResponse(val.trim());
                          _textController.clear();
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCorrectionDetailsSheet(BuildContext context, MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryNavy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.accentGold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Coach Feedback',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Praise section
                  if (msg.praise != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.celebration, color: AppTheme.successGreen, size: 18),
                              SizedBox(width: 8),
                              Text('Praise:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(msg.praise!, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Original and Corrected comparison
                  const Text('Your sentence:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 12),

                  if (msg.correctedText != null && msg.correctedText != msg.text) ...[
                    const Text('Polished English:', style: TextStyle(color: AppTheme.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      msg.correctedText!,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tamil Explanation
                  if (msg.tamilExplanation != null) ...[
                    const Text('Grammar Rule (தமிழ் விளக்கம்):', style: TextStyle(color: AppTheme.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryNavy.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondaryNavy.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        msg.tamilExplanation!,
                        style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Scores Row
                  if (msg.grammarScore != null) ...[
                    const Text('Conversation Metrics:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricIndicator('Grammar', msg.grammarScore!, AppTheme.accentGold),
                        _buildMetricIndicator('Fluency', msg.fluencyScore!, AppTheme.successGreen),
                        _buildMetricIndicator('Confidence', msg.confidenceScore!, AppTheme.alertOrange),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricIndicator(String label, double score, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: score / 100,
                backgroundColor: AppTheme.secondaryNavy,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 5,
              ),
            ),
            Text(
              score.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}
