import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/loan.dart';
import '../models/library_service.dart';

class LibraryViewModel extends ChangeNotifier {
  final LibraryService service;

  LibraryViewModel(this.service);

  List<Book> _books = [];
  List<Loan> _loans = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Book> get books => List.unmodifiable(_books);

  List<Loan> get loans => List.unmodifiable(_loans);

  List<Loan> get activeLoans =>
      _loans.where((loan) => loan.isActive).toList();

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get availableBookCount {
    return _books.fold(
      0,
          (total, book) => total + getAvailableQuantity(book),
    );
  }

  int get borrowedBookCount {
    return _loans.where((loan) {
      if (!loan.isActive) return false;

      return getOverdueStatus(loan) == 'Borrowed';
    }).length;
  }

  int get overdueBookCount {
    return _loans.where((loan) {
      if (!loan.isActive) return false;

      return getOverdueStatus(loan) == 'Overdue';
    }).length;
  }

  int get missingBookCount {
    return _loans.where((loan) {
      if (!loan.isActive) return false;

      return getOverdueStatus(loan) == 'Missing';
    }).length;
  }

  double get totalFine {
    double total = 0.0;

    for (final loan in _loans) {
      final book = getBookById(loan.bookId);

      if (book == null) {
        continue;
      }

      if (loan.isActive) {
        total += calculateFine(loan, book);
      } else {
        total += loan.outstandingFine;
      }
    }

    return total;
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _books = await service.getBooks();
      _loans = await service.getLoans();
    } catch (e) {
      _errorMessage = 'Gagal memuat data.';
    }

    _isLoading = false;

    notifyListeners();
  }

  Book? getBookById(int bookId) {
    try {
      return _books.firstWhere(
            (book) => book.id == bookId,
      );
    } catch (_) {
      return null;
    }
  }

  List<Loan> getActiveLoansForBook(int bookId) {
    return _loans
        .where(
          (loan) =>
      loan.bookId == bookId &&
          loan.isActive,
    )
        .toList();
  }

  Loan? getActiveLoanForBook(int bookId) {
    try {
      return _loans.firstWhere(
            (loan) =>
        loan.bookId == bookId &&
            loan.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  List<Loan> getLoansByStudentId(String studentId) {
    final id = studentId.trim();

    if (id.isEmpty) {
      return [];
    }

    return _loans
        .where(
          (loan) => loan.studentId == id,
    )
        .toList();
  }

  Loan? getActiveLoanForBookAndStudent(
      int bookId,
      String studentId,
      ) {
    final id = studentId.trim();

    if (id.isEmpty) {
      return null;
    }

    try {
      return _loans.firstWhere(
            (loan) =>
        loan.bookId == bookId &&
            loan.studentId == id &&
            loan.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  int getBorrowedQuantity(Book book) {
    return getActiveLoansForBook(book.id).length;
  }

  int getAvailableQuantity(Book book) {
    final borrowed = getBorrowedQuantity(book);

    final available = book.quantity - borrowed;

    return available < 0 ? 0 : available;
  }

  BookStatus getBookStatus(Book book) {
    final activeBookLoans =
    getActiveLoansForBook(book.id);

    if (activeBookLoans.isEmpty) {
      return BookStatus.available;
    }

    for (final loan in activeBookLoans) {
      final status = getOverdueStatus(loan);

      if (status == 'Missing') {
        return BookStatus.missing;
      }
    }

    for (final loan in activeBookLoans) {
      final status = getOverdueStatus(loan);

      if (status == 'Overdue') {
        return BookStatus.overdue;
      }
    }

    return BookStatus.borrowed;
  }

  String getOverdueStatus(Loan loan) {
    final book = getBookById(loan.bookId);

    if (book == null) {
      return 'Unknown';
    }

    if (!loan.isActive) {
      return 'Returned';
    }

    final now = DateTime.now();

    if (now.isBefore(loan.dueDate) ||
        _isSameDate(now, loan.dueDate)) {
      return 'Borrowed';
    }

    final missingDate = _addMonths(
      loan.dueDate,
      6,
    );

    if (_isSameDate(now, missingDate) ||
        now.isAfter(missingDate)) {
      return 'Missing';
    }

    return 'Overdue';
  }

  double calculateFine(
      Loan loan,
      Book book,
      ) {
    final calculationDate = loan.returnDate ?? DateTime.now();

    if (calculationDate.isBefore(loan.dueDate) ||
        _isSameDate(calculationDate, loan.dueDate)) {
      return 0.0;
    }

    final missingDate = _addMonths(
      loan.dueDate,
      6,
    );

    if (_isSameDate(calculationDate, missingDate) ||
        calculationDate.isAfter(missingDate)) {
      return book.replacementPrice;
    }

    final difference = _dateOnly(calculationDate).difference(
      _dateOnly(loan.dueDate),
    );

    final completedWeeks = difference.inDays ~/ 7;

    return completedWeeks * 5000.0;
  }

  Future<bool> borrowBook(
      int bookId,
      String studentId,
      ) async {
    if (studentId.trim().isEmpty) {
      _errorMessage =
      'Student ID tidak boleh kosong.';

      notifyListeners();

      return false;
    }

    final book = getBookById(bookId);

    if (book == null) {
      _errorMessage =
      'Buku tidak ditemukan.';

      notifyListeners();

      return false;
    }

    final borrowedQuantity =
    getBorrowedQuantity(book);

    if (borrowedQuantity >= book.quantity) {
      _errorMessage =
      'Semua eksemplar buku sedang dipinjam.';

      notifyListeners();

      return false;
    }

    final now = DateTime.now();

    final dueDate = now.add(
      const Duration(days: 14),
    );

    final newId = _loans.isEmpty
        ? 1
        : _loans
        .map((loan) => loan.id)
        .reduce(
          (a, b) => a > b ? a : b,
    ) +
        1;

    final loan = Loan(
      id: newId,
      bookId: bookId,
      studentId: studentId.trim(),
      borrowingDate: now,
      dueDate: dueDate,
      returnDate: null,
      outstandingFine: 0.0,
    );

    _loans.add(loan);

    await _save();

    _errorMessage = null;

    notifyListeners();

    return true;
  }

  Future<bool> returnBook(int loanId) async {
    final index = _loans.indexWhere(
          (loan) => loan.id == loanId,
    );

    if (index == -1) {
      _errorMessage =
      'Data peminjaman tidak ditemukan.';

      notifyListeners();

      return false;
    }

    final loan = _loans[index];

    final book = getBookById(loan.bookId);

    if (book == null) {
      _errorMessage =
      'Buku tidak ditemukan.';

      notifyListeners();

      return false;
    }

    if (!loan.isActive) {
      _errorMessage =
      'Buku sudah dikembalikan.';

      notifyListeners();

      return false;
    }

    final fine = calculateFine(
      loan,
      book,
    );

    final updatedLoan = loan.copyWith(
      returnDate: DateTime.now(),
      outstandingFine: fine,
    );

    _loans[index] = updatedLoan;

    await _save();

    _errorMessage = null;

    notifyListeners();

    return true;
  }

  Future<void> _save() async {
    await service.saveData(
      books: _books,
      loans: _loans,
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool _isSameDate(
      DateTime first,
      DateTime second,
      ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  DateTime _addMonths(
      DateTime date,
      int months,
      ) {
    final year =
        date.year +
            ((date.month - 1 + months) ~/ 12);

    final month =
        ((date.month - 1 + months) % 12) + 1;

    final lastDayOfMonth = DateTime(
      year,
      month + 1,
      0,
    ).day;

    final day = date.day > lastDayOfMonth
        ? lastDayOfMonth
        : date.day;

    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
    );
  }
}