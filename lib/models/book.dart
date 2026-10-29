enum BookStatus {
  available,
  borrowed,
  overdue,
  missing,
}

class Book {
  final int id;
  final String title;
  final String author;
  final double replacementPrice;
  final int quantity;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.replacementPrice,
    required this.quantity,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String,
      replacementPrice:
      (json['replacementPrice'] as num).toDouble(),
      quantity:
      (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'replacementPrice': replacementPrice,
      'quantity': quantity,
    };
  }
}