import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/debt.dart';
import '../models/insight.dart';
import '../models/reflection.dart';
import '../database/database_helper.dart';
import '../services/ai_service.dart';
import '../services/local_ai_service.dart';

class FinanceProvider extends ChangeNotifier {
  String _userName = 'Alex';
  double _allowance = 0.0;
  double _disciplineScore = 8.2;
  String _geminiApiKey = '';
  bool _isGeneratingAI = false;
  bool _hasCompletedOnboarding = false;
  bool _isInitialized = false;
  bool _isModelDownloaded = false;
  double _downloadProgress = 0.0;
  bool _isDownloadingModel = false;
  
  List<Expense> _expenses = [];
  List<Debt> _debts = [];
  List<Insight> _insights = [];
  WeeklyReflection _reflection = WeeklyReflection.emptyReflection;

  FinanceProvider() {
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final db = DatabaseHelper.instance;
      
      final savedName = await db.getSetting('userName');
      if (savedName != null) _userName = savedName;
      
      final savedAllowance = await db.getSetting('allowance');
      if (savedAllowance != null) _allowance = double.tryParse(savedAllowance) ?? 0.0;

      final savedScore = await db.getSetting('disciplineScore');
      if (savedScore != null) _disciplineScore = double.tryParse(savedScore) ?? 8.2;

      final savedKey = await db.getSetting('geminiApiKey');
      if (savedKey != null) _geminiApiKey = savedKey;

      final savedOnboarding = await db.getSetting('hasCompletedOnboarding');
      if (savedOnboarding != null) {
        _hasCompletedOnboarding = savedOnboarding == 'true';
      }

      _expenses = await db.fetchExpenses();
      _debts = await db.fetchDebts();
      _insights = await db.fetchInsights();
      
      final savedReflection = await db.fetchReflection();
      if (savedReflection != null) {
        _reflection = savedReflection;
      }
    } catch (e) {
      debugPrint("Error loading from database: $e");
    } finally {
      try {
        await LocalAIService.loadModelFromAssets();
        _isModelDownloaded = true;
      } catch (e) {
        _isModelDownloaded = await LocalAIService.isModelDownloaded();
      }
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> resetDatabase() async {
    _isInitialized = false;
    notifyListeners();
    
    await DatabaseHelper.instance.clearAllData();
    _geminiApiKey = '';
    _isGeneratingAI = false;
    _hasCompletedOnboarding = false;
    try {
      await LocalAIService.loadModelFromAssets();
      _isModelDownloaded = true;
    } catch (e) {
      _isModelDownloaded = await LocalAIService.isModelDownloaded();
    }
    await _loadFromDatabase();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await DatabaseHelper.instance.setSetting('hasCompletedOnboarding', 'true');
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key;
    await DatabaseHelper.instance.setSetting('geminiApiKey', key);
    notifyListeners();
    generateAICoachFeedback();
  }

  Future<void> startModelDownload() async {
    if (_isDownloadingModel || _isModelDownloaded) return;
    _isDownloadingModel = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      await for (final progress in LocalAIService.downloadModel()) {
        _downloadProgress = progress;
        notifyListeners();
      }
      _isModelDownloaded = true;
    } catch (e) {
      debugPrint("Download failed: $e");
      _isModelDownloaded = false;
    } finally {
      _isDownloadingModel = false;
      notifyListeners();
    }
  }

  Future<void> generateAICoachFeedback() async {
    if (!_isModelDownloaded) return;
    _isGeneratingAI = true;
    notifyListeners();
    try {
      final result = await LocalAIService.generateFeedback(
        userName: _userName,
        allowance: _allowance,
        expenses: weeklyExpenses,
        debts: _debts,
      );
      
      _insights = result.insights;
      _reflection = result.reflection;
      
      await DatabaseHelper.instance.saveAllInsights(_insights);
      await DatabaseHelper.instance.saveReflection(_reflection);
    } catch (e) {
      debugPrint("Local AI generation error: $e");
    } finally {
      _isGeneratingAI = false;
      notifyListeners();
    }
  }

  // Getters
  String get userName => _userName;
  double get allowance => _allowance;
  double get disciplineScore => _disciplineScore;
  String get geminiApiKey => _geminiApiKey;
  bool get isGeneratingAI => _isGeneratingAI;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitialized => _isInitialized;
  bool get isModelDownloaded => _isModelDownloaded;
  double get downloadProgress => _downloadProgress;
  bool get isDownloadingModel => _isDownloadingModel;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Debt> get debts => List.unmodifiable(_debts);
  List<Insight> get insights => List.unmodifiable(_insights);
  WeeklyReflection get reflection => _reflection;

  // Weekly Date Range Helper
  DateTime get startOfCurrentWeek {
    final now = DateTime.now();
    // Monday is 1, Sunday is 7. We subtract to get the most recent Sunday.
    final daysToSubtract = now.weekday % 7;
    final lastSunday = now.subtract(Duration(days: daysToSubtract));
    return DateTime(lastSunday.year, lastSunday.month, lastSunday.day);
  }

  List<Expense> get weeklyExpenses {
    final start = startOfCurrentWeek;
    return _expenses.where((e) => e.date.isAfter(start) || e.date.isAtSameMomentAs(start)).toList();
  }

  // Computed Getters
  double get totalSpent {
    return weeklyExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get remainingAllowance {
    return _allowance - totalSpent;
  }

  double get totalOwedToMe {
    return _debts
        .where((d) => !d.isIOwe && d.status != DebtStatus.paid)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  double get totalIOwe {
    return _debts
        .where((d) => d.isIOwe && d.status != DebtStatus.paid)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  // Setters & Operations
  void setUserName(String name) {
    _userName = name;
    DatabaseHelper.instance.setSetting('userName', name);
    notifyListeners();
  }

  void setAllowance(double amount) {
    _allowance = amount;
    DatabaseHelper.instance.setSetting('allowance', amount.toString());
    _recalculateDisciplineScore();
    notifyListeners();
    generateAICoachFeedback();
  }

  void addExpense({
    required double amount,
    required ExpenseCategory category,
    required String note,
    required DateTime date,
  }) {
    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      note: note,
      date: date,
    );
    _expenses.insert(0, newExpense);
    DatabaseHelper.instance.insertExpense(newExpense);
    
    _checkAndTriggerInsights(category, amount);
    _recalculateDisciplineScore();
    notifyListeners();
    generateAICoachFeedback();
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    DatabaseHelper.instance.deleteExpense(id);
    _recalculateDisciplineScore();
    notifyListeners();
    generateAICoachFeedback();
  }

  void addDebt({
    required String name,
    required double amount,
    required bool isIOwe,
    required DateTime dueDate,
  }) {
    final newDebt = Debt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      originalAmount: amount,
      remainingAmount: amount,
      dueDate: dueDate,
      isIOwe: isIOwe,
      status: DebtStatus.pending,
      payments: const [],
    );
    _debts.insert(0, newDebt);
    DatabaseHelper.instance.insertDebt(newDebt);
    notifyListeners();
    generateAICoachFeedback();
  }

  void deleteDebt(String id) {
    _debts.removeWhere((d) => d.id == id);
    DatabaseHelper.instance.deleteDebt(id);
    notifyListeners();
    generateAICoachFeedback();
  }

  void payPartialDebt(String debtId, double paymentAmount) {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      final oldDebt = _debts[index];
      final newRemaining = (oldDebt.remainingAmount - paymentAmount).clamp(0.0, oldDebt.originalAmount);
      final newStatus = newRemaining == 0.0 ? DebtStatus.paid : oldDebt.status;
      
      final newPayment = DebtPayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: paymentAmount,
        date: DateTime.now(),
      );
      
      final updatedPayments = List<DebtPayment>.from(oldDebt.payments)
        ..add(newPayment);

      final updatedDebt = Debt(
        id: oldDebt.id,
        name: oldDebt.name,
        originalAmount: oldDebt.originalAmount,
        remainingAmount: newRemaining,
        dueDate: oldDebt.dueDate,
        isIOwe: oldDebt.isIOwe,
        status: newStatus,
        payments: updatedPayments,
      );

      _debts[index] = updatedDebt;
      DatabaseHelper.instance.updateDebt(updatedDebt);
      DatabaseHelper.instance.insertDebtPayment(debtId, newPayment);
      notifyListeners();
      generateAICoachFeedback();
    }
  }

  void markDebtAsPaid(String debtId) {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      final oldDebt = _debts[index];
      
      final updatedPayments = List<DebtPayment>.from(oldDebt.payments);
      DebtPayment? newPayment;
      if (oldDebt.remainingAmount > 0) {
        newPayment = DebtPayment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: oldDebt.remainingAmount,
          date: DateTime.now(),
        );
        updatedPayments.add(newPayment);
      }

      final updatedDebt = Debt(
        id: oldDebt.id,
        name: oldDebt.name,
        originalAmount: oldDebt.originalAmount,
        remainingAmount: 0.0,
        dueDate: oldDebt.dueDate,
        isIOwe: oldDebt.isIOwe,
        status: DebtStatus.paid,
        payments: updatedPayments,
      );

      _debts[index] = updatedDebt;
      DatabaseHelper.instance.updateDebt(updatedDebt);
      if (newPayment != null) {
        DatabaseHelper.instance.insertDebtPayment(debtId, newPayment);
      }
      notifyListeners();
      generateAICoachFeedback();
    }
  }

  // Internal calculation helpers
  void _recalculateDisciplineScore() {
    double score = 10.0;
    
    // Penalty 1: Spent ratio of allowance
    final spentRatio = _allowance > 0 ? totalSpent / _allowance : 0.0;
    if (spentRatio > 1.0) {
      score -= 3.0; // Overspent penalty
    } else if (spentRatio > 0.8) {
      score -= 1.5;
    } else if (spentRatio > 0.5) {
      score -= 0.5;
    }

    // Penalty 2: High proportion of Wants (impulse purchases)
    final wantsSpent = weeklyExpenses
        .where((e) => e.category == ExpenseCategory.wants)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final wantsRatio = totalSpent > 0 ? wantsSpent / totalSpent : 0.0;
    if (wantsRatio > 0.5) {
      score -= 1.5;
    } else if (wantsRatio > 0.3) {
      score -= 0.8;
    }

    // Penalty 3: Overdue debts
    final overdueCount = _debts.where((d) => d.status == DebtStatus.overdue).length;
    score -= (overdueCount * 0.5);

    _disciplineScore = double.parse(score.clamp(1.0, 10.0).toStringAsFixed(1));
    DatabaseHelper.instance.setSetting('disciplineScore', _disciplineScore.toString());
  }

  void _checkAndTriggerInsights(ExpenseCategory category, double amount) {
    // Trigger dynamic warning insights based on recent activities
    if (category == ExpenseCategory.wants && amount >= 500) {
      final newInsight = Insight(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Impulse Warning',
        description: 'You just logged a large Want purchase of ₱${amount.toStringAsFixed(0)}. Sleep on wants for 24h next time!',
        type: InsightType.warning,
        category: 'Wants',
      );
      _insights.insert(0, newInsight);
      DatabaseHelper.instance.saveInsight(newInsight);
    }
    
    // Small expense check: count how many under ₱50
    final smallExpenses = weeklyExpenses.where((e) => e.amount < 50.0).toList();
    if (smallExpenses.length >= 8) {
      final totalSmallSum = smallExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final existingIndex = _insights.indexWhere((i) => i.title == 'Small Expense Detector');
      final updatedInsight = Insight(
        id: 'in1',
        title: 'Small Expense Detector',
        description: 'You spent ₱${totalSmallSum.toStringAsFixed(0)} on ${smallExpenses.length} purchases below ₱50 this week. Small taps add up quickly!',
        type: InsightType.warning,
        category: 'Others',
      );
      
      if (existingIndex != -1) {
        _insights[existingIndex] = updatedInsight;
      } else {
        _insights.add(updatedInsight);
      }
      DatabaseHelper.instance.saveAllInsights(_insights);
    }
  }
}
