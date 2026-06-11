import 'package:flutter/material.dart';

enum DebtStatus {
  pending,
  overdue,
  paid,
}

extension DebtStatusExtension on DebtStatus {
  String get displayName {
    switch (this) {
      case DebtStatus.pending:
        return 'Pending';
      case DebtStatus.overdue:
        return 'Overdue';
      case DebtStatus.paid:
        return 'Fully Paid';
    }
  }

  Color get color {
    switch (this) {
      case DebtStatus.pending:
        return const Color(0xFFF2C94C); // Warning Yellow
      case DebtStatus.overdue:
        return const Color(0xFFEB5757); // Danger Red
      case DebtStatus.paid:
        return const Color(0xFF27AE60); // Success Green
    }
  }
}

class DebtPayment {
  final String id;
  final double amount;
  final DateTime date;

  DebtPayment({
    required this.id,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap(String debtId) {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}

class Debt {
  final String id;
  final String name;
  final double originalAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final bool isIOwe; // true if 'I Owe', false if 'They Owe Me'
  final DebtStatus status;
  final List<DebtPayment> payments;

  Debt({
    required this.id,
    required this.name,
    required this.originalAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.isIOwe,
    required this.status,
    this.payments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'originalAmount': originalAmount,
      'remainingAmount': remainingAmount,
      'dueDate': dueDate.toIso8601String(),
      'isIOwe': isIOwe ? 1 : 0,
      'status': status.name,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map, List<DebtPayment> paymentsList) {
    final originalAmount = (map['originalAmount'] as num).toDouble();
    final remainingAmount = (map['remainingAmount'] as num).toDouble();
    final dueDate = DateTime.parse(map['dueDate'] as String);
    final isIOwe = (map['isIOwe'] as int) == 1;
    
    var status = DebtStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => DebtStatus.pending,
    );

    if (remainingAmount <= 0.0) {
      status = DebtStatus.paid;
    } else {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      if (dueDate.isBefore(todayStart)) {
        status = DebtStatus.overdue;
      }
    }

    return Debt(
      id: map['id'] as String,
      name: map['name'] as String,
      originalAmount: originalAmount,
      remainingAmount: remainingAmount,
      dueDate: dueDate,
      isIOwe: isIOwe,
      status: status,
      payments: paymentsList,
    );
  }

  double get progressPercentage {
    if (originalAmount == 0) return 0.0;
    final paidAmount = originalAmount - remainingAmount;
    return (paidAmount / originalAmount).clamp(0.0, 1.0);
  }

  static List<Debt> get mockDebts {
    final now = DateTime.now();
    return [
      // I Owe
      Debt(
        id: 'd1',
        name: 'Kuya Jobert',
        originalAmount: 1500.00,
        remainingAmount: 500.00,
        dueDate: now.add(const Duration(days: 4)),
        isIOwe: true,
        status: DebtStatus.pending,
        payments: [
          DebtPayment(id: 'p1', amount: 1000.00, date: now.subtract(const Duration(days: 2))),
        ],
      ),
      Debt(
        id: 'd2',
        name: 'Landlord (Boarding House)',
        originalAmount: 3500.00,
        remainingAmount: 3500.00,
        dueDate: now.subtract(const Duration(days: 3)),
        isIOwe: true,
        status: DebtStatus.overdue,
        payments: [],
      ),
      Debt(
        id: 'd3',
        name: 'Ate Sarah',
        originalAmount: 400.00,
        remainingAmount: 0.00,
        dueDate: now.subtract(const Duration(days: 5)),
        isIOwe: true,
        status: DebtStatus.paid,
        payments: [
          DebtPayment(id: 'p2', amount: 400.00, date: now.subtract(const Duration(days: 5))),
        ],
      ),
      // They Owe Me
      Debt(
        id: 'd4',
        name: 'Mark Reyes',
        originalAmount: 500.00,
        remainingAmount: 200.00,
        dueDate: now.add(const Duration(days: 6)),
        isIOwe: false,
        status: DebtStatus.pending,
        payments: [
          DebtPayment(id: 'p3', amount: 300.00, date: now.subtract(const Duration(days: 1))),
        ],
      ),
      Debt(
        id: 'd5',
        name: 'Julia Santos',
        originalAmount: 800.00,
        remainingAmount: 800.00,
        dueDate: now.subtract(const Duration(days: 1)),
        isIOwe: false,
        status: DebtStatus.overdue,
        payments: [],
      ),
    ];
  }
}
