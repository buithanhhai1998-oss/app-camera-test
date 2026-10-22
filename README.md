# CẨM NANG TOÀN BỘ VÒNG ĐỜI PHÁT TRIỂN FLUTTER iOS TRÊN WINDOWS
### Sideloading (SideStore / Sideloadly) · Free Apple ID · Độc lập 100% trong `D:\source\IOS`

---

## 1. TỔNG QUAN KIẾN TRÚC & CẤU TRÚC THƯ MỤC

Dự án này được thiết kế theo nguyên tắc **tự cô lập (self-contained)** tại `D:\source\IOS`. Không cài đặt hay chỉnh sửa bất kỳ biến môi trường nào vào hệ thống Windows (Global PATH).

```
D:\source\IOS\
├── .gitattributes             # Ép chuẩn Unix LF cho Podfile & shell scripts
├── .gitignore                # Bỏ qua local flutter, tools/bin, build cache
├── AGENTS.md                 # Bộ AI Rules bắt buộc cho Cursor/Copilot/Antigravity
├── env.bat                   # Kích hoạt session CMD với PATH cục bộ
├── env.ps1                   # Kích hoạt session PowerShell với PATH cục bộ
├── README.md                 # Cẩm nang vận hành A-Z
│
├── tools\                    # Bộ công cụ debug & quản trị cục bộ
│   ├── install_flutter.py    # Tự động tải Flutter SDK về D:\source\IOS\flutter
│   ├── install-local-flutter.ps1 # Bản PowerShell của bộ cài Flutter
│   ├── install-local-tools.ps1   # Tải iproxy, idevicecrashreport, jitterbugpair
│   ├── attach-wifi.ps1       # Flutter attach iPhone qua Wi-Fi (Hot Reload)
│   ├── attach-usb.ps1        # Flutter attach iPhone qua cáp USB bằng iproxy
│   ├── extract-crash-logs.ps1# Trích xuất crash logs (.ips) từ iPhone
│   └── update_altsource.py   # Script cập nhật apps.json cho SideStore
│
├── altsource\                # Hệ thống phân phối tự host trên GitHub Pages
│   └── apps.json             # File manifest định nghĩa app cho SideStore
│
├── .github\workflows\        # CI/CD tự động trên GitHub Actions
│   └── build-ios-sideload.yml# Workflow build IPA unsigned trên macOS-14 M1/M2
│
└── app\                      # Dự án Flutter production tối ưu cho iOS Sideload
    ├── pubspec.yaml          # Dependencies chuẩn (đã blacklist các package bị cấm)
    ├── lib\main.dart         # Error boundary + DevicePreview + Demo SQLite/Keychain
    └── ios\
        ├── Podfile           # Script vô hiệu hóa signing & fix kiến trúc M1/M2
        └── Runner\
            ├── Info.plist    # Đầy đủ mô tả quyền camera, location, Face ID
            └── Runner.entitlements # <dict></dict> rỗng an toàn cho Free Apple ID
```

---

## 2. BƯỚC 1: THIẾT LẬP MÔI TRƯỜNG CỤC BỘ TẠI `D:\source\IOS`

### 1. Cài đặt iTunes & iCloud bản Standalone của Apple (BẮT BUỘC)
> [!CAUTION]
> **TUYỆT ĐỐI KHÔNG** cài iTunes hay iCloud từ Microsoft Store. Bản Microsoft Store là container UWP ảo hóa, thiếu driver `Apple Mobile Device Service (AMDS)` khiến Sideloadly và `iproxy` không nhận diện được iPhone.
- Tải iTunes x64 chính thức: [https://www.apple.com/itunes/download/win64](https://www.apple.com/itunes/download/win64)
- Tải iCloud x64 chính thức từ trang hỗ trợ Apple.

### 2. Tải Flutter SDK Cục bộ vào `D:\source\IOS\flutter`
Chạy lệnh sau trong PowerShell hoặc CMD tại `D:\source\IOS`:
```cmd
python tools\install_flutter.py
```
*Script sẽ tự động tải bản Flutter Stable mới nhất và giải nén trực tiếp vào `D:\source\IOS\flutter` mà không sửa PATH hệ thống.*

### 3. Tải Bộ Công cụ Debug Cục bộ vào `D:\source\IOS\tools\bin`
```powershell
powershell -ExecutionPolicy Bypass -File tools\install-local-tools.ps1
```
*Script sẽ tải `iproxy.exe`, `idevicecrashreport.exe` và `jitterbugpair.exe` vào thư mục `tools\bin`.*

---

## 3. BƯỚC 2: KHỞI ĐỘNG PHIÊN LÀM VIỆC (LOCAL SESSION)

Mỗi khi muốn chạy lệnh Flutter trên máy tính Windows, mở terminal tại `D:\source\IOS` và chạy:
- **Nếu dùng CMD:** Chạy `env.bat`
- **Nếu dùng PowerShell:** Chạy `. .\env.ps1`

Session này sẽ tự động gắn `D:\source\IOS\flutter\bin` và `D:\source\IOS\tools\bin` vào biến môi trường PATH của **duy nhất cửa sổ terminal đó**. Khi đóng cửa sổ, hệ thống Windows hoàn toàn không bị ảnh hưởng.

Kiểm tra:
```cmd
flutter doctor
```

---

## 4. BƯỚC 3: PHÁT TRIỂN & DEBUG HÀNG NGÀY TRÊN WINDOWS

Do Apple không cung cấp iOS Simulator trên Windows, luồng phát triển chuẩn gồm 2 giai đoạn:

### Giai đoạn 1: 90% thời gian — Giả lập iOS bằng Android Emulator
1. Mở Android Emulator từ Android Studio.
2. Trong thư mục `app`, chạy:
   ```cmd
   cd app
   flutter run
   ```
3. App đã được tích hợp sẵn:
   - `DevicePreview`: Cho phép chọn khuôn viền iPhone (iPhone 15 Pro, iPhone 16), giả lập Dynamic Island, Safe Area, notch và Home Indicator.
   - `ThemeData(platform: TargetPlatform.iOS)`: Kích hoạt hiệu ứng vuốt chuyển trang Cupertino và hiệu ứng cuộn nảy (bouncing scroll physics) đặc trưng của iOS.
   - **Hot Reload** hoạt động tức thì (< 1 giây) khi bấm phím `r`.

### Giai đoạn 2: 10% thời gian — Kiểm tra Native trên iPhone thật
Khi cần kiểm tra Face ID, Camera, SQLite, hoặc Keychain thực tế trên phần cứng iOS:
- Đẩy code lên GitHub để CI build bản Debug hoặc Release IPA.

---

## 5. BƯỚC 4: CI/CD TỰ ĐỘNG BUILD IPA TRÊN GITHUB ACTIONS

### 1. Đẩy code lên GitHub Repository
```cmd
git add .
git commit -m "Init Flutter iOS Sideload workspace"
git remote add origin https://github.com/USERNAME/REPO_NAME.git
git branch -M main
git push -u origin main
```

### 2. Luồng hoạt động của Workflow `.github/workflows/build-ios-sideload.yml`:
- Chạy trên máy ảo `macos-14` (Apple Silicon M2).
- Tự động cache `pub-cache` và `Pods` giúp rút ngắn thời gian build từ 7 phút xuống còn **2 - 2.5 phút**.
- Chạy `flutter pub get` và `flutter build ios --config-only` trước khi cài CocoaPods.
- Tự động xóa sạch các entitlement bị cấm trong `Runner.entitlements` về `<dict></dict>` rỗng.
- Biên dịch bản Release không ký (`--no-codesign`).
- Đóng gói thư mục `Payload/Runner.app` thành file `Runner.ipa` chuẩn của Apple.
- Tạo checksum SHA256 và upload lên mục Artifacts của GitHub Actions (lưu trữ 7 ngày).

### 3. Tải IPA về máy:
Vào tab **Actions** trên GitHub → Bấm vào bản build mới nhất → Cuộn xuống mục **Artifacts** → Tải file `flutter-ios-release-ipa.zip` và giải nén lấy `Runner.ipa`.

---

## 6. BƯỚC 5: CÀI ĐẶT LẦN ĐẦU BẰNG SIDELOADLY & BOOTSTRAP SIDESTORE

### Cách A: Cài đặt nhanh qua Sideloadly (Khuyến nghị cho lần đầu)
1. Tải Sideloadly từ [https://sideloadly.io](https://sideloadly.io).
2. Cắm iPhone vào máy tính Windows bằng cáp USB, chọn **Trust This Computer** trên iPhone.
3. Kéo thả file `Runner.ipa` vào cửa sổ Sideloadly.
4. Nhập **Apple ID phụ** (Tài khoản Burner không gắn thẻ thanh toán).
5. Bấm **Start**, nhập mật khẩu và mã xác thực 2FA.
6. Sideloadly sẽ tự động liên hệ với máy chủ Apple, xin chứng chỉ Personal Team, ký file IPA và nạp vào iPhone.
7. **Trên iPhone:**
   - **iOS 16 trở lên:** Vào `Cài đặt > Quyền riêng tư & Bảo mật > Chế độ Nhà phát triển (Developer Mode) > Bật ON` (Máy sẽ khởi động lại).
   - Vào `Cài đặt > Cài đặt chung > Quản lý VPN & Thiết bị > [Apple ID của bạn] > Tin cậy (Trust)`.

### Cách B: Cài SideStore để tự động gia hạn không cần máy tính
1. Tải file `SideStore.ipa` từ [GitHub SideStore Releases](https://github.com/SideStore/SideStore/releases).
2. Dùng Sideloadly cài `SideStore.ipa` vào iPhone theo các bước trên.
3. **Tạo Pairing File:** Cắm iPhone qua USB, mở terminal chạy:
   ```cmd
   tools\bin\jitterbugpair.exe
   ```
   Lệnh sẽ xuất ra file `<UDID>.mobiledevicepairing`.
4. Gửi file pairing này sang iPhone (qua AirDrop/Zalo/iCloud Drive/cáp).
5. Mở SideStore trên iPhone:
   - Vào mục **Settings > Pairing File** → Chọn file pairing vừa chép vào.
   - Mục **Anisette Server**: Nhập `https://sidestore.io/anisette` (hoặc server tự host).
6. Kết nối vào cấu hình VPN WireGuard cục bộ mà SideStore tự tạo.
7. Bây giờ bạn có thể cài bất kỳ file `.ipa` nào trực tiếp ngay trên iPhone mà **không cần cắm vào máy tính nữa**!

---

## 7. BƯỚC 6: TỰ ĐỘNG CẬP NHẬT (ALTSOURCE) & GIA HẠN 7 NGÀY

### 1. Cơ chế AltSource qua GitHub Pages:
- Thư mục `altsource/apps.json` chứa thông tin phiên bản và đường link tải file `.ipa`.
- Khi bạn gắn Git Tag (ví dụ `git tag v1.0.1 && git push origin v1.0.1`), GitHub Actions sẽ:
  1. Build ra `Runner.ipa`.
  2. Tạo GitHub Release công khai chứa file IPA.
  3. Tự động chạy `tools/update_altsource.py` cập nhật version, file size và link tải vào `apps.json`.
  4. Đẩy `apps.json` lên nhánh `gh-pages`.
- Trong SideStore trên iPhone: Bấm dấu `+` ở tab **Sources**, dán link:
  `https://USERNAME.github.io/REPO_NAME/apps.json`
- Mỗi khi có bản build mới, mở SideStore sẽ thấy nút **UPDATE** màu xanh. Bấm update là app tự tải và cài đè không dây!

### 2. Tự động Gia hạn 7 Ngày (Auto-Renewal):
- Chứng chỉ Free Apple ID chỉ có hạn 7 ngày.
- **SideStore tự động gia hạn ngầm:** Khi iPhone kết nối Wi-Fi và bật VPN nội bộ của SideStore, nó sẽ gửi request lấy Anisette data và tự động re-sign app trước ngày thứ 7.
- **Nếu app hết hạn (quá 7 ngày chưa renew):**
  - App sẽ báo "App is no longer available" khi bấm vào.
  - **DỮ LIỆU HOÀN TOÀN KHÔNG BỊ MẤT!** Toàn bộ cơ sở dữ liệu SQLite và Keychain vẫn an toàn trong sandbox.
  - Chỉ cần mở SideStore bấm **Refresh** (hoặc cắm vào Sideloadly cài đè lại bản IPA cùng Bundle ID), app sẽ mở lại bình thường với dữ liệu nguyên vẹn.

---

## 8. BƯỚC 7: DEBUG TRỰC TIẾP IPHONE TỪ WINDOWS (`flutter attach`)

Bạn hoàn toàn có thể sử dụng **Hot Reload (`r`)**, **Hot Restart (`R`)** và **Dart DevTools** trực tiếp từ máy tính Windows sang iPhone thật mà không cần sở hữu máy Mac!

### Cách 1: Kết nối qua mạng Wi-Fi nội bộ
1. Đảm bảo iPhone và máy tính Windows đang kết nối **cùng một mạng Wi-Fi**.
2. Cài bản Debug IPA vào iPhone.
3. Mở app trên iPhone. Nhìn vào màn hình splash/log khởi động, bạn sẽ thấy dòng chữ:
   `The Dart VM Service is listening on http://192.168.1.XX:52134/AUTH_TOKEN=/`
4. Trên Windows, chạy:
   ```powershell
   powershell tools\attach-wifi.ps1
   ```
   Dán URL trên vào. Lập tức terminal sẽ attach vào iPhone!

### Cách 2: Kết nối qua cáp USB bằng `iproxy`
1. Cắm iPhone vào máy tính Windows qua cáp USB.
2. Chạy script:
   ```powershell
   powershell tools\attach-usb.ps1
   ```
   Script sẽ tự động khởi chạy `tools\bin\iproxy.exe` để forward port 8181 qua cáp USB sang iPhone.
3. Khi attach thành công:
   - Nhấn `r` để Hot Reload code Dart ngay lập tức lên màn hình iPhone.
   - Nhấn `R` để Restart lại toàn bộ app.
   - Mở đường link DevTools trong trình duyệt Chrome trên Windows để debug Layout Inspector, theo dõi RAM, CPU và Network.

---

## 9. BẢNG TRA CỨU NHANH LỖI THƯỜNG GẶP (TROUBLESHOOTING)

| Lỗi | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| `Building for iOS is only supported on macOS` | Chạy lệnh build trên Windows | Không chạy `flutter build ios` trên Windows. Đẩy code lên GitHub Actions. |
| `Generated.xcconfig: No such file or directory` | `pod install` chạy trước `flutter pub get` | Đảm bảo thứ tự trong CI: `flutter pub get` -> `flutter build ios --config-only` -> `pod install`. |
| `Signing for "Runner" requires a development team` | Xcode 14+ bắt buộc signing identity | Podfile đã có đoạn cấu hình `CODE_SIGNING_ALLOWED = 'NO'`. |
| `Sideloadly: Provisioning profile does not include expected entitlements` | File `Runner.entitlements` chứa quyền APNs hoặc Apple Sign In | Giữ file `Runner.entitlements` ở mức `<dict></dict>` rỗng. |
| `Device not found trong Sideloadly / iproxy` | Cài nhầm iTunes Microsoft Store hoặc chưa bấm Trust | Gỡ iTunes Store, cài iTunes Win64 standalone từ Apple, rút cáp cắm lại và bấm "Tin cậy máy tính". |
| `MAX_APP_ID_EXCEEDED` | Thay đổi Bundle ID quá 10 lần trong 7 ngày | Giữ cố định 1 Bundle ID (`com.yourname.appname`), không đổi tên theo phiên bản. |
| Crash silent ngay khi mở tính năng Camera/Location | Thiếu chuỗi mô tả trong `Info.plist` | Mở `ios/Runner/Info.plist`, bổ sung đầy đủ `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`. |
| `firebase_messaging` không nhận được token | Free Apple ID bị cấm dùng APNs | Chuyển sang dùng `web_socket_channel` / Supabase Realtime + `flutter_local_notifications`. |
