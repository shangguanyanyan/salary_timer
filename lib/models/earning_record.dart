import 'dart:convert';

class EarningRecord {
  final String id;
  final DateTime date;
  final double amount;
  final Duration workDuration;
  final double hourlyRate;

  EarningRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.workDuration,
    required this.hourlyRate,
  });

  // 转换为JSON和从JSON转换的方法
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'amount': amount,
    'workDuration': workDuration.inSeconds,
    'hourlyRate': hourlyRate,
  };

  factory EarningRecord.fromJson(Map<String, dynamic> json) => EarningRecord(
    id: json['id'],
    date: DateTime.parse(json['date']),
    amount: json['amount'],
    workDuration: Duration(seconds: json['workDuration']),
    hourlyRate: json['hourlyRate'],
  );

  static String encode(List<EarningRecord> records) =>
      jsonEncode(records.map((record) => record.toJson()).toList());

  static List<EarningRecord> decode(String records) =>
      (jsonDecode(records) as List)
          .map((item) => EarningRecord.fromJson(item))
          .toList();
}
