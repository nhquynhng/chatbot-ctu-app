# Flutter Development Requirements

## Bắt buộc (Required)

### 1. Flutter SDK
- Tải từ: https://docs.flutter.dev/get-started/install
- Thêm Flutter vào PATH environment variable

### 2. Dart SDK
- Được bao gồm trong Flutter SDK (không cần cài riêng)

### 3. Git
- Tải từ: https://git-scm.com/downloads

### 4. IDE/Editor (chọn 1)
- **Android Studio** (khuyên dùng): https://developer.android.com/studio
- **Visual Studio Code**: https://code.visualstudio.com/
  - Cài extension: Flutter, Dart

## Cho Android Development

### 5. Android Studio + Android SDK
- Android SDK Command-line Tools
- Android SDK Build-Tools
- Android SDK Platform-Tools
- Android Emulator (tùy chọn)

### 6. Java Development Kit (JDK)
- JDK 17 hoặc mới hơn
- Tải từ: https://adoptium.net/

## Cho iOS Development (chỉ macOS)

### 7. Xcode
- Tải từ Mac App Store
- Chạy: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

### 8. CocoaPods
```bash
sudo gem install cocoapods
```

## Cho Web Development

### 9. Chrome Browser
- Tải từ: https://www.google.com/chrome/

## Cho Windows Desktop Development

### 10. Visual Studio 2022
- Workload: "Desktop development with C++"

---

## Kiểm tra cài đặt

Chạy lệnh sau để kiểm tra:
```bash
flutter doctor
```

## Lệnh cơ bản

```bash
# Tạo project mới
flutter create my_app

# Chạy ứng dụng
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Cài dependencies
flutter pub get
```
