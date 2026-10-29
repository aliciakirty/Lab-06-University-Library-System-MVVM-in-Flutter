import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'book.dart';
import 'loan.dart';

class LibraryService {
  static const String assetPath = 'assets/data/library.json';
  static const String localFileName = 'library.json';

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$localFileName');
  }

  Future<void> _createInitialFileIfNeeded() async {
    final file = await _getLocalFile();

    if (!await file.exists()) {
      final initialData = await rootBundle.loadString(assetPath);
      await file.writeAsString(initialData);
    }
  }

  Future<Map<String, dynamic>> _readJson() async {
    await _createInitialFileIfNeeded();

    final file = await _getLocalFile();
    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return {
        'books': [],
        'loans': [],
      };
    }

    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<void> _writeJson(Map<String, dynamic> data) async {
    final file = await _getLocalFile();

    final content = const JsonEncoder.withIndent('  ').convert(data);

    await file.writeAsString(content);
  }

  Future<List<Book>> getBooks() async {
    final data = await _readJson();

    final books = data['books'] as List<dynamic>? ?? [];

    return books
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Loan>> getLoans() async {
    final data = await _readJson();

    final loans = data['loans'] as List<dynamic>? ?? [];

    return loans
        .map((item) => Loan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveData({
    required List<Book> books,
    required List<Loan> loans,
  }) async {
    await _writeJson({
      'books': books.map((book) => book.toJson()).toList(),
      'loans': loans.map((loan) => loan.toJson()).toList(),
    });
  }

  int calculateFine({
    required DateTime dueDate,
    required DateTime returnDate,
    required int replacementPrice,
  }) {
    final overdueDays = returnDate.difference(dueDate).inDays;

    if (overdueDays <= 6) {
      return 0;
    }

    if (overdueDays >= 180) {
      return replacementPrice + (26 * 5000);
    }

    final completedWeeks = overdueDays ~/ 7;

    return completedWeeks * 5000;
  }
}