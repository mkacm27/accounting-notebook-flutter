import 'package:flutter_quill/flutter_quill.dart';

enum ToolType { journal, amortization, customTable }

class Subject {
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.title,
    this.description,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Subject copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class Lesson {
  final String id;
  final String subjectId;
  final String title;
  final List<String> tags;
  final String content; // Quill Delta JSON
  final DateTime createdAt;
  final DateTime updatedAt;

  Lesson({
    required this.id,
    required this.subjectId,
    required this.title,
    this.tags = const [],
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Lesson copyWith({
    String? id,
    String? subjectId,
    String? title,
    List<String>? tags,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'tags': tags,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class JournalEntry {
  final String id;
  final DateTime date;
  final String accountDebit;
  final String accountCredit;
  final double debitAmount;
  final double creditAmount;
  final String description;
  final List<String> tags;

  JournalEntry({
    required this.id,
    required this.date,
    required this.accountDebit,
    required this.accountCredit,
    required this.debitAmount,
    required this.creditAmount,
    required this.description,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'accountDebit': accountDebit,
      'accountCredit': accountCredit,
      'debitAmount': debitAmount,
      'creditAmount': creditAmount,
      'description': description,
      'tags': tags,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      accountDebit: json['accountDebit'],
      accountCredit: json['accountCredit'],
      debitAmount: json['debitAmount'].toDouble(),
      creditAmount: json['creditAmount'].toDouble(),
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class AmortizationSchedule {
  final String id;
  final String assetName;
  final DateTime purchaseDate;
  final double assetValue;
  final int usefulLifeYears;
  final String method; // 'straight-line' or 'declining-balance'
  final double salvageValue;
  final String periodicity; // 'annual' or 'monthly'
  final List<String> tags;
  final List<AmortizationPeriod> schedule;

  AmortizationSchedule({
    required this.id,
    required this.assetName,
    required this.purchaseDate,
    required this.assetValue,
    required this.usefulLifeYears,
    required this.method,
    required this.salvageValue,
    required this.periodicity,
    this.tags = const [],
    required this.schedule,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetName': assetName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'assetValue': assetValue,
      'usefulLifeYears': usefulLifeYears,
      'method': method,
      'salvageValue': salvageValue,
      'periodicity': periodicity,
      'tags': tags,
      'schedule': schedule.map((p) => p.toJson()).toList(),
    };
  }

  factory AmortizationSchedule.fromJson(Map<String, dynamic> json) {
    return AmortizationSchedule(
      id: json['id'],
      assetName: json['assetName'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      assetValue: json['assetValue'].toDouble(),
      usefulLifeYears: json['usefulLifeYears'],
      method: json['method'],
      salvageValue: json['salvageValue'].toDouble(),
      periodicity: json['periodicity'],
      tags: List<String>.from(json['tags'] ?? []),
      schedule: (json['schedule'] as List)
          .map((p) => AmortizationPeriod.fromJson(p))
          .toList(),
    );
  }
}

class AmortizationPeriod {
  final String period;
  final double expense;
  final double accumulated;

  AmortizationPeriod({
    required this.period,
    required this.expense,
    required this.accumulated,
  });

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'expense': expense,
      'accumulated': accumulated,
    };
  }

  factory AmortizationPeriod.fromJson(Map<String, dynamic> json) {
    return AmortizationPeriod(
      period: json['period'],
      expense: json['expense'].toDouble(),
      accumulated: json['accumulated'].toDouble(),
    );
  }
}

class CustomTableData {
  final String id;
  final String name;
  final List<TableColumn> columns;
  final List<List<dynamic>> rows;
  final List<String> tags;

  CustomTableData({
    required this.id,
    required this.name,
    required this.columns,
    required this.rows,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'columns': columns.map((c) => c.toJson()).toList(),
      'rows': rows,
      'tags': tags,
    };
  }

  factory CustomTableData.fromJson(Map<String, dynamic> json) {
    return CustomTableData(
      id: json['id'],
      name: json['name'],
      columns: (json['columns'] as List)
          .map((c) => TableColumn.fromJson(c))
          .toList(),
      rows: (json['rows'] as List).map((r) => List<dynamic>.from(r)).toList(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class TableColumn {
  final String name;
  final String type; // 'text', 'number', 'date', 'currency'

  TableColumn({
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
    };
  }

  factory TableColumn.fromJson(Map<String, dynamic> json) {
    return TableColumn(
      name: json['name'],
      type: json['type'],
    );
  }
}

class EmbeddedTool {
  final String id;
  final String lessonId;
  final String toolType;
  final String toolData; // JSON data
  final int position;
  final DateTime createdAt;

  EmbeddedTool({
    required this.id,
    required this.lessonId,
    required this.toolType,
    required this.toolData,
    required this.position,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'toolType': toolType,
      'toolData': toolData,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmbeddedTool.fromJson(Map<String, dynamic> json) {
    return EmbeddedTool(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      toolType: json['toolType'] as String,
      toolData: json['toolData'] as String,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
