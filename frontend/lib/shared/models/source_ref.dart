class SourceRef {
  final String documentKey;
  final String versionKey;
  final String chunkKey;
  final String title;
  final String section;
  final int page;
  final int? pageEnd;

  /// Đường dẫn file gốc trên server (có thể là PDF gốc hoặc markdown canonical).
  final String sourceFile;

  /// Ngày ban hành dạng ISO (`yyyy-MM-dd`), `null` khi chưa cập nhật.
  final String? issuedDate;

  /// Đơn vị chịu trách nhiệm ban hành, `null` khi chưa cập nhật.
  final String? issuingAuthority;

  /// Loại tài liệu (ví dụ "Quyết định"), `null` khi chưa cập nhật.
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
      page: json['page_start'] as int? ?? 0,
      pageEnd: json['page_end'] as int?,
      sourceFile: json['source_file'] as String? ?? '',
      issuedDate: _emptyToNull(json['issued_date'] as String?),
      issuingAuthority: _emptyToNull(json['issuing_authority'] as String?),
      documentType: _emptyToNull(json['document_type'] as String?),
    );
  }

  static String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Hiển thị "Trang 4" hoặc "Trang 4–6" khi có dải trang.
  String get pageLabel {
    if (page <= 0) return '';
    final end = pageEnd;
    if (end != null && end > page) return 'Trang $page–$end';
    return 'Trang $page';
  }

  static const _notAvailable = 'Chưa cập nhật';

  /// Tên file gốc (chỉ phần cuối đường dẫn), ví dụ `QD3266_....pdf`.
  /// Trả "Chưa cập nhật" khi không có đường dẫn.
  String get sourceFileNameLabel {
    final path = sourceFile.trim();
    if (path.isEmpty) return _notAvailable;
    final segments = path.split(RegExp(r'[/\\]'));
    final name = segments.isEmpty ? path : segments.last;
    return name.isEmpty ? _notAvailable : name;
  }

  /// Ngày ban hành dạng `dd/MM/yyyy`, hoặc "Chưa cập nhật" khi thiếu/không hợp lệ.
  String get issuedDateLabel {
    final raw = issuedDate;
    if (raw == null) return _notAvailable;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
  }

  /// Đơn vị chịu trách nhiệm, hoặc "Chưa cập nhật" khi thiếu.
  String get issuingAuthorityLabel => issuingAuthority ?? _notAvailable;

  /// Loại tài liệu, hoặc "Chưa cập nhật" khi thiếu.
  String get documentTypeLabel => documentType ?? _notAvailable;
}
