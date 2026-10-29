import 'package:flutter/material.dart';

import '../models/book.dart';
import '../viewmodels/library_view_model.dart';

class LibraryScreen extends StatefulWidget {
  final LibraryViewModel viewModel;

  const LibraryScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController studentController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadData();
  }

  @override
  void dispose() {
    studentController.dispose();
    super.dispose();
  }

  Future<void> _borrow(Book book) async {
    final studentId =
    studentController.text.trim();

    if (studentId.isEmpty) {
      _showMessage(
        'Masukkan Student ID terlebih dahulu.',
      );
      return;
    }

    final success =
    await widget.viewModel.borrowBook(
      book.id,
      studentId,
    );

    if (success) {
      _showMessage('Buku berhasil dipinjam.'
      );
    } else if (
    widget.viewModel.errorMessage != null) {
      _showMessage(
        widget.viewModel.errorMessage!,
      );
    }
  }

  Future<void> _returnBook(int loanId) async {
    final success =
    await widget.viewModel.returnBook(
      loanId,
    );

    if (success) {
      _showMessage(
        'Buku berhasil dikembalikan.',
      );
    } else if (
    widget.viewModel.errorMessage != null) {
      _showMessage(
        widget.viewModel.errorMessage!,
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatRupiah(double value) {
    return 'Rp${value.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        if (widget.viewModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (widget.viewModel.errorMessage != null &&
            widget.viewModel.books.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'University Library System',
              ),
            ),
            body: Center(
              child: Text(
                widget.viewModel.errorMessage!,
              ),
            ),
          );
        }

        final studentId =
        studentController.text.trim();

        final studentLoans =
        widget.viewModel.getLoansByStudentId(
          studentId,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'University Library System',
            ),
          ),
          body: RefreshIndicator(
            onRefresh:
            widget.viewModel.loadData,
            child: ListView(
              padding:
              const EdgeInsets.all(16),
              children: [
                TextField(
                  controller:
                  studentController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration:
                  const InputDecoration(
                    labelText: 'Student ID',
                    border:
                    OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Available',
                        value:
                        '${widget.viewModel.availableBookCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Borrowed',
                        value:
                        '${widget.viewModel.borrowedBookCount}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Overdue',
                        value:
                        '${widget.viewModel.overdueBookCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Missing',
                        value:
                        '${widget.viewModel.missingBookCount}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding:
                    const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'Total Fine',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatRupiah(
                            widget.viewModel
                                .totalFine,
                          ),
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Book Catalogue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (widget
                    .viewModel.books.isEmpty)
                  const Center(
                    child: Padding(
                      padding:
                      EdgeInsets.all(32),
                      child: Text(
                        'No books available.',
                      ),
                    ),
                  ),

                ...widget.viewModel.books.map(
                      (book) {
                    final status =
                    widget.viewModel
                        .getBookStatus(
                      book,
                    );

                    final loan =
                    widget.viewModel
                        .getActiveLoanForBookAndStudent(
                      book.id,
                      studentId,
                    );

                    final fine = loan == null
                        ? 0.0
                        : widget.viewModel
                        .calculateFine(
                      loan,
                      book,
                    );

                    final availableQuantity =
                    widget.viewModel
                        .getAvailableQuantity(
                      book,
                    );

                    return Card(
                      margin:
                      const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Padding(
                        padding:
                        const EdgeInsets.all(
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              book.title,
                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(book.author),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              'Quantity: '
                                  '${book.quantity}',
                            ),

                            Text(
                              'Available: '
                                  '$availableQuantity',
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              'Status: '
                                  '${status.name.toUpperCase()}',
                            ),

                            if (loan != null) ...[
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                'Student: '
                                    '${loan.studentId}',
                              ),
                              Text(
                                'Due: '
                                    '${_formatDate(
                                  loan.dueDate,
                                )}',
                              ),
                              Text(
                                'Fine: '
                                    '${_formatRupiah(
                                  fine,
                                )}',
                              ),
                            ],

                            const SizedBox(
                              height: 12,
                            ),

                            if (availableQuantity >
                                0)
                              SizedBox(
                                width:
                                double.infinity,
                                child:
                                FilledButton(
                                  onPressed:
                                      () =>
                                      _borrow(
                                        book,
                                      ),
                                  child:
                                  const Text(
                                    'Borrow',
                                  ),
                                ),
                              ),

                            if (loan != null)
                              SizedBox(
                                width:
                                double.infinity,
                                child:
                                FilledButton(
                                  onPressed:
                                      () =>
                                      _returnBook(
                                        loan.id,
                                      ),
                                  child:
                                  const Text(
                                    'Return',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Borrowing Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (studentId.isEmpty)
                  const Text(
                    'Masukkan Student ID untuk '
                        'melihat borrowing records.',
                  )
                else if (studentLoans.isEmpty)
                  const Text(
                    'No borrowing records for '
                        'this Student ID.',
                  ),

                ...studentLoans.map(
                      (loan) {
                    final book =
                    widget.viewModel
                        .getBookById(
                      loan.bookId,
                    );

                    if (book == null) {
                      return const SizedBox
                          .shrink();
                    }

                    final double fine =
                    widget.viewModel
                        .calculateFine(
                      loan,
                      book,
                    );

                    return Card(
                      child: ListTile(
                        title:
                        Text(book.title),
                        subtitle: Text(
                          'Student: ${loan.studentId}\n'
                              'Due: ${_formatDate(loan.dueDate)}\n'
                              'Status: ${widget.viewModel.getOverdueStatus(loan)}\n'
                              'Fine: ${_formatRupiah(fine)}',
                        ),
                        isThreeLine: true,
                        trailing: loan.isActive
                            ? IconButton(
                          icon:
                          const Icon(
                            Icons
                                .assignment_return,
                          ),
                          onPressed:
                              () =>
                              _returnBook(
                                loan.id,
                              ),
                        )
                            : const Icon(
                          Icons
                              .check_circle,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}