class Book {
  const Book({required this.path, required this.title});

  final String path;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book && other.path == path && other.title == title);

  @override
  int get hashCode => Object.hash(path, title);
}
