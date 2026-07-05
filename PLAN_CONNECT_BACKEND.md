# Plan: Nối Frontend Flutter ↔ Backend FastAPI (RAG trên Qdrant)

## Bối cảnh & trạng thái hiện tại

Pipeline dữ liệu đã xong: PDF → OCR → chunking → embedding (BGE-M3) → **đã nằm trong Qdrant**
(collection `ctu_chunks_bge_m3`, vector 1024 chiều, cosine). Giờ cần lấy dữ liệu đó ra để trả lời user.

Kiểm tra thực tế 2 phía:

- **Backend** (`CSS-CTU-Student-Service/backend/`): chỉ có `schemas/`, `databases/models/`, `enums`
  là có nội dung. Các file cốt lõi để phục vụ truy vấn **đang RỖNG (0 dòng)**:
  `app/main.py`, `app/api/health.py`, `app/core/settings_loader.py`, `app/embedding/embeder.py`,
  `app/vectorstore/qdrant_client.py`, `app/vectorstore/repository.py`,
  `app/retrieval/retriever.py`, `app/llm/prompt.py`, `app/llm/generator.py`.
  → "Connect" ở đây = **viết mới** đường đi query → embed → search Qdrant → LLM → answer, chứ không phải chỉ ráp dây.
- **Frontend** (`myapp/frontend/`): app đã chạy xong nhưng **toàn bộ là mock**
  (`lib/shared/mock/mock_data.dart`). `chat_controller.dart` trả lời giả sau delay 900ms.
  App hiện có **3 tab**: Trang chủ, Chat, **Tài liệu** (đã đổi từ "Lịch sử").
  → App giờ cần **2 nguồn dữ liệu thật** từ backend, không chỉ 1:
  1. **Hỏi–đáp RAG** (tab Chat): câu trả lời + nguồn trích dẫn.
  2. **Duyệt kho tài liệu** (tab Tài liệu): danh sách loại tài liệu → danh sách file trong mỗi loại →
     chi tiết + link + tải PDF. Đây là phần **mới phát sinh** so với bản plan gốc.

Hợp đồng API đã được đặc tả sẵn trong `.docs/spec/ctu-service/06_API_SPEC.md` và `.docs/RAG_RETRIEVAL.md`:
endpoint chính là `POST /api/v1/rag/answer`, cộng thêm nhóm `GET /api/v1/documents...` và `.../assets/{id}/download`.

Mục tiêu: user gõ câu hỏi trong app → gọi backend → backend truy hồi chunk từ Qdrant →
LLM sinh câu trả lời có trích dẫn → app hiển thị answer + khối "Nguồn tham khảo" + màn chi tiết tài liệu;
đồng thời tab Tài liệu duyệt được kho văn bản thật (theo loại) và mở/tải được file PDF gốc.

---

## PHẦN A — BACKEND: cần viết những gì để connect

Chỉ tập trung đường **đọc/trả lời** (student flow). Bỏ qua auth, admin, ingestion vì dữ liệu đã có sẵn trong Qdrant.

### A0. Config & dependencies
- File: `app/core/settings_loader.py` (đang rỗng)
- Dùng `pydantic-settings` đọc từ `.env`. Các biến tối thiểu:
  - `QDRANT_URL` (vd `http://localhost:6333`), `QDRANT_API_KEY` (nếu có), `QDRANT_COLLECTION=ctu_chunks_bge_m3`
  - `EMBEDDING_MODEL=BAAI/bge-m3`, `EMBEDDING_DIM=1024`, `NORMALIZE_EMBEDDINGS=true`
  - `LLM_PROVIDER` + API key (vd OpenAI/Gemini/local) — chọn 1 nhà cung cấp cho MVP
  - `TOP_K=8`, `CORS_ORIGINS`
- Thêm vào `requirements.txt`: `fastapi`, `uvicorn[standard]`, `pydantic-settings`, và SDK LLM đã chọn.
  (`qdrant-client`, `sentence-transformers`, `numpy` đã có sẵn.)

### A1. Embedding query
- File: `app/embedding/embeder.py` (đang rỗng)
- Load `SentenceTransformer("BAAI/bge-m3")` **1 lần** (singleton / lru_cache), `normalize_embeddings=True`.
- Hàm `embed_query(text: str) -> list[float]` trả vector 1024 chiều.
- ⚠️ Query và document phải cùng cấu hình BGE-M3 (đã nêu trong RAG_RETRIEVAL.md).

### A2. Kết nối Qdrant + search
- File: `app/vectorstore/qdrant_client.py` — tạo `QdrantClient` singleton từ config.
- File: `app/vectorstore/repository.py` — hàm `search(vector, top_k, filter)`:
  - Gọi `client.search(collection, query_vector=vector, limit=top_k, query_filter=...)`.
  - **Hard filter** (bắt buộc theo RAG_RETRIEVAL.md) trên payload:
    `review_status=approved`, `validity_status=valid`, `rag_status=published`,
    `effective_date <= today`, `expiry_date null hoặc >= today`.
  - Trả list điểm kèm payload (chunk_id, document_id, version_id, title, heading_path,
    section_title, page_start, page_end, source_file, content, score).

### A3. Retriever (orchestration)
- File: `app/retrieval/retriever.py` (đang rỗng)
- Hàm `retrieve(query, top_k, domain_filter) -> list[RetrievedChunk]`:
  1. `embed_query(query)` (A1)
  2. build Qdrant filter (hard filter + `domain_filter` nếu có) → `repository.search` (A2)
  3. **MVP có thể dừng ở đây** (dense-only). Các bước hybrid BM25, rerank, version-expansion từ
     PostgreSQL, parent-context expansion trong RAG_RETRIEVAL.md để **giai đoạn 2** — không chặn kết nối đầu tiên.
- Trả các chunk kèm đủ metadata để dựng citation.

### A4. Prompt + LLM generation
- File: `app/llm/prompt.py` — system prompt tiếng Việt, kèm quy tắc anti-hallucination:
  chỉ trả lời dựa trên context; nếu không đủ nguồn thì nói "chưa có đủ thông tin"; không bịa phí/hạn/biểu mẫu.
  Ghép context dạng `[nguồn i] {title} - {section} (tr.{page}call): {content}`.
- File: `app/llm/generator.py` — hàm `generate(query, chunks) -> (answer, citations)`:
  - Gọi LLM đã chọn với prompt + context.
  - Dựng `citations` từ chính các chunk đưa vào prompt (không để LLM tự chế citation).

### A5. Schemas request/response cho endpoint
- File mới: `app/schemas/rag.py` (bám đúng `06_API_SPEC.md`):
  - `RagAnswerRequest { query: str; user_role="student"; domain_filter: list[str]=[]; prefer_latest=True; session_id: str|None }`
  - `Citation { document_id; version_id; title; page_start; page_end; section_title; source_file; quote_snippet }`
  - `RagAnswerResponse { answer; citations: list[Citation]; related_assets: list; confidence; retrieval_count; trace_id }`

### A6. API router + app
- File mới: `app/api/rag.py` — `POST /api/v1/rag/answer`:
  gọi `retriever.retrieve` → `generator.generate` → map sang `RagAnswerResponse`.
  Nếu 0 chunk qua filter → trả answer "chưa có đủ thông tin", citations rỗng.
- File: `app/api/health.py` (rỗng) — `GET /health` trả `{"status":"ok"}`.
- File: `app/main.py` (rỗng):
  - Tạo `FastAPI()`, include router `health` và `rag` (prefix `/api/v1`).
  - **Bật CORS** (`CORSMiddleware`) cho origin của Flutter (khi chạy web / hoặc `*` cho dev).
  - Warm-up model embedding ở `startup` để request đầu không bị chậm.

### A7. API kho tài liệu (phục vụ tab Tài liệu)
> Phần này **mới**, để phục vụ tab Tài liệu (duyệt theo loại) + 2 nút ở màn chi tiết.
> Nguồn dữ liệu là **PostgreSQL** (`document_versions`, `documents`, `assets`) — KHÔNG phải Qdrant.
> Cùng hard filter như A2 (chỉ trả tài liệu `published`/`approved`/`valid`/còn hiệu lực).

- File mới: `app/api/documents.py`:
  - `GET /api/v1/document-categories` → danh sách loại tài liệu + số lượng mỗi loại + ngày cập nhật mới nhất.
    Map từ enum `DocumentType` (quyet_dinh, quy_dinh, quy_trinh, huong_dan, thong_bao, thong_tu…).
    Response gợi ý: `[{ "key": "quyet-dinh", "name": "Quyết định", "count": 4, "latest_date": "2023-09-01" }]`
  - `GET /api/v1/documents?document_type=quyet-dinh&q=...` → list file trong 1 loại (có phân trang + tìm kiếm).
    Mỗi item: `{ document_id, title, document_type, updated_date, department }`.
  - `GET /api/v1/documents/{id}` → chi tiết đầy đủ cho màn Chi tiết tài liệu:
    `{ document_id, title, category, page, section, department, updated_date, document_type, code,
       source_url, download_url }`.
    - `source_url` = URL gốc trên web (field `source_url` trong `DocumentVersionMetadata`).
    - `download_url` = link tải file PDF đã lưu (trỏ tới A8, hoặc `related_asset_keys`).
- File: `app/schemas/documents.py` đã có sẵn metadata; chỉ cần thêm schema response gọn cho API (list/detail).

### A8. Tải file PDF (nút "Tải xuống")
- File mới (hoặc trong `documents.py`): `GET /api/v1/documents/{id}/download` **hoặc** `GET /api/v1/assets/{id}/download`.
- Trả về file PDF gốc bằng `FileResponse` (đọc từ `source_path` / `canonical_*` đã lưu trên server),
  header `Content-Disposition: attachment; filename=...`.
- Nếu file không tồn tại → 404 với body lỗi chuẩn.

### A9. Chạy & kiểm thử backend
```bash
cd CSS-CTU-Student-Service/backend
uvicorn app.main:app --reload --port 8000
```
- `GET http://localhost:8000/health` → ok.
- `POST http://localhost:8000/api/v1/rag/answer` với body `{"query":"Xin giấy xác nhận sinh viên cần gì?"}`
  → nhận `answer` + `citations` không rỗng.
- `GET /api/v1/document-categories` → danh sách loại + count.
- `GET /api/v1/documents?document_type=quyet-dinh` → list file.
- `GET /api/v1/documents/{id}` → có `source_url` + `download_url`.
- `GET /api/v1/documents/{id}/download` → tải được file PDF.
- Kiểm tất cả ở `/docs` (Swagger tự sinh).

> Điểm rủi ro cần xác nhận trước khi code A2: **tên các field trong payload Qdrant** phải khớp với lúc index.
> Cần mở Qdrant (hoặc script đã index) xem payload thật có đúng `document_id/title/page_start/...` không,
> nếu khác thì đổi mapping trong `repository.py`.
> Tương tự A7/A8: xác nhận PostgreSQL thật có cột `source_url`, `source_path` và file PDF đã lưu ở đâu.

---

## PHẦN B — FRONTEND: thay đổi gì, ở file nào

Nguyên tắc: **giữ nguyên toàn bộ UI**, chỉ thay nguồn dữ liệu từ mock → HTTP. Model đã gần khớp API nên sửa ít.

### B1. Thêm dependency
- File: `myapp/frontend/pubspec.yaml`
- Thêm dưới `flutter_riverpod`:
  ```yaml
    http: ^1.2.0
  ```
- Chạy `flutter pub get`.
- Với Android emulator: backend `localhost:8000` của máy = **`http://10.0.2.2:8000`** trong app (không phải localhost).
  Thêm `android:usesCleartextTraffic="true"` vào `AndroidManifest.xml` để cho phép HTTP (dev).

### B2. Lớp gọi API (file MỚI)
- File mới: `lib/core/api/api_client.dart`
  - Hằng `baseUrl` (đọc theo nền tảng: `10.0.2.2` cho Android, `localhost` cho web/desktop).
  - Hàm `Future<RagAnswer> answer(String query)`:
    `POST $baseUrl/api/v1/rag/answer`, header `Content-Type: application/json`,
    body `{"query": query}`, parse JSON → model.
  - Bọc try/catch, throw lỗi rõ ràng để controller hiển thị message thân thiện.
- File mới: `lib/shared/models/rag_answer.dart`
  - `RagAnswer { String answer; List<Citation> citations }` + `fromJson`.
  - `Citation { documentId, versionId, title, sectionTitle, pageStart, pageEnd, sourceFile }` + `fromJson`.

### B3. Cập nhật model hiện có để mang đủ dữ liệu
- File: `lib/shared/models/source_ref.dart`
  - Hiện: `{ documentKey, title, section, page }`.
  - Map từ `Citation`: `documentKey = document_id`, `title = title`,
    `section = section_title` (hoặc heading_path), `page = page_start`.
  - Cân nhắc thêm optional field để dựng màn chi tiết mà không cần gọi API thứ 2
    (vd `versionId`, `sourceFile`). Nếu backend chưa trả đủ metadata cho màn chi tiết (department,
    updatedDate, documentType, code) → xem B5.

### B4. Chuyển ChatController sang gọi API thật
- File: `lib/features/chat/chat_controller.dart` — **thay phần mock**:
  - Bỏ `import mock_data.dart` phần `buildMockAnswer`, giữ `kWelcomeMessage` nếu muốn.
  - Constructor nhận `ApiClient` (qua Riverpod `Provider`).
  - Trong `send()`: sau khi thêm bubble user + typing indicator (giữ nguyên UX hiện tại),
    gọi `await api.answer(text)`; xóa typing; thêm `ChatMessage` với `text = res.answer`
    và `sources = res.citations.map(toSourceRef)`.
  - **Xử lý lỗi**: nếu API throw → thay typing bằng bubble bot "Xin lỗi, hệ thống đang gặp sự cố…".
- File: cùng file — sửa `chatControllerProvider` để inject `apiClientProvider`.
- ✅ `chat_screen.dart` **không cần đổi** (nó chỉ đọc state + render `SourceCard`). Đây là lợi ích của việc giữ nguyên shape model.

### B5. Màn chi tiết tài liệu
- File: `lib/features/document/document_detail_screen.dart`
  - Hiện đọc `kMockDocuments[documentKey]`.
  - **Phương án MVP (nhanh)**: dựng `DocumentDetail` tạm từ chính `SourceRef` (title/section/page)
    + để trống các ô metadata chưa có, hoặc hiển thị "—".
  - **Phương án đầy đủ (giai đoạn 2)**: gọi `GET /api/v1/documents/{id}` (endpoint này trong spec
    nhưng backend chưa viết) để lấy department/updatedDate/documentType/code → cần bổ sung
    router `documents` ở backend. Ghi rõ đây là việc thêm nếu muốn 4 ô metadata thật.
- File: `lib/shared/mock/mock_data.dart` — sau khi B4/B5 xong, chỉ còn giữ `kWelcomeMessage`
  và `kSuggestedQuestion`; xóa dần `kMockAnswer`, `kMockSources`, `kMockDocuments`.

### B6. Kiểm thử frontend
- `flutter analyze` sạch.
- Chạy backend (A7) + `flutter run`:
  - Gõ câu hỏi → thấy typing → câu trả lời thật từ Qdrant + khối "Nguồn tham khảo".
  - Bấm card nguồn → mở màn chi tiết (dữ liệu từ citation hoặc API documents).
  - Tắt backend → gửi câu hỏi → hiện thông báo lỗi thân thiện, app không crash.

---

## Thứ tự thực hiện đề xuất

1. **Xác nhận payload Qdrant thật** (mở collection, xem field names) — chặn A2.
2. Backend A0 → A1 → A2 → A3 (dense-only) → A4 → A5 → A6 → chạy A7, test bằng Swagger `/docs`.
3. Frontend B1 → B2 → B3 → B4 → test chat với backend thật (B6).
4. B5 màn chi tiết (MVP trước, đầy đủ sau).
5. Giai đoạn 2 (không chặn): hybrid BM25 + rerank + version-expansion (PostgreSQL) + parent-context,
   endpoint `/documents/{id}`, auth, chat history.

## Các quyết định cần bạn chốt

- **LLM provider**: dùng nhà cung cấp nào cho `generator.py`? (OpenAI / Gemini / model local qua Ollama…)
- **Metadata màn chi tiết**: làm MVP (dựng từ citation, để trống ô thiếu) hay viết luôn `GET /documents/{id}`?
- **Nền tảng chạy app chính**: Android emulator (dùng `10.0.2.2`) hay web/desktop (dùng `localhost`)?
```
