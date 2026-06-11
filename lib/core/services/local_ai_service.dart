import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../models/expense.dart';
import '../models/debt.dart';
import '../models/insight.dart';
import '../models/reflection.dart';
import 'ai_service.dart';

class LocalAIService {
  static const String _modelUrl =
      'https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf';
  static const String _modelFileName = 'qwen2-0_5b-instruct-q4_k_m.gguf';

  LocalAIService._();

  static Future<String> getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, _modelFileName);
  }

  /// Copies the model from Flutter assets to local application documents folder if it doesn't exist
  static Future<void> loadModelFromAssets() async {
    final path = await getModelPath();
    final file = File(path);
    if (!file.existsSync()) {
      await file.parent.create(recursive: true);
      final byteData = await rootBundle.load('assets/models/$_modelFileName');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
    }
  }

  static Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final file = File(path);
    if (!file.existsSync()) return false;
    try {
      final length = await file.length();
      // Expecting at least 300 MB (correct model size is ~379 MB)
      return length >= 300 * 1024 * 1024;
    } catch (_) {
      return false;
    }
  }

  /// Downloads the model file from Hugging Face and yields the download progress (0.0 to 1.0)
  static Stream<double> downloadModel() async* {
    final path = await getModelPath();
    final file = File(path);
    
    // Create parent directories if they don't exist
    await file.parent.create(recursive: true);

    final client = HttpClient();
    
    try {
      final request = await client.getUrl(Uri.parse(_modelUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('Failed to download model. Status code: ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      final sink = file.openWrite();
      int downloadedBytes = 0;

      final controller = StreamController<double>();

      response.listen(
        (chunk) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            controller.add(progress);
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          
          try {
            final fileLength = await file.length();
            if (contentLength > 0 && fileLength != contentLength) {
              throw HttpException('Downloaded file size ($fileLength bytes) does not match expected size ($contentLength bytes).');
            }
            if (fileLength < 300 * 1024 * 1024) {
              throw HttpException('Downloaded model file is too small ($fileLength bytes) and may be corrupt.');
            }
            controller.close();
          } catch (err) {
            if (file.existsSync()) {
              file.deleteSync();
            }
            controller.addError(err);
            controller.close();
          }
        },
        onError: (Object e) {
          sink.close();
          if (file.existsSync()) {
            file.deleteSync();
          }
          controller.addError(e);
          controller.close();
        },
        cancelOnError: true,
      );

      yield* controller.stream;
    } catch (e) {
      if (file.existsSync()) {
        file.deleteSync();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Generates finance coach reflection feedback locally using Qwen-2-0.5B
  static Future<AIServiceResult> generateFeedback({
    required String userName,
    required double allowance,
    required List<Expense> expenses,
    required List<Debt> debts,
  }) async {
    final modelPath = await getModelPath();
    if (!File(modelPath).existsSync()) {
      throw const FileSystemException('Local Qwen model file not found. Please download it first.');
    }

    // 1. Build deterministic financial details
    final totalSpent = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final remaining = allowance - totalSpent;

    final Map<String, double> categorySums = {};
    for (var expense in expenses) {
      final catName = expense.category.displayName;
      categorySums[catName] = (categorySums[catName] ?? 0.0) + expense.amount;
    }

    final categoryBreakdownText = categorySums.entries
        .map((e) => '- ${e.key}: ₱${e.value.toStringAsFixed(0)}')
        .join('\n');

    final expensesListText = expenses.take(15).map((e) {
      final dateStr = "${e.date.year}-${e.date.month}-${e.date.day}";
      return '- ₱${e.amount.toStringAsFixed(0)} on ${e.category.displayName} (${e.note}) on $dateStr';
    }).join('\n');

    final debtsListText = debts.map((d) {
      final direction = d.isIOwe ? "I owe them" : "They owe me";
      return '- ${d.name}: ₱${d.remainingAmount.toStringAsFixed(0)} outstanding / ₱${d.originalAmount.toStringAsFixed(0)} original ($direction, Status: ${d.status.name})';
    }).join('\n');

    // 2. Compose prompting context
    final prompt = '''
Analyze this weekly student personal finance data and generate coaching insights and Saturday reflections.
Return your output strictly as a valid JSON object matching the schema below. Do not output anything else.

USER DATA:
- Name: $userName
- Weekly Allowance: ₱${allowance.toStringAsFixed(0)}
- Total Spent: ₱${totalSpent.toStringAsFixed(0)}
- Remaining Allowance: ₱${remaining.toStringAsFixed(0)}

SPENDING BY CATEGORY:
${categoryBreakdownText.isEmpty ? 'No transactions logged.' : categoryBreakdownText}

RECENT EXPENSES:
${expensesListText.isEmpty ? 'No transactions logged.' : expensesListText}

ACTIVE DEBTS:
${debtsListText.isEmpty ? 'No active debts.' : debtsListText}

SCHEMA:
{
  "insights": [
    {
      "id": "ai_in_1",
      "title": "Impulse Warning",
      "description": "You spent ₱500 on Wants. Sleep on wants for 24h next time!",
      "type": "warning",
      "category": "Wants"
    }
  ],
  "reflection": {
    "whatWentWell": ["Saved 20% allowance.", "Paid off Friend A."],
    "needsImprovement": ["Excessive snacks spending."],
    "aiCoachSuggestions": ["Decrease Wants spending by ₱100.", "Settle small debts first."],
    "comparisonText": "Spent ₱150 less than budget limit",
    "motivationalQuote": "Save today, secure tomorrow."
  }
}
''';

    // 3. Initialize dynamic LlamaEngine in background isolate
    LlamaEngine? engine;
    try {
      final isMobileProcess = Platform.isIOS || Platform.isMacOS;
      
      if (isMobileProcess) {
        engine = await LlamaEngine.spawnFromProcess(
          modelParams: ModelParams(path: modelPath),
          contextParams: const ContextParams(nCtx: 2048),
        );
      } else {
        final libName = LlamaLibrary.defaultFileName();
        engine = await LlamaEngine.spawn(
          libraryPath: libName,
          modelParams: ModelParams(path: modelPath),
          contextParams: const ContextParams(nCtx: 2048),
        );
      }

      // Create chat turn
      final chat = await engine.createChat();
      chat.addSystem("You are KwartaKo, an expert AI student finance coach. You always respond strictly in valid JSON format matching the requested schema. You output zero conversational preamble.");
      chat.addUser(prompt);

      final responseBuffer = StringBuffer();
      
      // Execute local generation
      await for (final event in chat.generate(maxTokens: 512)) {
        if (event is TokenEvent) {
          responseBuffer.write(event.text);
        }
      }

      final rawOutput = responseBuffer.toString();
      debugPrint("Qwen Raw Output:\n$rawOutput");

      // 4. Robust parsing of JSON from local output
      final data = _cleanAndParseJson(rawOutput);

      final List<Insight> insights = [];
      if (data['insights'] != null) {
        for (var item in data['insights']) {
          insights.add(Insight.fromMap(item as Map<String, dynamic>));
        }
      }

      final reflData = data['reflection'] as Map<String, dynamic>? ?? {};
      final savingsSum = categorySums['Savings'] ?? 0.0;

      List<String> parseStringList(dynamic value, List<String> fallback) {
        if (value is List) {
          return value.map((e) => e.toString()).toList();
        }
        return fallback;
      }

      // Re-overlay deterministic maths on top of AI suggestions
      final reflection = WeeklyReflection(
        allowance: allowance,
        totalSpent: totalSpent,
        remaining: remaining,
        savings: savingsSum,
        dailySpendingTrend: _calculateDailySpendingTrend(expenses),
        topCategories: _calculateTopCategories(expenses),
        whatWentWell: parseStringList(reflData['whatWentWell'], ['Log transactions to start reflection!']),
        needsImprovement: parseStringList(reflData['needsImprovement'], ['No spending data recorded yet.']),
        aiCoachSuggestions: parseStringList(reflData['aiCoachSuggestions'], ['Use Sunday Planning to set your budget allocation.']),
        comparisonText: reflData['comparisonText'] as String? ?? 'No comparison data',
        motivationalQuote: reflData['motivationalQuote'] as String? ?? 'Keep saving!',
      );

      return AIServiceResult(
        insights: insights,
        reflection: reflection,
      );
    } catch (e) {
      debugPrint("Local Qwen Error: $e");
      rethrow;
    } finally {
      if (engine != null) {
        await engine.dispose();
      }
    }
  }

  static Map<String, dynamic> _cleanAndParseJson(String rawOutput) {
    final cleaned = rawOutput.trim();

    // 1. Direct parse
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {}

    // 2. Try markdown json block match
    final jsonRegex = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
    final match = jsonRegex.firstMatch(cleaned);
    if (match != null) {
      try {
        return jsonDecode(match.group(1)!) as Map<String, dynamic>;
      } catch (_) {}
    }

    // 3. Find first { and last }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      try {
        return jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
      } catch (_) {}
    }

    throw FormatException("Failed to extract valid JSON from Qwen response: $rawOutput");
  }

  // --- DETERMINISTIC MATH CALCULATIONS FOR REFLECTION ---
  static List<double> _calculateDailySpendingTrend(List<Expense> expenses) {
    final List<double> trend = List.filled(7, 0.0);
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final mondayOfThisWeek = now.subtract(Duration(days: currentWeekday - 1));
    final startOfDayMonday = DateTime(mondayOfThisWeek.year, mondayOfThisWeek.month, mondayOfThisWeek.day);

    for (var expense in expenses) {
      final difference = expense.date.difference(startOfDayMonday).inDays;
      if (difference >= 0 && difference < 7) {
        final index = expense.date.weekday - 1;
        if (index >= 0 && index < 7) {
          trend[index] += expense.amount;
        }
      }
    }
    return trend;
  }

  static Map<String, double> _calculateTopCategories(List<Expense> expenses) {
    final Map<String, double> sums = {};
    for (var expense in expenses) {
      final name = expense.category.displayName;
      sums[name] = (sums[name] ?? 0.0) + expense.amount;
    }
    
    final sortedEntries = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return Map.fromEntries(sortedEntries);
  }
}
