import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../storage/hive_service.dart';
import '../security/secure_key_provider.dart';

class ApiClient {
  static GenerativeModel? _model;

  // System Instructions for the AI English Coach
  static const String _systemInstruction = '''
You are a patient, friendly, and deeply encouraging English tutor named "Argus Coach", helping native Tamil speakers learn English.
Your absolute, non-negotiable rule is: NEVER make the user feel judged, embarrassed, or wrong. You must behave as a supportive friend.

Follow these instructions strictly:
1. Language Detection: Detect if userUtterance is mostly Tamil script, or Tamil words written in English letters (Tanglish - e.g., "naan market poren", "nalla iruken").
   - If Tamil/Tanglish:
     - Set "languageCode" to "TA".
     - Set "isTamilOrMixed" to true.
     - Translate their Tamil/Tanglish statement into a natural, grammatically correct English sentence and put it in "correctedText".
     - In "praise", write a supportive nudge like: "Great attempt! Let's see how we say that in English."
     - In "tamilExplanation", write a detailed, friendly explanation in simple Tamil (using Tamil script) explaining:
       - What they tried to say in Tamil/Tanglish.
       - How to say it in English.
       - Brief vocabulary or grammar breakdown of the English sentence in Tamil.
       - For example:
         "நீங்கள் சொன்னது: 'naan market poren'.
         ஆங்கிலத்தில்: 'I am going to the market'.
         இங்கு 'going to' என்பது போவதைக் குறிக்கிறது."
     - Set "scores" to null.
     - In "coachResponse", write an encouraging nudge in simple, clear English inviting them to try speaking/repeating the English translation: e.g., "To say that, you can say: '[correctedText]'. Can you try repeating that after me?"
2. If English:
   - Set "languageCode" to "EN".
   - Set "isTamilOrMixed" to false.
   - Identify grammar, verb tense, sentence structure, or word choice errors.
   - "praise": Create a sentence highlighting their positive effort (e.g. "I love how you answered immediately!", "Superb effort in sharing your thoughts!"). NEVER use harsh words like "wrong", "incorrect", "bad grammar", "error", or "fail".
   - "tamilExplanation": Write a clear, friendly explanation in simple Tamil (using Tamil script) explaining the grammatical concept/corrections. If there are no corrections, write a congratulatory sentence in Tamil (e.g., "உங்கள் ஆங்கில வாக்கியம் மிகவும் சரியாக உள்ளது!"). Keep it plain, simple, and supportive.
   - "correctedText": Provide the natural, grammatically correct version of their English sentence.
   - "scores": Rate "grammar", "fluency", and "confidence" from 10 to 100 based on their input.
   - "coachResponse": Generate a friendly follow-up question in simple English to keep the conversation going, matched to their difficulty level.
3. Difficulty Levels:
   - Beginner: Use extremely simple vocabulary (A1-A2 level), very short sentences, and ask very direct, simple questions.
   - Intermediate: Use standard conversational English and medium-length sentences. Ask open-ended questions.
   - Advanced: Use fluent, natural English with rich vocabulary/idioms and complex sentence structures. Ask deep, scenario-appropriate questions.
4. Output must be strictly JSON format. Do not wrap in markdown ```json blocks.

JSON Output Schema:
{
  "languageCode": "EN" | "TA",
  "isTamilOrMixed": boolean,
  "praise": "string",
  "correctedText": "string" | null,
  "tamilExplanation": "string",
  "scores": {
    "grammar": number,
    "fluency": number,
    "confidence": number
  } | null,
  "coachResponse": "string"
}
''';

  static void _initModel() {
    if (_model != null) return;

    final apiKey = SecureKeyProvider.getGeminiApiKey();
    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API Key is missing or invalid. Please check your secure credentials.',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
      ),
      systemInstruction: Content.system(_systemInstruction),
    );
  }

  // Generate initial greeting dynamically using Gemini based on topic and difficulty
  static Future<String> generateInitialGreeting({
    required String topic,
    required String difficulty,
  }) async {
    try {
      _initModel();

      final prompt = '''
You are the English tutor "Argus Coach".
Generate a friendly, natural starting greeting and initial question in English to begin a roleplay/practice conversation.
Topic: "$topic"
Difficulty Level: "$difficulty"

Rules:
1. The message must fit the topic role (e.g. if Railway Station, you are the station master; if Job Interview, you are the interviewer; if Hotel Booking, you are the receptionist; if General Practice, you are a friendly coach).
2. The language complexity must match the difficulty level:
   - Beginner: Use extremely simple vocabulary and short, clear sentences. Ask a very simple, direct question.
   - Intermediate: Use standard everyday English, moderate sentence length.
   - Advanced: Use natural, expressive English, slightly more complex phrasing or idiomatic expressions.
3. Output ONLY the plain text of the starting greeting. Do not include quotes, JSON, formatting, or markdown.
''';

      final content = [Content.text(prompt)];
      final response = await _model!
          .generateContent(content)
          .timeout(const Duration(seconds: 8));

      final responseText = response.text;
      if (responseText != null && responseText.isNotEmpty) {
        String cleanText = responseText.trim();
        if ((cleanText.startsWith('"') && cleanText.endsWith('"')) ||
            (cleanText.startsWith("'") && cleanText.endsWith("'"))) {
          cleanText = cleanText.substring(1, cleanText.length - 1);
        }
        return cleanText;
      }
    } catch (e) {
      // Fallback
    }

    return getMockInitialGreeting(topic, difficulty);
  }

  static Future<Map<String, dynamic>> evaluateResponse({
    required String utterance,
    required String topic,
    required String difficulty,
    required int turnIndex,
    required List<Map<String, String>> conversationHistory,
  }) async {
    // 1. Enforce local limit check
    if (HiveService.getUsedTurnsToday() >= 20) {
      throw Exception('Practice limit reached for today! Resets at midnight.');
    }

    try {
      _initModel();

      final history = conversationHistory
          .map((m) => "${m['role']}: ${m['text']}")
          .join('\n');

      final prompt =
          '''
Conversation Topic: "$topic"
Difficulty Level: "$difficulty"

Previous Conversation:
$history

Latest User Message:
"$utterance"

Continue the conversation naturally.
Evaluate the user's latest response.
Ask ONE relevant follow-up question based on the conversation.
''';

      final content = [Content.text(prompt)];
      final response = await _model!
          .generateContent(content)
          .timeout(const Duration(seconds: 8));

      final responseText = response.text;
      if (responseText != null && responseText.isNotEmpty) {
        // Robust JSON cleaning: extract first matching {...} block using regex
        String cleanJson = responseText.trim();
        final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleanJson);
        if (match != null) {
          cleanJson = match.group(0)!;
        }

        final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;

        // Log scores to Hive progress if English
        final isTamil = decoded['isTamilOrMixed'] as bool? ?? false;
        if (!isTamil && decoded['scores'] != null) {
          final scores = decoded['scores'] as Map<dynamic, dynamic>;
          final grammar = (scores['grammar'] as num).toDouble();
          final fluency = (scores['fluency'] as num).toDouble();
          final confidence = (scores['confidence'] as num).toDouble();
          await HiveService.saveDailyMetric(grammar, fluency, confidence);
        }

        await HiveService.incrementUsedTurns();
        return decoded;
      }
    } catch (e) {
      // Fallback to offline mock engine if Gemini API fails or limits are hit
      return _generateMockFallback(utterance, topic, turnIndex);
    }

    return _generateMockFallback(utterance, topic, turnIndex);
  }

  // Fallback Mock Engine
  static Future<Map<String, dynamic>> _generateMockFallback(
    String utterance,
    String topic,
    int turnIndex,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await HiveService.incrementUsedTurns();

    final difficulty = HiveService.getDifficultyLevel();
    final isTamil = _detectTamilText(utterance);

    if (isTamil) {
      String englishTranslation = "I want a ticket";
      if (utterance.toLowerCase().contains('vanakkam') || utterance.toLowerCase().contains('hello')) {
        englishTranslation = "Hello";
      }
      return {
        'languageCode': 'TA',
        'isTamilOrMixed': true,
        'praise':
            'Great attempt! Let\'s learn how to say this in English.',
        'correctedText': englishTranslation,
        'tamilExplanation':
            'நீங்கள் தமிழில் பேசினீர்கள். அதற்குப் பதிலாக ஆங்கிலத்தில் இப்படி சொல்லுங்கள்: "$englishTranslation".',
        'scores': null,
        'coachResponse':
            'To say that, you can say: "$englishTranslation". Try repeating that after me!',
        'remainingTurns': 20 - HiveService.getUsedTurnsToday(),
      };
    }

    String corrected = utterance;
    String explanation =
        "Your sentence is grammatically correct! Excellent effort.";
    double grammarScore = 95.0;
    double fluencyScore = 90.0;
    double confidenceScore = 92.0;

    final utteranceLower = utterance.toLowerCase().trim();
    if (utteranceLower.contains('i going')) {
      corrected = utterance.replaceAll(
        RegExp('i going', caseSensitive: false),
        'I went',
      );
      explanation =
          "கடந்த காலத்தை (past tense) குறிக்கும் போது 'I going' என்பதற்கு பதிலாக 'I went' என பயன்படுத்த வேண்டும்.";
      grammarScore = 70.0;
      confidenceScore = 75.0;
    } else if (utteranceLower.contains('yesterday i go')) {
      corrected = utterance.replaceAll(
        RegExp('i go', caseSensitive: false),
        'I went',
      );
      explanation =
          "'Yesterday' என்பது கடந்த காலத்தைக் குறிப்பதால் 'go'-க்குப் பதிலாக 'went' (past tense) எனப் பயன்படுத்த வேண்டும்.";
      grammarScore = 72.0;
      confidenceScore = 78.0;
    } else if (utteranceLower.contains('for buy')) {
      corrected = utterance.replaceAll(
        RegExp('for buy', caseSensitive: false),
        'to buy',
      );
      explanation =
          "ஆங்கிலத்தில் ஒரு நோக்கத்தை விவரிக்கும்போது பொதுவாக 'for buying' அல்லது 'to buy' எனப் பயன்படுத்த வேண்டும்.";
      grammarScore = 80.0;
    }

    await HiveService.saveDailyMetric(
      grammarScore,
      fluencyScore,
      confidenceScore,
    );

    // Dynamic level-aware prompts
    String nextPrompt;
    if (topic == 'Railway Station') {
      if (difficulty == 'Beginner') {
        nextPrompt = turnIndex == 0
            ? "Are you going to Chennai?"
            : "Do you have a ticket?";
      } else if (difficulty == 'Intermediate') {
        nextPrompt = turnIndex == 0
            ? "The next train to Chennai departs in ten minutes. Are you traveling alone?"
            : "No problem. Let me help you carry your luggage. Have you purchased your ticket?";
      } else {
        nextPrompt = turnIndex == 0
            ? "The express train bound for Chennai is scheduled for Platform 3 shortly. Are you traveling solo or with family?"
            : "Certainly. I can arrange porter assistance for your luggage. Do you hold a confirmed ticket or booking confirmation?";
      }
    } else if (topic == 'Job Interview') {
      if (difficulty == 'Beginner') {
        nextPrompt = turnIndex == 0
            ? "Why do you like this job?"
            : "Can you speak English well?";
      } else if (difficulty == 'Intermediate') {
        nextPrompt = turnIndex == 0
            ? "That sounds wonderful. Why are you interested in working as an English speaker?"
            : "I appreciate your honesty. Where do you see yourself in five years?";
      } else {
        nextPrompt = turnIndex == 0
            ? "That's quite impressive. What specific aspects of this role at Argus Communications attracted you the most?"
            : "Valuable perspective. Looking forward, where do you see your career path leading over the next five years?";
      }
    } else if (topic == 'Hotel Booking') {
      if (difficulty == 'Beginner') {
        nextPrompt = turnIndex == 0
            ? "Do you want a big bed or small bed?"
            : "How do you want to pay? Cash or card?";
      } else if (difficulty == 'Intermediate') {
        nextPrompt = turnIndex == 0
            ? "I can find a deluxe room available for two nights. Would you like a king bed or double beds?"
            : "Perfect. The total comes to one hundred dollars. How would you like to make the payment?";
      } else {
        nextPrompt = turnIndex == 0
            ? "We currently have a deluxe suite ready for your stay. Would you prefer a king-size bed or a double-bed configuration?"
            : "Excellent choice. Your reservation is finalized. How would you prefer to settle the transaction?";
      }
    } else {
      if (difficulty == 'Beginner') {
        nextPrompt = turnIndex == 0
            ? "What did you eat today?"
            : "What is your hobby?";
      } else if (difficulty == 'Intermediate') {
        nextPrompt = turnIndex == 0
            ? "Oh, that sounds interesting! Did you go anywhere else?"
            : "Nice. What are your plans for tomorrow?";
      } else {
        nextPrompt = turnIndex == 0
            ? "Fascinating routine. Did you explore any other activities or locations during your day?"
            : "Wonderful. What are your primary goals and agendas scheduled for tomorrow?";
      }
    }

    return {
      'languageCode': 'EN',
      'isTamilOrMixed': false,
      'praise':
          'Wonderful effort! Every sentence brings you closer to fluency.',
      'correctedText': corrected,
      'tamilExplanation': explanation,
      'scores': {
        'grammar': grammarScore,
        'fluency': fluencyScore,
        'confidence': confidenceScore,
      },
      'coachResponse': nextPrompt,
      'remainingTurns': 20 - HiveService.getUsedTurnsToday(),
    };
  }

  static bool _detectTamilText(String text) {
    final tamilReg = RegExp(r'[\u0B80-\u0BFF]');
    if (tamilReg.hasMatch(text)) return true;

    final lower = text.toLowerCase();
    final tanglishKeywords = [
      'naan',
      'nalla',
      'iruken',
      'poren',
      'solunga',
      'amaa',
      'theriyathu',
      'enaku',
      'ticket',
      'venum',
    ];
    for (var key in tanglishKeywords) {
      if (lower.contains(key)) return true;
    }
    return false;
  }

  static String getMockInitialGreeting(String topic, String difficulty) {
    if (topic == 'Railway Station') {
      if (difficulty == 'Beginner') {
        return "Hello! I am the station master. Where do you want to go?";
      } else if (difficulty == 'Intermediate') {
        return "Hello! I am the station master. How can I help you find your train today?";
      } else {
        return "Good day! I'm the station master here. How may I assist you with your travel plans or bookings today?";
      }
    } else if (topic == 'Job Interview') {
      if (difficulty == 'Beginner') {
        return "Hello! Welcome. Can you tell me your name and job?";
      } else if (difficulty == 'Intermediate') {
        return "Welcome to Argus Communications. Can you please tell me about yourself and your background?";
      } else {
        return "Welcome to Argus Communications. To start our interview, could you walk me through your professional background and key achievements?";
      }
    } else if (topic == 'Hotel Booking') {
      if (difficulty == 'Beginner') {
        return "Hello! Welcome to our hotel. Do you want a room?";
      } else if (difficulty == 'Intermediate') {
        return "Good evening, welcome to the Grand Palace Hotel. Do you have a reservation under your name?";
      } else {
        return "Good evening and welcome to the Grand Palace Hotel. May I inquire if you have an active reservation with us tonight?";
      }
    } else {
      if (difficulty == 'Beginner') {
        return "Hi! Let's talk in English. How are you today?";
      } else if (difficulty == 'Intermediate') {
        return "Hi there! Let's chat. What did you do yesterday?";
      } else {
        return "Hello! I'd love to chat with you today. Could you share what your main goals are for improving your English communication?";
      }
    }
  }
}
