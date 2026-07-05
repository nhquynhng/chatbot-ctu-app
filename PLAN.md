# Plan: CTU Student Service — Flutter chatbot app (UI + mock data)

## Context

Người dùng cần một app chatbot Flutter cho "CTU Student Service" — hỗ trợ sinh viên tra cứu thủ tục, quy định, biểu mẫu. Đây là bản dựng UI-first: **toàn bộ dữ liệu là mock trong app**, chưa nối backend (backend RAG đã tồn tại trong repo nhưng để nối sau).

Thư mục `myapp/frontend/` hiện chỉ có scaffold Android trống (chưa có `pubspec.yaml` hay `lib/`), nên đây là tạo project Flutter mới từ đầu tại đó. Tài liệu thiết kế repo (`CSS-CTU-Student-Service/.docs/FRONTEND_FLUTTER.md`) quy định dùng **Flutter + Riverpod**, theme xanh CTU, và luôn hiển thị nguồn/citation gần mỗi câu trả lời — plan này bám theo.

Kết quả mong muốn: app chạy được trên Android emulator với 3 màn hình dựa đúng theo ảnh mẫu.

## Phạm vi (theo ảnh mẫu)

3 màn hình chính (bottom nav 3 tab: Trang chủ / Chat / Lịch sử — **tab Lịch sử để placeholder, không làm màn hình thật**):

1. **Trang chủ** — header xanh gradient (logo + "ĐẠI HỌC CẦN THƠ", tiêu đề "CTU Student Service", mô tả, nút toggle dark mode), card giới thiệu "CTU Bot" với lời chào + chip gợi ý ("Xin giấy xác nhận cần làm gì?") + trạng thái "Đang soạn...", nút lớn "Bắt đầu hỏi →".
2. **Chat** — header xanh ("CTU Student Service" + chấm "Trực tuyến" + avatar "CTU"), danh sách bong bóng hội thoại, khối **"Nguồn tham khảo"** dưới câu trả lời bot (các card tài liệu: tiêu đề, mục, số trang, mũi tên → điều hướng), ô nhập "Nhập câu hỏi của bạn..." + nút gửi tròn.
3. **Chi tiết tài liệu** — header xanh ("Nguồn tham khảo / Chi tiết tài liệu" + nút back + share), card badge "Quy trình hành chính" + tiêu đề + "Trang / Mục", lưới 4 ô metadata (Đơn vị, Ngày cập nhật, Loại tài liệu, Mã tài liệu), nút "← Quay lại cuộc trò chuyện".

## Kiến trúc

Project mới tại `myapp/frontend/`. Cấu trúc `lib/` theo feature-first (rút gọn từ doc):

```
lib/
├── main.dart                      # ProviderScope + MyApp
├── app.dart                       # MaterialApp, theme, routing
├── core/
│   ├── theme/app_theme.dart       # màu xanh CTU, light/dark, text styles
│   └── widgets/                   # bong bóng chat, badge, section header dùng chung
├── features/
│   ├── shell/home_shell.dart      # Scaffold + BottomNavigationBar (3 tab)
│   ├── home/home_screen.dart
│   ├── chat/
│   │   ├── chat_screen.dart
│   │   ├── chat_controller.dart   # Riverpod StateNotifier: messages, gửi câu hỏi (mock reply)
│   │   └── widgets/ (message_bubble.dart, source_card.dart, typing_indicator.dart)
│   └── document/document_detail_screen.dart
└── shared/
    ├── models/                    # ChatMessage, SourceRef, DocumentDetail
    └── mock/mock_data.dart        # dữ liệu giả: câu hỏi mẫu, câu trả lời, nguồn, chi tiết tài liệu
```

**State management:** Riverpod (theo doc). `chat_controller.dart` giữ list `ChatMessage`; khi gửi câu hỏi → thêm message user → hiển thị typing → sau delay ngắn trả về câu trả lời mock kèm `List<SourceRef>`.

**Routing:** dùng `Navigator` cơ bản (push màn hình Chi tiết tài liệu từ Chat). Không cần go_router cho scope này; dùng `MaterialPageRoute`. Bottom nav dùng `IndexedStack` để giữ state giữa các tab.

## Data models (mock, mô phỏng shape backend)

Bám theo schema backend đã có (`backend/app/schemas/documents.py`, `assets.py`) để sau này dễ nối API:

- `ChatMessage { String id; bool isUser; String text; List<SourceRef> sources; bool isTyping }`
- `SourceRef { String documentKey; String title; String section; int page }` — ứng với citation (title/section/page trong doc schema `citation_type: page`).
- `DocumentDetail { String documentKey; String category; String title; int page; String section; String department; String updatedDate; String documentType; String code }` — map từ `DocumentMetadata` (department, document_type, code, effective_date...).

`mock_data.dart` chứa: 1 kịch bản hội thoại mẫu (câu hỏi "Xin giấy xác nhận..." + câu trả lời có 2 nguồn), và map `documentKey → DocumentDetail` cho 2 tài liệu trong ảnh ("Quy trình cấp giấy xác nhận sinh viên", "Hướng dẫn sử dụng cổng dịch vụ sinh viên").

## Theme

- Màu chính: xanh CTU (~`#1A5FC4` / `#0B4DA2` cho gradient header). Nền sáng `#F5F7FA`, card trắng bo góc lớn (16–20), shadow nhẹ.
- Hỗ trợ light/dark (nút toggle mặt trăng ở Trang chủ) qua `ThemeMode` provider — làm ở mức cơ bản.
- Font: mặc định (Roboto). Ưu tiên dễ đọc, spacing thoáng theo UX rules trong doc.

## Các bước thực hiện

1. `cd myapp/frontend && flutter create . --project-name myapp --platforms android` (điền vào scaffold sẵn có; giữ thư mục android hiện tại).
2. Thêm `flutter_riverpod` vào `pubspec.yaml`, `flutter pub get`.
3. Viết `core/theme/app_theme.dart` (light + dark, màu CTU).
4. Viết models + `mock/mock_data.dart`.
5. Viết `home_shell.dart` (bottom nav 3 tab, IndexedStack).
6. Viết `home_screen.dart` theo ảnh 1.
7. Viết `chat_controller.dart` + `chat_screen.dart` + widgets (bubble, source_card, typing) theo ảnh 2.
8. Viết `document_detail_screen.dart` theo ảnh 4; nối điều hướng từ source_card.
9. `main.dart` / `app.dart` ráp lại với `ProviderScope`.

## Critical files (đã tạo)

- `myapp/frontend/pubspec.yaml`
- `myapp/frontend/lib/main.dart`, `app.dart`
- `lib/core/theme/app_theme.dart`
- `lib/features/shell/home_shell.dart`, `app_state.dart`
- `lib/features/home/home_screen.dart`
- `lib/features/chat/chat_screen.dart`, `chat_controller.dart`, `widgets/`
- `lib/features/document/document_detail_screen.dart`
- `lib/shared/mock/mock_data.dart`, `lib/shared/models/`

## Verification

- `flutter analyze` — không lỗi.
- `flutter run` trên emulator `Small_Phone:5554` và kiểm tra thủ công:
  - Trang chủ hiển thị đúng header + card CTU Bot; nút "Bắt đầu hỏi" → chuyển sang tab Chat.
  - Chat: gửi câu hỏi → thấy bong bóng user, typing, rồi câu trả lời + khối "Nguồn tham khảo".
  - Click card nguồn → mở màn Chi tiết tài liệu với đúng metadata; nút "Quay lại cuộc trò chuyện" → về Chat.
  - Toggle dark mode ở Trang chủ đổi theme toàn app.

## Trạng thái: ĐÃ HOÀN THÀNH

App đã build + chạy trên emulator-5554, `flutter analyze` sạch (no issues).
