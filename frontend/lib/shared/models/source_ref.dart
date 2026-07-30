class SourceRef {
  final String documentKey;
  final String versionKey;
  final String chunkKey;
  final String title;
  final String section;
  final int page;
  final int? pageEnd;

  /// Tên file nguồn dùng để hiển thị, ví dụ `stsv-2026.pdf`.
  final String sourceFile;

  /// Link trang web chứa tài liệu gốc.
  final String? sourceUrl;

  /// Object key của file PDF/file gốc trên Cloudflare R2.
  final String? sourcePath;

  /// Object key của file Markdown OCR trên Cloudflare R2.
  final String? canonicalMarkdownPath;

  /// Ngày ban hành dạng ISO (`yyyy-MM-dd`).
  final String? issuedDate;

  /// Đơn vị chịu trách nhiệm ban hành.
  final String? issuingAuthority;

  /// Loại tài liệu, ví dụ `Quyết định`.
  final String? documentType;

  const SourceRef({
    required this.documentKey,
    required this.versionKey,
    required this.chunkKey,
    required this.title,
    required this.section,
    required this.page,
    this.pageEnd,
    this.sourceFile = '',
    this.sourceUrl,
    this.sourcePath,
    this.canonicalMarkdownPath,
    this.issuedDate,
    this.issuingAuthority,
    this.documentType,
  });

  factory SourceRef.fromCitationJson(Map<String, dynamic> json) {
    return SourceRef(
      documentKey: json['document_key'] as String? ?? '',
      versionKey: json['version_key'] as String? ?? '',
      chunkKey: json['chunk_key'] as String? ?? '',
      title: json['title'] as String? ?? 'Tài liệu tham khảo',
      section: json['citation'] as String? ?? '',
      page: _toInt(json['page_start']) ?? 0,
      pageEnd: _toInt(json['page_end']),
      sourceFile: json['source_file'] as String? ?? '',
      sourceUrl: _emptyToNull(json['source_url'] as String?),
      sourcePath: _emptyToNull(json['source_path'] as String?),
      canonicalMarkdownPath: _emptyToNull(
        json['canonical_markdown_path'] as String?,
      ),
      issuedDate: _emptyToNull(json['issued_date'] as String?),
      issuingAuthority: _emptyToNull(
        json['issuing_authority'] as String?,
      ),
      documentType: _emptyToNull(json['document_type'] as String?),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _emptyToNull(String? value) {
    if (value == null) return null;

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Có trang web nguồn để mở trực tiếp.
  bool get hasSourceUrl => sourceUrl != null;

  /// Có PDF hoặc file nguồn trên Cloudflare R2.
  bool get hasSourceFile => sourcePath != null;

  /// Có bản Markdown OCR trên Cloudflare R2.
  bool get hasCanonicalMarkdown => canonicalMarkdownPath != null;

  /// Hiển thị `Trang 4` hoặc `Trang 4–6`.
  String get pageLabel {
    if (page <= 0) return '';

    final end = pageEnd;
    if (end != null && end > page) {
      return 'Trang $page–$end';
    }

    return 'Trang $page';
  }

  static const String _notAvailable = 'Chưa cập nhật';

  /// Tên file gốc để hiển thị.
  String get sourceFileNameLabel {
    final explicitName = sourceFile.trim();
    if (explicitName.isNotEmpty) {
      return _extractFileName(explicitName);
    }

    final path = sourcePath;
    if (path != null) {
      return _extractFileName(path);
    }

    return _notAvailable;
  }

  /// Tên file OCR để hiển thị.
  String get canonicalMarkdownFileNameLabel {
    final path = canonicalMarkdownPath;
    if (path == null) return _notAvailable;

    return _extractFileName(path);
  }

  static String _extractFileName(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return _notAvailable;
    }

    final withoutQuery = normalized.split('?').first;
    final segments = withoutQuery.split(RegExp(r'[/\\]'));
    final name = segments.isEmpty ? withoutQuery : segments.last;

    return name.isEmpty ? _notAvailable : name;
  }

  /// Ngày ban hành dạng `dd/MM/yyyy`.
  String get issuedDateLabel {
    final raw = issuedDate;
    if (raw == null) return _notAvailable;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${twoDigits(parsed.day)}/'
        '${twoDigits(parsed.month)}/'
        '${parsed.year}';
  }

  /// Đơn vị chịu trách nhiệm.
  String get issuingAuthorityLabel {
    return issuingAuthority ?? _notAvailable;
  }

  /// Loại tài liệu.
  String get documentTypeLabel {
    return documentType ?? _notAvailable;
  }
}