import 'package:flutter_test/flutter_test.dart';

import '../lib/models/book.dart';
import '../lib/models/loan.dart';
import '../lib/models/library_service.dart';
import '../lib/viewmodels/library_view_model.dart';

class FakeLibraryService extends LibraryService {
  List<Book> testBooks = [];
  List<Loan> testLoans = [];

  @override
  Future<List<Book>> getBooks() async {
    return List<Book>.from(testBooks);
  }

  @override
  Future<List<Loan>> getLoans() async {
    return List<Loan>.from(testLoans);
  }

  @override
  Future<void> saveData({
    required List<Book> books,
    required List<Loan> loans,
  }) async {
    testBooks = List<Book>.from(books);
    testLoans = List<Loan>.from(loans);
  }
}

Book createBook({
  int id = 1,
  String title = 'Flutter Basics',
  double price = 100000,
  int quantity = 2,
}) {
  return Book(
    id: id,
    title: title,
    author: 'John Doe',
    replacementPrice: price,
    quantity: quantity,
  );
}

Loan createLoan({
  int id = 1,
  int bookId = 1,
  String studentId = 'STD001',
  DateTime? borrowingDate,
  DateTime? dueDate,
  DateTime? returnDate,
  double outstandingFine = 0,
}) {
  return Loan(
    id: id,
    bookId: bookId,
    studentId: studentId,
    borrowingDate: borrowingDate ?? DateTime(2026, 9, 1),
    dueDate: dueDate ?? DateTime(2026, 10, 1),
    returnDate: returnDate,
    outstandingFine: outstandingFine,
  );
}

Future<LibraryViewModel> createViewModel({
  List<Book>? books,
  List<Loan>? loans,
}) async {
  final service = FakeLibraryService();

  service.testBooks = books ??
      [
        createBook(
          id: 1,
          title: 'Flutter Basics',
          price: 100000,
          quantity: 2,
        ),
        createBook(
          id: 2,
          title: 'Dart Programming',
          price: 150000,
          quantity: 1,
        ),
      ];

  service.testLoans = loans ?? [];

  final viewModel = LibraryViewModel(service);

  await viewModel.loadData();

  return viewModel;
}

void main() {
  group('LibraryViewModel - Book Catalogue', () {
    test('1. Book catalogue displays books correctly', () async {
      final viewModel = await createViewModel();

      expect(viewModel.books.length, 2);
      expect(viewModel.books[0].title, 'Flutter Basics');
      expect(viewModel.books[1].title, 'Dart Programming');
    });

    test('2. Available quantity is correct', () async {
      final viewModel = await createViewModel();

      expect(
        viewModel.getAvailableQuantity(viewModel.books[0]),
        2,
      );

      expect(
        viewModel.getAvailableQuantity(viewModel.books[1]),
        1,
      );
    });
  });

  group('LibraryViewModel - Borrowing', () {
    test('3. Available book can be borrowed', () async {
      final viewModel = await createViewModel();

      final result = await viewModel.borrowBook(
        1,
        'STD001',
      );

      expect(result, isTrue);
      expect(viewModel.activeLoans.length, 1);

      final loan = viewModel.activeLoans.first;

      expect(loan.bookId, 1);
      expect(loan.studentId, 'STD001');
      expect(loan.returnDate, isNull);
    });

    test('4. Borrowing decreases available quantity', () async {
      final viewModel = await createViewModel();

      expect(
        viewModel.getAvailableQuantity(viewModel.books[0]),
        2,
      );

      await viewModel.borrowBook(
        1,
        'STD001',
      );

      expect(
        viewModel.getAvailableQuantity(viewModel.books[0]),
        1,
      );
    });

    test(
      '5. Book cannot be borrowed when all copies are borrowed',
          () async {
        final viewModel = await createViewModel(
          books: [
            createBook(
              id: 1,
              quantity: 1,
            ),
          ],
        );

        final firstBorrow = await viewModel.borrowBook(
          1,
          'STD001',
        );

        final secondBorrow = await viewModel.borrowBook(
          1,
          'STD002',
        );

        expect(firstBorrow, isTrue);
        expect(secondBorrow, isFalse);
        expect(viewModel.activeLoans.length, 1);
      },
    );

    test(
      '6. Multiple copies can be borrowed independently',
          () async {
        final viewModel = await createViewModel();

        final firstBorrow = await viewModel.borrowBook(
          1,
          'STD001',
        );

        final secondBorrow = await viewModel.borrowBook(
          1,
          'STD002',
        );

        expect(firstBorrow, isTrue);
        expect(secondBorrow, isTrue);
        expect(viewModel.activeLoans.length, 2);

        expect(
          viewModel.getAvailableQuantity(viewModel.books[0]),
          0,
        );
      },
    );

    test('7. Invalid book cannot be borrowed', () async {
      final viewModel = await createViewModel();

      final result = await viewModel.borrowBook(
        999,
        'STD001',
      );

      expect(result, isFalse);
      expect(viewModel.activeLoans, isEmpty);
    });

    test('8. Empty student ID cannot borrow', () async {
      final viewModel = await createViewModel();

      final result = await viewModel.borrowBook(
        1,
        '',
      );

      expect(result, isFalse);
      expect(viewModel.activeLoans, isEmpty);
    });
  });

  group('LibraryViewModel - Due Date', () {
    test('9. New loan has a correct due date', () async {
      final viewModel = await createViewModel();

      await viewModel.borrowBook(
        1,
        'STD001',
      );

      final loan = viewModel.activeLoans.first;

      expect(
        loan.dueDate.difference(loan.borrowingDate).inDays,
        14,
      );
    });
  });

  group('LibraryViewModel - Return', () {
    test('10. Existing loan can be returned', () async {
      final viewModel = await createViewModel();

      await viewModel.borrowBook(
        1,
        'STD001',
      );

      final loanId = viewModel.activeLoans.first.id;

      final result = await viewModel.returnBook(
        loanId,
      );

      expect(result, isTrue);
      expect(viewModel.activeLoans, isEmpty);

      final returnedLoan = viewModel.loans.firstWhere(
            (loan) => loan.id == loanId,
      );

      expect(returnedLoan.returnDate, isNotNull);
    });

    test(
      '11. Returning a book removes it from active loans',
          () async {
        final viewModel = await createViewModel();

        await viewModel.borrowBook(
          1,
          'STD001',
        );

        final loanId = viewModel.activeLoans.first.id;

        await viewModel.returnBook(loanId);

        expect(viewModel.activeLoans, isEmpty);
      },
    );

    test(
      '12. Returning a book restores available quantity',
          () async {
        final viewModel = await createViewModel();

        await viewModel.borrowBook(
          1,
          'STD001',
        );

        expect(
          viewModel.getAvailableQuantity(
            viewModel.books[0],
          ),
          1,
        );

        final loanId = viewModel.activeLoans.first.id;

        await viewModel.returnBook(loanId);

        expect(
          viewModel.getAvailableQuantity(
            viewModel.books[0],
          ),
          2,
        );
      },
    );

    test('13. Invalid loan cannot be returned', () async {
      final viewModel = await createViewModel();

      final result = await viewModel.returnBook(999);

      expect(result, isFalse);
    });
  });

  group('LibraryViewModel - Fine Calculation', () {
    test('14. On-time return has Rp0 fine', () async {
      final book = createBook(
        id: 1,
        price: 100000,
      );

      final loan = createLoan(
        dueDate: DateTime(2026, 10, 1),
        returnDate: DateTime(2026, 10, 1),
      );

      final viewModel = await createViewModel(
        books: [book],
        loans: [loan],
      );

      expect(
        viewModel.calculateFine(loan, book),
        0.0,
      );
    });

    test('15. Six days overdue has Rp0 fine', () async {
      final book = createBook(
        id: 1,
        price: 100000,
      );

      final loan = createLoan(
        dueDate: DateTime(2026, 10, 1),
        returnDate: DateTime(2026, 10, 7),
      );

      final viewModel = await createViewModel(
        books: [book],
        loans: [loan],
      );

      expect(
        viewModel.calculateFine(loan, book),
        0.0,
      );
    });

    test(
      '16. One completed week overdue charges Rp5000',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final loan = createLoan(
          dueDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 8),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.calculateFine(loan, book),
          5000.0,
        );
      },
    );

    test(
      '17. Two completed weeks overdue charges Rp10000',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final loan = createLoan(
          dueDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 15),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.calculateFine(loan, book),
          10000.0,
        );
      },
    );

    test(
      '18. Three completed weeks overdue charges Rp15000',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final loan = createLoan(
          dueDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 22),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.calculateFine(loan, book),
          15000.0,
        );
      },
    );

    test(
      '19. Incomplete overdue week does not add another fine',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final loan = createLoan(
          dueDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 14),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.calculateFine(loan, book),
          5000.0,
        );
      },
    );

    test(
      '20. Six-month overdue uses replacement price',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final loan = createLoan(
          dueDate: DateTime(2026, 1, 15),
          returnDate: DateTime(2026, 7, 15),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.calculateFine(loan, book),
          100000.0,
        );
      },
    );
  });

  group('LibraryViewModel - Status', () {
    test(
      '21. Active loan before due date is Borrowed',
          () async {
        final book = createBook(
          id: 1,
        );

        final now = DateTime.now();

        final loan = createLoan(
          dueDate: DateTime(
            now.year,
            now.month,
            now.day + 10,
          ),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.getOverdueStatus(loan),
          'Borrowed',
        );
      },
    );

    test(
      '22. Active loan after due date is Overdue',
          () async {
        final book = createBook(
          id: 1,
        );

        final now = DateTime.now();

        final loan = createLoan(
          dueDate: DateTime(
            now.year,
            now.month,
            now.day - 10,
          ),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.getOverdueStatus(loan),
          'Overdue',
        );
      },
    );

    test(
      '23. Active loan at six-month threshold is Missing',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final now = DateTime.now();

        final dueDate = DateTime(
          now.year,
          now.month - 6,
          now.day,
        );

        final loan = createLoan(
          dueDate: dueDate,
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.getOverdueStatus(loan),
          'Missing',
        );
      },
    );
  });

  group('LibraryViewModel - Fine Summary', () {
    test(
      '24. Total fine includes active overdue loan',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final now = DateTime.now();

        final loan = createLoan(
          dueDate: DateTime(
            now.year,
            now.month,
            now.day - 8,
          ),
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.totalFine,
          5000.0,
        );
      },
    );

    test(
      '25. Outstanding fine remains after returned loan',
          () async {
        final book = createBook(
          id: 1,
          price: 100000,
        );

        final loan = createLoan(
          dueDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 8),
          outstandingFine: 5000,
        );

        final viewModel = await createViewModel(
          books: [book],
          loans: [loan],
        );

        expect(
          viewModel.totalFine,
          5000.0,
        );
      },
    );
  });

  group('LibraryViewModel - State Updates', () {
    test(
      '26. notifyListeners is called after borrowing',
          () async {
        final viewModel = await createViewModel();

        var notificationCount = 0;

        viewModel.addListener(() {
          notificationCount++;
        });

        await viewModel.borrowBook(
          1,
          'STD001',
        );

        expect(
          notificationCount,
          greaterThan(0),
        );
      },
    );

    test(
      '27. notifyListeners is called after returning',
          () async {
        final viewModel = await createViewModel();

        await viewModel.borrowBook(
          1,
          'STD001',
        );

        final loanId = viewModel.activeLoans.first.id;

        var notificationCount = 0;

        viewModel.addListener(() {
          notificationCount++;
        });

        await viewModel.returnBook(loanId);

        expect(
          notificationCount,
          greaterThan(0),
        );
      },
    );
  });

  group('LibraryViewModel - Book Status', () {
    test(
      '28. Available book status is available',
          () async {
        final viewModel = await createViewModel();

        final book = viewModel.books.first;

        expect(
          viewModel.getBookStatus(book),
          BookStatus.available,
        );
      },
    );

    test(
      '29. Borrowed book status is borrowed',
          () async {
        final viewModel = await createViewModel(
          books: [
            createBook(
              id: 1,
              quantity: 1,
            ),
          ],
        );

        await viewModel.borrowBook(
          1,
          'STD001',
        );

        final book = viewModel.books.first;

        expect(
          viewModel.getBookStatus(book),
          BookStatus.borrowed,
        );
      },
    );
  });
}