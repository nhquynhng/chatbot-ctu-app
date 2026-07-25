# Chạy app theo từng môi trường

App chọn địa chỉ backend qua [`lib/core/network/api_config.dart`](lib/core/network/api_config.dart):

1. Nếu có `--dart-define=API_BASE_URL=...` → dùng giá trị đó.
2. Nếu không: web/desktop → `http://localhost:8000`, Android → `http://10.0.2.2:8000`.

Không cần sửa code để đổi môi trường — chỉ đổi cách chạy.

## Backend (chạy trước, luôn giống nhau)

Backend phải lắng nghe trên `0.0.0.0` để emulator và điện thoại thật kết nối được (không dùng `127.0.0.1`).

```powershell
# Kích hoạt venv (ở root workspace)
.\.venv\Scripts\Activate.ps1

# Hạ tầng
cd CSS-CTU-Student-Service
docker compose up -d postgres qdrant tei

# Backend
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Kiểm tra: `curl http://localhost:8000/health` → `{"status":"ok"}`.

## Bảng tóm tắt

| Môi trường       | Lệnh                                                           | baseUrl thực tế         | Điều kiện thêm                  |
| ------------------- | --------------------------------------------------------------- | ------------------------- | ----------------------------------- |
| Android Emulator    | `flutter run -d emulator-5554`                                | `http://10.0.2.2:8000`  | —                                  |
| Flutter Web         | `flutter run -d chrome`                                       | `http://localhost:8000` | Backend đã bật CORS              |
| Điện thoại thật | `flutter run --dart-define=API_BASE_URL=http://<IP-LAN>:8000` | IP LAN của host          | Cùng WiFi + mở firewall port 8000 |

## 1. Android Emulator

Emulator có alias `10.0.2.2` trỏ về `localhost` của máy host. Đây đã là mặc định cho Android — không cần truyền gì.

```powershell
flutter run -d emulator-5554
```

## 2. Flutter Web (Chrome / Edge)

Web chạy ngay trên host nên `localhost` là đúng (mặc định). Backend **phải bật CORS** thì trình duyệt mới cho gọi — đã cấu hình sẵn `CORSMiddleware` trong `app/main.py` (cho phép mọi origin `localhost` / `127.0.0.1` ở port bất kỳ).

```powershell
flutter run -d chrome
```

## 3. Điện thoại thật (USB hoặc cùng WiFi)

`10.0.2.2` và `localhost` đều vô nghĩa với điện thoại thật. Phải trỏ tới **IP LAN của máy host**, và hai thiết bị phải cùng mạng WiFi.

Lấy IP host:

```powershell
ipconfig
```

Tìm `IPv4 Address` của card WiFi (ví dụ `192.168.1.50`), rồi chạy:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://192.168.1.50:8000
```

Lưu ý:

- **Firewall Windows** phải cho phép port 8000. Lần đầu chạy uvicorn thường hiện popup — chọn Allow cho Private network.
- `usesCleartextTraffic="true"` đã bật trong `AndroidManifest.xml` nên `http://` không bị chặn.
- Đổi WiFi → IP host đổi → chạy lại với IP mới.

## VS Code launch configs

`.vscode/launch.json` có sẵn 3 cấu hình: **App: Android Emulator**, **App: Flutter Web (Chrome)**, **App: Điện thoại thật (LAN)**. Chọn từ dropdown Run and Debug rồi bấm chạy.

> Cấu hình "Điện thoại thật" đang gán cứng IP mẫu `192.168.1.50` — sửa lại đúng IP host của bạn trong `.vscode/launch.json` (mục `toolArgs`) trước khi dùng.
