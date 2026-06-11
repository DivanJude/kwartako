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
  int _streakCount = 0;
  String _lastLogDate = '';
  double _foodRatio = 0.35;
  double _transRatio = 0.15;
  double _schoolRatio = 0.25;
  double _savingsRatio = 0.15;
  double _othersRatio = 0.10;
  int _currentNavigationIndex = 0;
  
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

      final savedStreak = await db.getSetting('streakCount');
      if (savedStreak != null) _streakCount = int.tryParse(savedStreak) ?? 0;

      final savedLastLogDate = await db.getSetting('lastLogDate');
      if (savedLastLogDate != null) _lastLogDate = savedLastLogDate;

      // Check and reset broken streaks on startup
      if (_lastLogDate.isNotEmpty) {
        try {
          final lastDateParts = _lastLogDate.split('-');
          final lastDate = DateTime(
            int.parse(lastDateParts[0]),
            int.parse(lastDateParts[1]),
            int.parse(lastDateParts[2]),
          );
          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day);
          final difference = todayDate.difference(lastDate).inDays;
          if (difference > 1) {
            _streakCount = 0;
            await db.setSetting('streakCount', '0');
          }
        } catch (_) {}
      }

      final savedFood = await db.getSetting('budget_ratio_food');
      if (savedFood != null) _foodRatio = double.tryParse(savedFood) ?? 0.35;

      final savedTrans = await db.getSetting('budget_ratio_trans');
      if (savedTrans != null) _transRatio = double.tryParse(savedTrans) ?? 0.15;

      final savedSchool = await db.getSetting('budget_ratio_school');
      if (savedSchool != null) _schoolRatio = double.tryParse(savedSchool) ?? 0.25;

      final savedSavings = await db.getSetting('budget_ratio_savings');
      if (savedSavings != null) _savingsRatio = double.tryParse(savedSavings) ?? 0.15;

      final savedOthers = await db.getSetting('budget_ratio_others');
      if (savedOthers != null) _othersRatio = double.tryParse(savedOthers) ?? 0.10;

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
    final hasGeminiKey = _geminiApiKey.trim().isNotEmpty;
    if ((!_isModelDownloaded && !hasGeminiKey) || _isGeneratingAI) return;
    _isGeneratingAI = true;
    notifyListeners();
    try {
      final AIServiceResult result;
      if (hasGeminiKey) {
        result = await AIService.generateFeedback(
          apiKey: _geminiApiKey,
          userName: _userName,
          allowance: _allowance,
          expenses: weeklyExpenses,
          debts: _debts,
        );
      } else {
        result = await LocalAIService.generateFeedback(
          userName: _userName,
          allowance: _allowance,
          expenses: weeklyExpenses,
          debts: _debts,
        );
      }
      
      _insights = result.insights;
      _reflection = result.reflection;
      
      await DatabaseHelper.instance.saveAllInsights(_insights);
      await DatabaseHelper.instance.saveReflection(_reflection);
    } catch (e) {
      debugPrint("AI Coach generation error: $e");
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
  int get streakCount {
    if (_lastLogDate.isEmpty) return 0;
    try {
      final lastDateParts = _lastLogDate.split('-');
      final lastDate = DateTime(
        int.parse(lastDateParts[0]),
        int.parse(lastDateParts[1]),
        int.parse(lastDateParts[2]),
      );
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final difference = todayDate.difference(lastDate).inDays;
      if (difference > 1) {
        return 0;
      }
    } catch (_) {
      return 0;
    }
    return _streakCount;
  }
  String get lastLogDate => _lastLogDate;

  int get currentNavigationIndex => _currentNavigationIndex;
  
  void setNavigationIndex(int index) {
    _currentNavigationIndex = index;
    notifyListeners();
  }

  String get disciplineLevel {
    if (_disciplineScore >= 9.0) return 'Centavo Sage 🌟';
    if (_disciplineScore >= 7.5) return 'Thrifty Scholar 🎓';
    if (_disciplineScore >= 5.0) return 'Budget Balancer ⚖️';
    if (_disciplineScore >= 3.0) return 'Loose Spender 💸';
    return 'Bankruptcy Warning ⚠️';
  }

  // Budget Category limits & expenditures
  double getCategoryBudget(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return _allowance * _foodRatio;
      case ExpenseCategory.transportation:
        return _allowance * _transRatio;
      case ExpenseCategory.school:
        return _allowance * _schoolRatio;
      case ExpenseCategory.savings:
        return _allowance * _savingsRatio;
      case ExpenseCategory.others:
        return _allowance * _othersRatio;
      case ExpenseCategory.loadInternet:
      case ExpenseCategory.wants:
      case ExpenseCategory.emergency:
        return double.infinity;
    }
  }

  double getCategorySpent(ExpenseCategory category) {
    return weeklyExpenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Discipline Score Parameter Breakdowns
  double get spentRatioPenalty {
    final spentRatio = _allowance > 0 ? totalSpent / _allowance : 0.0;
    if (spentRatio > 1.0) return -3.0;
    if (spentRatio > 0.8) return -1.5;
    if (spentRatio > 0.5) return -0.5;
    return 0.0;
  }

  double get wantsRatioPenalty {
    final wantsSpent = weeklyExpenses
        .where((e) => e.category == ExpenseCategory.wants)
        .fold(0.0, (sum, e) => sum + e.amount);
    final wantsRatio = totalSpent > 0 ? wantsSpent / totalSpent : 0.0;
    if (wantsRatio > 0.5) return -1.5;
    if (wantsRatio > 0.3) return -0.8;
    return 0.0;
  }

  double get overdueDebtsPenalty {
    final overdueCount = _debts.where((d) => d.status == DebtStatus.overdue).length;
    return -(overdueCount * 0.5);
  }

  void checkInNoSpendDay() {
    _updateStreak();
    notifyListeners();
  }
  double get foodRatio => _foodRatio;
  double get transRatio => _transRatio;
  double get schoolRatio => _schoolRatio;
  double get savingsRatio => _savingsRatio;
  double get othersRatio => _othersRatio;
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

  double get weeklyInflow {
    final start = startOfCurrentWeek;
    double sum = 0.0;
    for (var debt in _debts) {
      if (!debt.isIOwe) {
        for (var payment in debt.payments) {
          if (payment.date.isAfter(start) || payment.date.isAtSameMomentAs(start)) {
            sum += payment.amount;
          }
        }
      }
    }
    return sum;
  }

  double get remainingAllowance {
    return _allowance + weeklyInflow - totalSpent;
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

  void saveBudgetPlan({
    required double allowance,
    required double food,
    required double trans,
    required double school,
    required double savings,
    required double others,
  }) {
    _allowance = allowance;
    _foodRatio = food;
    _transRatio = trans;
    _schoolRatio = school;
    _savingsRatio = savings;
    _othersRatio = others;

    final db = DatabaseHelper.instance;
    db.setSetting('allowance', allowance.toString());
    db.setSetting('budget_ratio_food', food.toString());
    db.setSetting('budget_ratio_trans', trans.toString());
    db.setSetting('budget_ratio_school', school.toString());
    db.setSetting('budget_ratio_savings', savings.toString());
    db.setSetting('budget_ratio_others', others.toString());

    _recalculateDisciplineScore();
    notifyListeners();
    generateAICoachFeedback();
  }

  void addExpense({
    required double amount,
    required ExpenseCategory category,
    required String note,
    required DateTime date,
    String? id,
  }) {
    final newExpense = Expense(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      note: note,
      date: date,
    );
    _expenses.insert(0, newExpense);
    DatabaseHelper.instance.insertExpense(newExpense);
    
    _updateStreak();
    _checkAndTriggerInsights(category, amount);
    _recalculateDisciplineScore();
    notifyListeners();
    generateAICoachFeedback();
  }

  void _updateStreak() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    if (_lastLogDate.isEmpty) {
      _streakCount = 1;
    } else {
      try {
        final lastDateParts = _lastLogDate.split('-');
        final lastDate = DateTime(
          int.parse(lastDateParts[0]),
          int.parse(lastDateParts[1]),
          int.parse(lastDateParts[2]),
        );
        final todayDate = DateTime(now.year, now.month, now.day);
        final difference = todayDate.difference(lastDate).inDays;

        if (difference == 1) {
          _streakCount += 1;
        } else if (difference > 1) {
          _streakCount = 1;
        }
        // If difference == 0 (logged today already), do nothing, keep current streak.
      } catch (_) {
        _streakCount = 1;
      }
    }

    _lastLogDate = todayStr;
    DatabaseHelper.instance.setSetting('streakCount', _streakCount.toString());
    DatabaseHelper.instance.setSetting('lastLogDate', _lastLogDate);
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
    final trimmedName = name.trim();
    final existingIndex = _debts.indexWhere((d) =>
        d.name.trim().toLowerCase() == trimmedName.toLowerCase() &&
        d.isIOwe == isIOwe &&
        d.status != DebtStatus.paid);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final calculatedStatus = dueDate.isBefore(todayStart) ? DebtStatus.overdue : DebtStatus.pending;

    if (existingIndex != -1) {
      final oldDebt = _debts[existingIndex];
      final updatedDebt = Debt(
        id: oldDebt.id,
        name: oldDebt.name,
        originalAmount: oldDebt.originalAmount + amount,
        remainingAmount: oldDebt.remainingAmount + amount,
        dueDate: dueDate,
        isIOwe: oldDebt.isIOwe,
        status: calculatedStatus,
        payments: oldDebt.payments,
      );
      _debts[existingIndex] = updatedDebt;
      DatabaseHelper.instance.updateDebt(updatedDebt);
    } else {
      final newDebt = Debt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: trimmedName,
        originalAmount: amount,
        remainingAmount: amount,
        dueDate: dueDate,
        isIOwe: isIOwe,
        status: calculatedStatus,
        payments: const [],
      );
      _debts.insert(0, newDebt);
      DatabaseHelper.instance.insertDebt(newDebt);
    }
    _recalculateDisciplineScore();
    notifyListeners();
    generateAICoachFeedback();
  }

  void deleteDebt(String id) {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      final debt = _debts[index];
      if (debt.isIOwe) {
        for (var payment in debt.payments) {
          _expenses.removeWhere((e) => e.id == 'pay_${payment.id}');
          DatabaseHelper.instance.deleteExpense('pay_${payment.id}');
        }
      }
      _debts.removeAt(index);
      DatabaseHelper.instance.deleteDebt(id);
      _recalculateDisciplineScore();
      notifyListeners();
      generateAICoachFeedback();
    }
  }

  void payPartialDebt(String debtId, double paymentAmount) {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      final oldDebt = _debts[index];
      final newRemaining = (oldDebt.remainingAmount - paymentAmount).clamp(0.0, oldDebt.originalAmount);
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final newStatus = newRemaining == 0.0
          ? DebtStatus.paid
          : (oldDebt.dueDate.isBefore(todayStart) ? DebtStatus.overdue : oldDebt.status);
      
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

      if (oldDebt.isIOwe) {
        addExpense(
          amount: paymentAmount,
          category: ExpenseCategory.others,
          note: 'Paid debt to ${oldDebt.name}',
          date: DateTime.now(),
          id: 'pay_${newPayment.id}',
        );
      } else {
        _recalculateDisciplineScore();
        notifyListeners();
        generateAICoachFeedback();
      }
    }
  }

  void markDebtAsPaid(String debtId) {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      final oldDebt = _debts[index];
      
      final updatedPayments = List<DebtPayment>.from(oldDebt.payments);
      DebtPayment? newPayment;
      final remainingAmount = oldDebt.remainingAmount;
      if (remainingAmount > 0) {
        newPayment = DebtPayment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: remainingAmount,
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

      if (oldDebt.isIOwe && remainingAmount > 0) {
        addExpense(
          amount: remainingAmount,
          category: ExpenseCategory.others,
          note: 'Paid debt to ${oldDebt.name}',
          date: DateTime.now(),
          id: 'pay_${newPayment!.id}',
        );
      } else {
        _recalculateDisciplineScore();
        notifyListeners();
        generateAICoachFeedback();
      }
    }
  }

  Future<void> deleteDebtPayment(String debtId, String paymentId) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      final oldDebt = _debts[index];
      final paymentIndex = oldDebt.payments.indexWhere((p) => p.id == paymentId);
      if (paymentIndex != -1) {
        final payment = oldDebt.payments[paymentIndex];
        final updatedPayments = List<DebtPayment>.from(oldDebt.payments)..removeAt(paymentIndex);
        final newRemaining = oldDebt.remainingAmount + payment.amount;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final newStatus = newRemaining <= 0.0
            ? DebtStatus.paid
            : (oldDebt.dueDate.isBefore(todayStart) ? DebtStatus.overdue : DebtStatus.pending);

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
        await DatabaseHelper.instance.updateDebt(updatedDebt);
        await DatabaseHelper.instance.deleteDebtPayment(paymentId);

        if (oldDebt.isIOwe) {
          deleteExpense('pay_$paymentId');
        } else {
          _recalculateDisciplineScore();
          notifyListeners();
          generateAICoachFeedback();
        }
      }
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
