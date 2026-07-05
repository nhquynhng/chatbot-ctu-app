class DocumentSummary {
  final String documentKey;
  final String title;
  final String category;
  final String updatedDate;
  final String department;

  const DocumentSummary({
    required this.documentKey,
    required this.title,
    required this.category,
    required this.updatedDate,
    required this.department,
  });
}
