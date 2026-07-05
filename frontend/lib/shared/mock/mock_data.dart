import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../models/document_category.dart';
import '../models/document_detail.dart';
import '../models/document_summary.dart';
import '../models/source_ref.dart';

const kSuggestedQuestion = 'Xin giấy xác nhận cần làm gì?';

const kFaqQuestions = <String>[
  'Cách xem điểm rèn luyện?',
  'Thủ tục xin học bổng?',
  'Cách đăng ký học phần?',
];

const _quyTrinhKey = 'QT-SV-003-2024';
const _huongDanKey = 'HD-SV-002-2024';

const kMockSources = <SourceRef>[
  SourceRef(
    documentKey: _quyTrinhKey,
    title: 'Quy trình cấp giấy xác nhận sinh viên',
    section: 'Mục 3. Trình tự thực hiện',
    page: 4,
  ),
  SourceRef(
    documentKey: _huongDanKey,
    title: 'Hướng dẫn sử dụng cổng dịch vụ sinh viên',
    section: 'Mục 2. Các bước thực hiện',
    page: 8,
  ),
];

const kMockAnswer =
    'Để xin giấy xác nhận sinh viên, bạn đăng nhập cổng dịch vụ sinh viên, '
    'chọn mục "Giấy xác nhận", điền thông tin và gửi yêu cầu. Sau khi được '
    'duyệt, bạn có thể nhận giấy trực tiếp tại Phòng Công tác Sinh viên '
    '(Nhà A, phòng 101) hoặc qua email.';

const kWelcomeMessage = ChatMessage(
  id: 'welcome',
  isUser: false,
  text: 'Xin chào! Tôi có thể giúp gì cho bạn?',
);

ChatMessage buildMockAnswer(String id) => ChatMessage(
      id: id,
      isUser: false,
      text: kMockAnswer,
      sources: kMockSources,
    );

const kDocumentLatestUpdate = '10/01/2024';

const kDocumentCategories = <DocumentCategory>[
  DocumentCategory(
    key: 'quyet-dinh',
    name: 'Quyết định',
    description: 'Quyết định ban hành quy chế, chính sách',
    latestDate: '01/09/2023',
    icon: Icons.gavel,
    color: AppColors.amber,
    bg: AppColors.amberBg,
  ),
  DocumentCategory(
    key: 'quy-dinh',
    name: 'Quy định',
    description: 'Quy định đào tạo trình độ đại học',
    latestDate: '15/06/2023',
    icon: Icons.verified_user_outlined,
    color: AppColors.badgeGreen,
    bg: AppColors.badgeGreenBg,
  ),
  DocumentCategory(
    key: 'quy-trinh',
    name: 'Quy trình',
    description: 'Quy trình công tác đánh giá',
    latestDate: '30/08/2023',
    icon: Icons.format_list_numbered,
    color: AppColors.primary,
    bg: AppColors.chipBg,
  ),
  DocumentCategory(
    key: 'huong-dan',
    name: 'Hướng dẫn',
    description: 'Hướng dẫn sử dụng dịch vụ sinh viên',
    latestDate: '02/01/2024',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF8E5FE0),
    bg: Color(0xFFF0EAFB),
  ),
];

const kDocumentsByCategory = <String, List<DocumentSummary>>{
  'quyet-dinh': [
    DocumentSummary(
      documentKey: 'QD-QC-2023',
      title: 'Quyết định ban hành quy chế học vụ năm học 2023-2024',
      category: 'Quyết định',
      updatedDate: '01/09/2023',
      department: 'Ban Giám hiệu',
    ),
    DocumentSummary(
      documentKey: 'QD-MGHP-2023',
      title: 'Quyết định về việc miễn, giảm học phí cho sinh viên khó khăn',
      category: 'Quyết định',
      updatedDate: '12/09/2023',
      department: 'Ban Giám hiệu',
    ),
    DocumentSummary(
      documentKey: 'QD-HB-2024',
      title: 'Quyết định thành lập Hội đồng xét học bổng',
      category: 'Quyết định',
      updatedDate: '10/05/2024',
      department: 'Ban Giám hiệu',
    ),
  ],
  'quy-dinh': [
    DocumentSummary(
      documentKey: 'QD-DT-001-2023',
      title: 'Quy định đào tạo trình độ đại học',
      category: 'Quy định',
      updatedDate: '15/06/2023',
      department: 'Phòng Đào tạo',
    ),
    DocumentSummary(
      documentKey: 'QD-RL-2023',
      title: 'Quy định về đánh giá kết quả rèn luyện của sinh viên',
      category: 'Quy định',
      updatedDate: '20/07/2023',
      department: 'Phòng Công tác Sinh viên',
    ),
  ],
  'quy-trinh': [
    DocumentSummary(
      documentKey: _quyTrinhKey,
      title: 'Quy trình công tác đánh giá điểm rèn luyện',
      category: 'Quy trình',
      updatedDate: '30/08/2023',
      department: 'Phòng Công tác Sinh viên',
    ),
  ],
  'huong-dan': [
    DocumentSummary(
      documentKey: _huongDanKey,
      title: 'Hướng dẫn sử dụng cổng dịch vụ sinh viên',
      category: 'Hướng dẫn',
      updatedDate: '02/01/2024',
      department: 'Trung tâm Quản lý CNTT',
    ),
  ],
};

const Map<String, DocumentDetail> kMockDocuments = {
  _quyTrinhKey: DocumentDetail(
    documentKey: _quyTrinhKey,
    category: 'Quy trình hành chính',
    title: 'Quy trình cấp giấy xác nhận sinh viên',
    page: 4,
    section: 'Mục 3. Trình tự thực hiện',
    department: 'Phòng Công tác Sinh viên',
    updatedDate: '15/03/2024',
    documentType: 'Quy trình nội bộ',
    code: 'QT-SV-003-2024',
    sourceUrl: 'https://ctu.edu.vn/vanban/QT-SV-003-2024.pdf',
    pdfFileName: 'QT-SV-003-2024.pdf',
  ),
  _huongDanKey: DocumentDetail(
    documentKey: _huongDanKey,
    category: 'Hướng dẫn sử dụng',
    title: 'Hướng dẫn sử dụng cổng dịch vụ sinh viên',
    page: 8,
    section: 'Mục 2. Các bước thực hiện',
    department: 'Trung tâm Quản lý CNTT',
    updatedDate: '02/01/2024',
    documentType: 'Tài liệu hướng dẫn',
    code: 'HD-SV-002-2024',
    sourceUrl: 'https://ctu.edu.vn/vanban/HD-SV-002-2024.pdf',
    pdfFileName: 'HD-SV-002-2024.pdf',
  ),
};
