class Loan {
  final int id;
  final int bookId;
  final String studentId;
  final DateTime borrowingDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final double outstandingFine;

  Loan({
    required this.id,
    required this.bookId,
    required this.studentId,
    required this.borrowingDate,
    required this.dueDate,
    this.returnDate,
    this.outstandingFine = 0.0,
  });

  bool get isActive => returnDate == null;

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as int,
      bookId: json['bookId'] as int,
      studentId: json['studentId'] as String,
      borrowingDate: DateTime.parse(
        json['borrowingDate'] as String,
      ),
      dueDate: DateTime.parse(
        json['dueDate'] as String,
      ),
      returnDate: json['returnDate'] == null
          ? null
          : DateTime.parse(
        json['returnDate'] as String,
      ),
      outstandingFine:
      (json['outstandingFine'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'studentId': studentId,
      'borrowingDate': borrowingDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'outstandingFine': outstandingFine,
    };
  }

  Loan copyWith({
    int? id,
    int? bookId,
    String? studentId,
    DateTime? borrowingDate,
    DateTime? dueDate,
    DateTime? returnDate,
    double? outstandingFine,
  }) {
    return Loan(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      studentId: studentId ?? this.studentId,
      borrowingDate: borrowingDate ?? this.borrowingDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      outstandingFine:
      outstandingFine ?? this.outstandingFine,
    );
  }
}