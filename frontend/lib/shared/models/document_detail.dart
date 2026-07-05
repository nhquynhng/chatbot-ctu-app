class DocumentDetail {
  final String documentKey;
  final String category;
  final String title;
  final int page;
  final String section;
  final String department;
  final String updatedDate;
  final String documentType;
  final String code;
  final String sourceUrl;
  final String pdfFileName;

  const DocumentDetail({
    required this.documentKey,
    required this.category,
    required this.title,
    required this.page,
    required this.section,
    required this.department,
    required this.updatedDate,
    required this.documentType,
    required this.code,
    this.sourceUrl = '',
    this.pdfFileName = '',
  });
}
