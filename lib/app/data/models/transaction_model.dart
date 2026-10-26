import 'entry_type.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.category,
    required this.account,
    required this.date,
  });

  final int id;
  final EntryType type;
  final double amount;
  final String note;
  final String category;
  final String account;
  final DateTime date; // date only (no time part)

  String get _dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'note': note,
        'category': category,
        'account': account,
        'date': _dateKey,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> j) {
    final d = DateTime.parse(j['date'] as String);
    return TransactionModel(
      id: (j['id'] as num).toInt(),
      type: EntryType.values.byName(j['type'] as String),
      amount: (j['amount'] as num).toDouble(),
      note: (j['note'] as String?) ?? '',
      category: j['category'] as String,
      account: j['account'] as String,
      date: DateTime(d.year, d.month, d.day),
    );
  }
}
