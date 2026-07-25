# Plan: Xây dựng backend FastAPI cho CTU Student Service (RAG + Document Catalog)

## Context

`myapp/backend` hiện đang **rỗng hoàn toàn**. Frontend Flutter (`myapp/frontend`) đã build xong UI với 3 tab (Trang chủ / Chat / Tài liệu) nhưng đang dùng mock data, chưa gọi API thật. Có một repo tham khảo (`CSS-CTU-Student-Service/backend`, sibling repo, không nằm trong `myapp`) đã có một số phần được implement (SQLAlchemy models, chunking, embedding qua NVIDIA API, Qdrant repository) nhưng cấu trúc rời rạc, nhiều file rỗng, và có một số mâu thuẫn giữa README/plan cũ và code thật (ví dụ: README nói dùng `sentence-transformers` local nhưng code thật dùng `NVIDIAEmbeddings`/`ChatNVIDIA` qua API).

Mục tiêu của plan này: dựng một backend **mới, gọn, đúng với thực tế stack đã chọn** trong `myapp/backend`, đủ để:
1. Trả lời câu hỏi của sinh viên qua RAG (embed câu hỏi → tìm trong Qdrant → sinh câu trả lời có trích dẫn nguồn) — phục vụ tab Chat.
2. Cung cấp API duyệt/tải văn bản (danh mục, danh sách, chi tiết, download PDF) từ Postgres — phục vụ tab Tài liệu.

Không nằm trong phạm vi: đăng nhập/phân quyền, các API quản trị/ingestion (pipeline nạp dữ liệu chạy offline, không lộ qua API), retrieval hybrid (BM25+RRF) — MVP chỉ dùng dense vector search, để dành cho giai đoạn sau.

Quyết định đã chốt với người dùng:
- Xây trong `myapp/backend` (thư mục rỗng), không tái sử dụng nguyên trạng cấu trúc của repo sibling.
- Giữ nguyên hướng dùng **NVIDIA hosted API** cho cả embedding (`NVIDIAEmbeddings`, model `baai/bge-m3`) và sinh câu trả lời (`ChatNVIDIA`), không chuyển sang sentence-transformers local.
- Scope gồm cả RAG answer path và Document catalog/download.

## Stack

- **API**: FastAPI + Uvicorn
- **RAG orchestration**: LangChain (`langchain-nvidia-ai-endpoints`, `langchain-text-splitters`)
- **Metadata DB**: PostgreSQL qua SQLAlchemy 2.0 (async, `asyncpg`) + Alembic migrations, schema `css`
- **Vector DB**: Qdrant (`qdrant-client`)
- **Config**: `pydantic-settings` đọc từ `.env`
- **Test**: `pytest` + `pytest-asyncio` + `httpx` (test client cho FastAPI)

## Cấu trúc thư mục

```
backend/
├── .env.example
├── .gitignore
├── requirements.txt
├── alembic.ini
├── pytest.ini
├── README.md
├── alembic/
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
│       └── 0001_create_core_tables.py
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── health.py
│   │       ├── rag.py
│   │       └── documents.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── logging.py
│   ├── databases/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── session.py
│   │   └── models/
│   │       ├── __init__.py
│   │       ├── enums.py
│   │       ├── documents.py
│   │       └── assets.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── rag.py
│   │   └── documents.py
│   ├── embedding/
│   │   ├── __init__.py
│   │   └── embedder.py
│   ├── vectorstore/
│   │   ├── __init__.py
│   │   ├── client.py
│   │   └── repository.py
│   ├── retrieval/
│   │   ├── __init__.py
│   │   └── retriever.py
│   ├── llm/
│   │   ├── __init__.py
│   │   ├── prompts.py
│   │   └── generator.py
│   └── services/
│       ├── __init__.py
│       ├── rag_service.py
│       └── document_service.py
└── test/
    ├── __init__.py
    ├── conftest.py
    ├── api/
    │   ├── test_health.py
    │   ├── test_rag.py
    │   └── test_documents.py
    ├── services/
    │   ├── test_rag_service.py
    │   └── test_document_service.py
    ├── retrieval/
    │   └── test_retriever.py
    └── vectorstore/
        └── test_repository.py
```

## Chi tiết từng file

### Root

**`requirements.txt`** — pin phiên bản cụ thể:
```
fastapi==0.115.6
uvicorn[standard]==0.34.0
pydantic==2.10.4
pydantic-settings==2.7.0
sqlalchemy==2.0.36
asyncpg==0.30.0
alembic==1.14.0
python-dotenv==1.0.1
qdrant-client==1.12.1
langchain-nvidia-ai-endpoints==0.3.9
langchain-text-splitters==0.3.4
langchain-core==0.3.28
pytest==8.3.4
pytest-asyncio==0.25.0
httpx==0.28.1
```

**`.env.example`**:
```
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/ctu_service
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=
QDRANT_COLLECTION=ctu_chunks
NVIDIA_API_KEY=
NVIDIA_EMBEDDING_MODEL=baai/bge-m3
NVIDIA_LLM_MODEL=qwen/qwen3-next-80b-a3b-instruct
TOP_K=8
CORS_ORIGINS=http://localhost:3000,http://10.0.2.2
ASSET_STORAGE_DIR=./storage/assets
```

**`alembic.ini`**, **`alembic/env.py`**, **`alembic/script.py.mako`** — cấu hình Alembic chuẩn, `env.py` đọc `DATABASE_URL` từ settings (`app.core.config.settings`), target `app.databases.base.Base.metadata`, schema `css`.

**`alembic/versions/0001_create_core_tables.py`** — migration đầu tiên tạo schema `css` và các bảng: `departments`, `document_types`, `documents`, `document_versions`, `document_chunks`, `assets`, `document_assets`. Khớp với models ở `app/databases/models/`.

**`pytest.ini`** — `asyncio_mode = auto`, `testpaths = test`.

### `app/core/`

**`config.py`** — `Settings(BaseSettings)` đọc toàn bộ biến env ở `.env.example` (database_url, qdrant_url, qdrant_api_key, qdrant_collection, nvidia_api_key, nvidia_embedding_model, nvidia_llm_model, top_k: int, cors_origins: list[str], asset_storage_dir). Expose singleton `settings = Settings()`. Mọi module khác import `from app.core.config import settings`.

**`logging.py`** — `setup_logging()` gọi `logging.basicConfig` với format chuẩn, gọi 1 lần trong `main.py` lúc startup.

### `app/databases/`

**`base.py`** — `Base = declarative_base()` hoặc `DeclarativeBase` với `metadata = MetaData(schema="css")`.

**`session.py`** — tạo `async_engine = create_async_engine(settings.database_url)`, `AsyncSessionLocal = async_sessionmaker(...)`, hàm `get_db() -> AsyncGenerator[AsyncSession, None]` dùng làm FastAPI dependency (yield session, đảm bảo close).

**`models/enums.py`** — các Python `Enum`/SQLAlchemy Enum dùng chung: `DocumentTypeEnum`, `ReviewStatus` (draft/approved), `RagStatus` (draft/published), `ValidityStatus` (valid/expired).

**`models/documents.py`** — ORM classes: `Department` (id, code, name), `DocumentType` (id, code, name), `Document` (id, department_id, document_type_id, title, code, created_at), `DocumentVersion` (id, document_id, version_no, review_status, rag_status, validity_status, effective_date, expiry_date, source_file, updated_at) — đây là bảng quyết định filter cho RAG.

**`models/assets.py`** — `Asset` (id, document_version_id, file_type, storage_path, original_filename), `DocumentAsset` liên kết nếu cần nhiều asset/document (hoặc gộp thẳng vào `Asset` nếu 1-1, tuỳ đơn giản hoá — ưu tiên gộp vì scope không có ingestion phức tạp).

### `app/schemas/`

**`rag.py`** — Pydantic DTOs cho `/api/v1/rag/answer`:
- `RagAnswerRequest`: `query: str`, `user_role: str = "student"`, `domain_filter: list[str] = []`, `prefer_latest: bool = True`, `session_id: str | None = None`
- `Citation`: `document_id`, `version_id`, `title`, `page_start`, `page_end`, `section_title`, `source_file`, `quote_snippet`
- `RagAnswerResponse`: `answer: str`, `citations: list[Citation]`, `related_assets: list[str]`, `confidence: float`, `retrieval_count: int`, `trace_id: str`

**`documents.py`** — DTOs cho catalog:
- `DocumentCategory`: `key`, `name`, `count`, `latest_date`
- `DocumentListItem`: `document_id`, `title`, `document_type`, `updated_date`, `department`
- `DocumentDetail`: thêm `category`, `page`, `section`, `code`, `source_url`, `download_url`
- `PaginatedDocuments`: `items: list[DocumentListItem]`, `total: int`, `page: int`, `page_size: int`

### `app/embedding/embedder.py`

Hàm/class `Embedder` bọc `NVIDIAEmbeddings(model=settings.nvidia_embedding_model, api_key=settings.nvidia_api_key)` (singleton, khởi tạo 1 lần lúc app startup, lưu vào `app.state`). Expose `embed_query(text: str) -> list[float]`. Không cần cache JSON phức tạp như repo tham khảo — MVP chỉ query-time embedding, không ingest trong scope này.

### `app/vectorstore/`

**`client.py`** — `get_qdrant_client() -> QdrantClient` singleton factory dùng `settings.qdrant_url` + `settings.qdrant_api_key`.

**`repository.py`** — `search_points(client, collection, vector, top_k, filters: dict) -> list[QdrantSearchResult]`, build Qdrant `Filter` từ `review_status=approved`, `rag_status=published`, `validity_status=valid`, `effective_date<=today`, `expiry_date is null or >=today`, cộng thêm `domain_filter` nếu có. `QdrantSearchResult` dataclass: `chunk_id, document_id, version_id, title, heading_path, section_title, page_start, page_end, source_file, content, score`.

### `app/retrieval/retriever.py`

Hàm `retrieve(query: str, top_k: int, domain_filter: list[str]) -> list[QdrantSearchResult]`: gọi `embedder.embed_query(query)` → `vectorstore.repository.search_points(...)`. Đây là lớp orchestration thuần, không phụ thuộc FastAPI.

### `app/llm/`

**`prompts.py`** — `RAG_ANSWER_PROMPT: ChatPromptTemplate` (tiếng Việt), system prompt có rule chống bịa (chỉ trả lời dựa trên context được cung cấp, nói rõ nếu không tìm thấy thông tin, luôn trích dẫn theo `(nguồn: tên tài liệu, trang X)`).

**`generator.py`** — `Generator` bọc `ChatNVIDIA(model=settings.nvidia_llm_model, api_key=settings.nvidia_api_key)`. Hàm `generate(query: str, chunks: list[QdrantSearchResult]) -> tuple[str, list[Citation]]`: build context string từ chunks, invoke prompt + LLM, build citations trực tiếp từ chunks đã dùng (không để LLM tự bịa citation).

### `app/services/`

**`rag_service.py`** — `answer_question(db: AsyncSession, request: RagAnswerRequest) -> RagAnswerResponse`: gọi `retriever.retrieve()` → `generator.generate()` → tính `confidence` (ví dụ dựa trên score trung bình top-k) → query `related_assets` từ Postgres qua `document_id` các citation → build `trace_id` (uuid4) → trả `RagAnswerResponse`. Đây là nơi duy nhất nối retrieval + llm + db.

**`document_service.py`** — 3 hàm nghiệp vụ thuần SQLAlchemy, mỗi hàm nhận `db: AsyncSession`:
- `list_categories(db) -> list[DocumentCategory]`: group by `document_type`, count + latest `updated_date`.
- `list_documents(db, document_type: str | None, q: str | None, page: int, page_size: int) -> PaginatedDocuments`: filter + ILIKE search trên title + phân trang.
- `get_document_detail(db, document_id: int) -> DocumentDetail | None`: join `Document` + `DocumentVersion` + `Asset` để lấy `download_url`.
- `get_asset_path(db, document_id: int) -> Path | None`: trả đường dẫn file thật trên `settings.asset_storage_dir` để `api/v1/documents.py` dùng `FileResponse`.

### `app/api/`

**`deps.py`** — re-export `get_db` từ `app.databases.session`, và (nếu cần) dependency lấy `Embedder`/`Generator` singleton từ `request.app.state`.

**`v1/health.py`** — `GET /health` trả `{"status": "ok"}`, không phụ thuộc DB/Qdrant (health check thuần).

**`v1/rag.py`** — `POST /rag/answer`: nhận `RagAnswerRequest`, gọi `rag_service.answer_question(db, request)`, trả `RagAnswerResponse`. Bắt lỗi lên `HTTPException(502)` nếu NVIDIA API hoặc Qdrant lỗi.

**`v1/documents.py`** — 4 route:
- `GET /document-categories` → `document_service.list_categories`
- `GET /documents?document_type=&q=&page=&page_size=` → `document_service.list_documents`
- `GET /documents/{document_id}` → `document_service.get_document_detail`, 404 nếu None
- `GET /documents/{document_id}/download` → `document_service.get_asset_path`, `FileResponse(path)`, 404 nếu None/file không tồn tại

### `app/main.py`

App factory `create_app() -> FastAPI`:
1. `setup_logging()`
2. Tạo `FastAPI(title="CTU Student Service API")`
3. Thêm `CORSMiddleware` với `allow_origins=settings.cors_origins`
4. `@app.on_event("startup")`: khởi tạo `Embedder`, `Generator`, `QdrantClient` singleton, gán vào `app.state`
5. `include_router` cho `health`, `rag`, `documents` dưới prefix `/api/v1` (health có thể để root `/health` không prefix, tuỳ style — giữ `/health` không prefix để dễ dùng cho healthcheck của hạ tầng)
6. Module-level `app = create_app()` để `uvicorn app.main:app` chạy được

### `test/`

**`conftest.py`** — fixture `client: AsyncClient` (httpx, dùng `ASGITransport` trỏ vào `app`), fixture `db_session` (nếu test cần Postgres thật — có thể dùng SQLite in-memory cho unit test service layer đơn giản, hoặc mark integration test cần Postgres thật chạy riêng).

**`api/test_health.py`** — gọi `GET /health`, assert 200 + `{"status": "ok"}`.

**`api/test_rag.py`** — mock `rag_service.answer_question`, gọi `POST /api/v1/rag/answer`, assert response shape đúng schema.

**`api/test_documents.py`** — mock `document_service`, test 4 route trả đúng status code (200/404) và shape.

**`services/test_rag_service.py`** — mock `retriever.retrieve` và `generator.generate`, assert `answer_question` build đúng `RagAnswerResponse`, đặc biệt confidence/trace_id.

**`services/test_document_service.py`** — test trực tiếp trên DB test (SQLite/Postgres test container) với data mẫu, assert filter/pagination/join đúng.

**`retrieval/test_retriever.py`** — mock `embedder` và `vectorstore.repository`, assert `retrieve()` gọi đúng tham số filter.

**`vectorstore/test_repository.py`** — test hàm build Qdrant `Filter` (input ngày hiệu lực/hết hạn → output filter đúng), không cần Qdrant thật.

## Thứ tự triển khai đề xuất

1. `requirements.txt`, `.env.example`, `core/config.py`, `core/logging.py` — nền tảng, chạy được `import app.core.config` không lỗi.
2. `databases/base.py`, `session.py`, `models/*`, alembic migration — chạy `alembic upgrade head` thành công trên Postgres local/test.
3. `schemas/rag.py`, `schemas/documents.py` — validate được bằng test import đơn giản.
4. `vectorstore/client.py`, `repository.py` + test filter (không cần Qdrant thật cho unit test filter-building).
5. `embedding/embedder.py`, `llm/prompts.py`, `llm/generator.py` — có thể test bằng cách gọi thật với `NVIDIA_API_KEY` (integration, không bắt buộc CI).
6. `retrieval/retriever.py` — nối embedder + vectorstore, test bằng mock.
7. `services/rag_service.py`, `services/document_service.py` — nối tất cả layer.
8. `api/deps.py`, `api/v1/health.py`, `api/v1/rag.py`, `api/v1/documents.py`, `main.py` — wiring cuối cùng.
9. Viết test song song mỗi bước, không dồn về cuối.

## Kiểm thử / Verification

- `pip install -r requirements.txt` chạy sạch trong venv mới.
- `alembic upgrade head` chạy thành công trên Postgres local (cần `DATABASE_URL` thật trong `.env`).
- `pytest` chạy toàn bộ `test/`, ưu tiên các test không cần network (mock NVIDIA/Qdrant) pass trước, sau đó chạy riêng test integration (cần `NVIDIA_API_KEY` + Qdrant thật) nếu có sẵn credentials.
- `uvicorn app.main:app --reload --port 8000`, dùng Swagger UI (`/docs`) để tay gọi `GET /health`, `POST /api/v1/rag/answer` (cần Qdrant có data thật để có kết quả nghĩa), `GET /api/v1/document-categories`.
- Sau khi backend chạy, cập nhật frontend (`myapp/frontend`) đổi từ mock data sang gọi HTTP thật — nằm ngoài phạm vi plan này nhưng là bước tiếp theo tự nhiên (đã có phân tích sẵn trong `PLAN_CONNECT_BACKEND.md` phần B).
