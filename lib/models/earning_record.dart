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

  // 将对象转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'work_duration_seconds': workDuration.inSeconds,
      'hourly_rate': hourlyRate,
    };
  }

  // 从 Map 创建对象
  factory EarningRecord.fromMap(Map<String, dynamic> map) {
    return EarningRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      amount: map['amount'],
      workDuration: Duration(seconds: map['work_duration_seconds']),
      hourlyRate: map['hourly_rate'],
    );
  }

  // 将对象列表编码为 JSON 字符串
  static String encode(List<EarningRecord> records) {
    return json.encode(records.map((record) => record.toMap()).toList());
  }

  // 从 JSON 字符串解码对象列表
  static List<EarningRecord> decode(String recordsJson) {
    final List<dynamic> decodedList = json.decode(recordsJson);
    return decodedList.map((item) => EarningRecord.fromMap(item)).toList();
  }
}
