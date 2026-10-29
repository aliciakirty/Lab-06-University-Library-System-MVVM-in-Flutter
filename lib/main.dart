import 'package:flutter/material.dart';

import 'models/library_service.dart';
import 'viewmodels/library_view_model.dart';
import 'views/library_screen.dart';

void main() {
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = LibraryViewModel(
      LibraryService(),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University Library System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: LibraryScreen(
        viewModel: viewModel,
      ),
    );
  }
}