import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/network/api_client.dart';
import '../../onboarding/providers/onboarding_provider.dart';

class MessageModel {
  final String text;
  final bool isUser;
  final String? praise;
  final String? correctedText;
  final String? tamilExplanation;
  final double? grammarScore;
  final double? fluencyScore;
  final double? confidenceScore;
  final DateTime timestamp;

  MessageModel({
    required this.text,
    required this.isUser,
    this.praise,
    this.correctedText,
    this.tamilExplanation,
    this.grammarScore,
    this.fluencyScore,
    this.confidenceScore,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'praise': praise,
    'correctedText': correctedText,
    'tamilExplanation': tamilExplanation,
    'grammarScore': grammarScore,
    'fluencyScore': fluencyScore,
    'confidenceScore': confidenceScore,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MessageModel.fromJson(Map<dynamic, dynamic> json) => MessageModel(
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    praise: json['praise'] as String?,
    correctedText: json['correctedText'] as String?,
    tamilExplanation: json['tamilExplanation'] as String?,
    grammarScore: json['grammarScore'] as double?,
    fluencyScore: json['fluencyScore'] as double?,
    confidenceScore: json['confidenceScore'] as double?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class ChatState {
  final List<MessageModel> messages;
  final String topic;
  final bool isListening;
  final bool isSpeaking;
  final bool isLoading;
  final int remainingTurns;
  final int retryTamilCount;
  final String? error;

  ChatState({
    required this.messages,
    required this.topic,
    this.isListening = false,
    this.isSpeaking = false,
    this.isLoading = false,
    required this.remainingTurns,
    this.retryTamilCount = 0,
    this.error,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    String? topic,
    bool? isListening,
    bool? isSpeaking,
    bool? isLoading,
    int? remainingTurns,
    int? retryTamilCount,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      topic: topic ?? this.topic,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isLoading: isLoading ?? this.isLoading,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      retryTamilCount: retryTamilCount ?? this.retryTamilCount,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final Ref _ref;

  ChatNotifier(this._ref)
    : super(
        ChatState(
          messages: [],
          topic: '',
          remainingTurns: 20 - HiveService.getUsedTurnsToday(),
        ),
      ) {
    _initTts();
  }

  void _initTts() {
    _tts.setLanguage("en-US");
    _tts.setSpeechRate(0.45); // Set speech rate slower for Tamil learners
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true, isListening: false);
    });

    _tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
      // Wait guard interval of 300ms, then start listening
      Future.delayed(const Duration(milliseconds: 300), () {
        if (state.remainingTurns > 0) {
          startSpeechToText();
        }
      });
    });

    _tts.setErrorHandler((msg) {
      state = state.copyWith(isSpeaking: false, error: "TTS Error: $msg");
    });
  }

  Future<void> startSession(String chosenTopic) async {
    _tts.stop();
    _speech.stop();

    state = ChatState(
      messages: [],
      topic: chosenTopic,
      remainingTurns: 20 - HiveService.getUsedTurnsToday(),
      isLoading: true,
    );

    final difficulty = HiveService.getDifficultyLevel();
    String greeting;
    try {
      greeting = await ApiClient.generateInitialGreeting(
        topic: chosenTopic,
        difficulty: difficulty,
      );
    } catch (e) {
      greeting = ApiClient.getMockInitialGreeting(chosenTopic, difficulty);
    }

    final initialMessage = MessageModel(
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [initialMessage],
      isLoading: false,
    );
    speak(greeting);
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> startSpeechToText() async {
    if (state.isSpeaking || state.isLoading) return;

    bool available = await _speech.initialize(
      onError: (val) {
        state = state.copyWith(isListening: false);
      },
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          state = state.copyWith(isListening: false);
        }
      },
    );

    if (available) {
      state = state.copyWith(isListening: true, error: null);
      _speech.listen(
        onResult: (val) {
          if (val.finalResult && val.recognizedWords.trim().isNotEmpty) {
            submitUserResponse(val.recognizedWords);
          }
        },
      );
    } else {
      state = state.copyWith(
        isListening: false,
        error:
            "Speech recognition not available. Please check microphone permissions.",
      );
    }
  }

  Future<void> stopSpeechToText() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> submitUserResponse(String text) async {
    if (state.isLoading) return;
    _speech.stop();

    final userMessage = MessageModel(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final conversationHistory = state.messages
          .map((m) => {'role': m.isUser ? 'User' : 'Coach', 'text': m.text})
          .toList();

      final evaluation = await ApiClient.evaluateResponse(
        utterance: text,
        topic: state.topic,
        difficulty: HiveService.getDifficultyLevel(),
        turnIndex: state.messages.length ~/ 2,
        conversationHistory: conversationHistory,
      );

      final isTamil = evaluation['isTamilOrMixed'] as bool? ?? false;

      if (isTamil) {
        final retryCount = state.retryTamilCount + 1;

        final updatedUserMessage = MessageModel(
          text: text,
          isUser: true,
          praise: evaluation['praise'] as String?,
          correctedText: evaluation['correctedText'] as String?,
          tamilExplanation: evaluation['tamilExplanation'] as String?,
          timestamp: userMessage.timestamp,
        );

        state = state.copyWith(
          messages: [
            ...state.messages.sublist(0, state.messages.length - 1),
            updatedUserMessage,
          ],
          retryTamilCount: retryCount,
          remainingTurns: 20 - HiveService.getUsedTurnsToday(),
        );

        String coachFeedback = evaluation['coachResponse'] as String;
        if (retryCount > 3) {
          coachFeedback =
              "No worries, let's reset. Tap one of the answers below or try saying 'Hello' in English.";
        }

        final aiMessage = MessageModel(
          text: coachFeedback,
          isUser: false,
          praise: evaluation['praise'] as String?,
          tamilExplanation: evaluation['tamilExplanation'] as String?,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
        );
        speak(coachFeedback);
      } else {
        // Successful English Turn
        final scores = evaluation['scores'] as Map<String, dynamic>?;
        final aiMessage = MessageModel(
          text: evaluation['coachResponse'] as String,
          isUser: false,
          praise: evaluation['praise'] as String?,
          correctedText: evaluation['correctedText'] as String?,
          tamilExplanation: evaluation['tamilExplanation'] as String?,
          grammarScore: scores != null
              ? (scores['grammar'] as num).toDouble()
              : null,
          fluencyScore: scores != null
              ? (scores['fluency'] as num).toDouble()
              : null,
          confidenceScore: scores != null
              ? (scores['confidence'] as num).toDouble()
              : null,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
          retryTamilCount: 0,
          remainingTurns: 20 - HiveService.getUsedTurnsToday(),
        );

        // Notify onboarding stats reload (for dashboard updating total sessions etc)
        _ref.read(onboardingProvider.notifier).incrementSessionCount();

        speak(evaluation['coachResponse'] as String);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> endAndSaveSession() async {
    if (state.messages.isEmpty) return;

    final turnsJson = state.messages.map((m) => m.toJson()).toList();
    await HiveService.saveSession(state.topic, turnsJson);

    _tts.stop();
    _speech.stop();
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
