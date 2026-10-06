import 'package:flutter/material.dart';

enum HealthGrade {
  excellent,
  good,
  fair,
  needsAttention;

  String get label {
    switch (this) {
      case HealthGrade.excellent:
        return 'Sangat Sehat';
      case HealthGrade.good:
        return 'Sehat';
      case HealthGrade.fair:
        return 'Cukup';
      case HealthGrade.needsAttention:
        return 'Perlu Pembenahan';
    }
  }

  String get gradeLetter {
    switch (this) {
      case HealthGrade.excellent:
        return 'A';
      case HealthGrade.good:
        return 'B';
      case HealthGrade.fair:
        return 'C';
      case HealthGrade.needsAttention:
        return 'D';
    }
  }

  Color get color {
    switch (this) {
      case HealthGrade.excellent:
        return const Color(0xFF10B981); // Emerald
      case HealthGrade.good:
        return const Color(0xFF3B82F6); // Blue
      case HealthGrade.fair:
        return const Color(0xFFF59E0B); // Amber
      case HealthGrade.needsAttention:
        return const Color(0xFFEF4444); // Red
    }
  }
}

class FinancialHealthScore {
  final int overallScore; // 0 - 100
  final HealthGrade grade;
  final double savingsRateScore; // 0 - 35
  final double actualSavingsRate; // e.g. 0.25 for 25%
  final double budgetAdherenceScore; // 0 - 30
  final double budgetUtilizationRate; // e.g. 0.75 for 75%
  final double emergencyBufferScore; // 0 - 20
  final double emergencyBufferMonths; // e.g. 3.5 months
  final double recordingRegularityScore; // 0 - 15
  final int activeRecordingDays; // e.g. 18 days in last 30
  final List<String> recommendations;

  const FinancialHealthScore({
    required this.overallScore,
    required this.grade,
    required this.savingsRateScore,
    required this.actualSavingsRate,
    required this.budgetAdherenceScore,
    required this.budgetUtilizationRate,
    required this.emergencyBufferScore,
    required this.emergencyBufferMonths,
    required this.recordingRegularityScore,
    required this.activeRecordingDays,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'grade': grade.name,
    'savingsRateScore': savingsRateScore,
    'actualSavingsRate': actualSavingsRate,
    'budgetAdherenceScore': budgetAdherenceScore,
    'budgetUtilizationRate': budgetUtilizationRate,
    'emergencyBufferScore': emergencyBufferScore,
    'emergencyBufferMonths': emergencyBufferMonths,
    'recordingRegularityScore': recordingRegularityScore,
    'activeRecordingDays': activeRecordingDays,
    'recommendations': recommendations,
  };

  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScore(
      overallScore: json['overallScore'] as int,
      grade: HealthGrade.values.firstWhere(
        (g) => g.name == json['grade'],
        orElse: () => HealthGrade.fair,
      ),
      savingsRateScore: (json['savingsRateScore'] as num).toDouble(),
      actualSavingsRate: (json['actualSavingsRate'] as num).toDouble(),
      budgetAdherenceScore: (json['budgetAdherenceScore'] as num).toDouble(),
      budgetUtilizationRate: (json['budgetUtilizationRate'] as num).toDouble(),
      emergencyBufferScore: (json['emergencyBufferScore'] as num).toDouble(),
      emergencyBufferMonths: (json['emergencyBufferMonths'] as num).toDouble(),
      recordingRegularityScore: (json['recordingRegularityScore'] as num).toDouble(),
      activeRecordingDays: json['activeRecordingDays'] as int,
      recommendations: List<String>.from(json['recommendations'] as List),
    );
  }
}
