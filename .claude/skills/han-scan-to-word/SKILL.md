---
name: han-scan-to-word
description: Phân tích và chuyển file scan, PDF dạng ảnh hoặc ảnh chụp tài liệu (png, jpg, tif, bmp) thành file Word (.docx) chỉnh sửa được bằng OCR tiếng Việt (Tesseract). Dùng khi người dùng muốn chuyển PDF scan sang Word, "OCR" một tài liệu, lấy chữ ra khỏi bản scan hay ảnh chụp, hỏi vì sao không copy được chữ trong PDF, hoặc muốn sửa nội dung văn bản pháp luật vừa tải bằng han-download-law-doc - kể cả khi không nói chữ "OCR" hay "Word".
compatibility: Windows 10/11 (64-bit) với Windows PowerShell 5.1 (powershell.exe, không phải pwsh 7). Tesseract OCR 5 và dữ liệu tiếng Việt được skill tự cài vào thư mục người dùng ở lần đầu (cần internet tới github.com), hoặc dùng bản đã cài sẵn trên máy. Không cần quyền quản trị, Python hay Microsoft Word.
---

# Chuyển file scan / PDF ảnh sang Word

Skill này dựng từng trang PDF thành ảnh bằng bộ đọc PDF có sẵn của Windows, nhận
dạng chữ bằng Tesseract OCR (mô hình tiếng Việt), ghép các dòng lại thành đoạn văn,
rồi ghi ra file `.docx`. Không cần Python hay Microsoft Word.

Mọi thao tác đi qua `scripts/scan2word.ps1` (đường dẫn tính từ thư mục skill).
Luôn gọi bằng `powershell.exe` (bản 5.1), vì PowerShell 7 không nạp được bộ đọc PDF
của Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<thư mục skill>\scripts\scan2word.ps1" <action> ...
```

## Quy trình

### 0. Chưa biết file nào thì hỏi trước

Nếu người dùng gọi skill mà chưa chỉ ra file (ví dụ chỉ gõ tên skill `han-scan-to-word`,
hoặc "chuyển giúp tôi file scan sang word"), hãy hỏi một câu ngắn: họ muốn chuyển
file nào - đường dẫn tới file PDF hoặc ảnh. Đừng tự chọn một file trong thư mục
thay họ, kể cả khi chỉ thấy một file PDF: chuyển nhầm tài liệu tốn thời gian và có
thể tạo ra một bản Word mà họ tưởng là của tài liệu khác.

Ngoại lệ hợp lý: nếu ngay trong cuộc trò chuyện vừa tải hoặc vừa nhắc tới đúng một
file và người dùng nói "chuyển file đó sang Word", thì đó chính là file họ chỉ ra.
Nếu họ đưa một thư mục hoặc tên không đầy đủ và có nhiều file khớp, liệt kê các
file khớp để họ chọn.

### 1. Kiểm tra máy đã sẵn sàng (`check`)

```powershell
... scan2word.ps1 check
```

Lệnh này chỉ đọc, chạy chưa tới một giây, và là bước đầu tiên của mọi lần dùng
skill.

**Kết quả `READY` (mã thoát 0): đi thẳng sang bước 2.** Không nhắc gì tới cài đặt,
không chạy `setup`, không hỏi người dùng điều gì về Tesseract. Máy đã cài xong thì
người dùng không nên phải nghe lại chuyện cài đặt mỗi lần chuyển một file.

**Kết quả `NOT READY` (mã thoát 3):** dòng `missing:` cho biết còn thiếu gì
(`tesseract`, `language-data:vie`, hoặc cả hai). Lúc này hỏi người dùng **một lần**
xem họ chọn cách nào, kèm đủ thông tin để họ quyết định:

- **Cách 1 - skill tự cài (khuyên dùng).** Tải một bản Tesseract "mang theo" cùng
  dữ liệu tiếng Việt (file zip khoảng 47 MB từ mục Releases của kho
  `nguyenquanicd/VLSIT_Company_Manager_AI_Skills`), giải nén vào
  `%LOCALAPPDATA%\han-scan-to-word` (khoảng 130 MB). Không cần quyền quản trị,
  không đụng tới thiết lập hệ thống, gỡ bằng cách xóa thư mục đó. Chỉ chạy sau khi
  người dùng đồng ý:

  ```powershell
  ... scan2word.ps1 setup
  ```

- **Cách 2 - người dùng tự cài.** Họ chạy lệnh dưới đây (Windows sẽ hỏi quyền quản
  trị), báo lại khi xong, rồi bạn chạy `setup` để lấy phần dữ liệu tiếng Việt còn
  thiếu (12 MB từ `github.com/tesseract-ocr/tessdata_best`):

  ```powershell
  winget install --id UB-Mannheim.TesseractOCR -e
  ```

Sau cả hai cách, chạy lại `check` để xác nhận `READY` rồi mới làm tiếp. Đừng coi
việc người dùng nói "đã cài" là đủ - chính `check` mới là bằng chứng.

`setup` chỉ cài phần còn thiếu: chạy trên máy đã đủ thì nó in `Already set up -
nothing to do` và không tải gì. Vì vậy nếu lỡ chạy lại cũng không hại, nhưng không
có lý do để chạy khi `check` đã báo `READY`.

Nếu `setup` báo `Portable Tesseract NOT installed`:

- lỗi tải (404, không có mạng, bị tường lửa chặn GitHub): chuyển sang Cách 2, hoặc
  nếu người dùng có sẵn file zip (chép qua USB, ổ mạng) thì chạy
  `setup -BundlePath "<đường dẫn zip>"`;
- lỗi `does not match the expected SHA-256`: file tải về không đúng bản đã công bố.
  Đừng tìm cách bỏ qua bước kiểm tra này; báo cho người dùng và dùng Cách 2.

Đừng tìm cách dùng bộ nhận dạng chữ có sẵn của Windows (Windows.Media.Ocr, lệnh
`Add-WindowsCapability ... Language.OCR~~~vi-VN`): nó không có mô hình tiếng Việt,
lệnh cài sẽ không bao giờ thành công. Cũng đừng dùng `-Language eng` để "chạy tạm"
cho tài liệu tiếng Việt - chữ ra mất hết dấu ("lao động" thành "Iao döng"), không
dùng được. `-Language` nhận mã của Tesseract: `vie` (mặc định), `eng`, hoặc ghép
`vie+eng` cho tài liệu song ngữ; mỗi mã cần `setup -Language <mã>` một lần.

### 2. Phân tích file (`analyze`)

```powershell
... scan2word.ps1 analyze -Path "C:\...\45.signed.pdf"
```

Cho biết loại file, số trang, khổ giấy, và `Verdict`:

| Verdict | Ý nghĩa | Việc cần làm |
|---|---|---|
| `scan` | Trang chỉ là ảnh, không có lớp chữ | Chuyển bằng OCR (bước 3) |
| `mixed` | Chỉ có rất ít chữ thật (nhãn chữ ký số, số trang) trên nền ảnh | Vẫn chuyển bằng OCR |
| `text` | PDF đã có chữ thật, bôi đen và copy được | **Không OCR** - xem bên dưới |

Báo lại cho người dùng kết quả phân tích bằng một hai câu trước khi chuyển, nhất là
số trang: tài liệu vài trăm trang mất vài phút, họ nên biết trước.

**Khi verdict là `text`**: OCR lại một văn bản vốn đã có chữ chỉ làm sinh thêm lỗi.
Hãy nói với người dùng rằng file này không phải bản scan, và cách tốt nhất là mở
thẳng PDF bằng Microsoft Word (File > Open, chọn file PDF) rồi Save As `.docx` -
Word giữ nguyên chữ và phần lớn định dạng. Chỉ thêm `-OcrTextPdf` nếu họ vẫn muốn
OCR (ví dụ lớp chữ trong PDF bị lỗi font, copy ra toàn ký tự rác).

### 3. Chuyển đổi (`convert`)

```powershell
... scan2word.ps1 convert -Path "C:\...\45.signed.pdf" -SaveText
... scan2word.ps1 convert -Path "C:\...\scan.jpg" -OutFile "C:\...\ket-qua.docx"
... scan2word.ps1 convert -Path "C:\...\45.signed.pdf" -Pages "1-5,8"
```

| Tham số | Ý nghĩa |
|---|---|
| `-Path` | File PDF hoặc ảnh (`.png .jpg .jpeg .bmp .tif .tiff .gif`). TIFF nhiều trang được xử lý từng trang. |
| `-OutFile` | Nơi lưu file Word. Mặc định: cùng thư mục, cùng tên với file gốc, đuôi `.docx`. |
| `-Pages` | Chỉ chuyển một số trang, ví dụ `1-5,8`. Hữu ích để thử nhanh vài trang đầu của tài liệu dài trước khi chạy toàn bộ. |
| `-SaveText` | Ghi thêm bản chữ thuần `.txt` (UTF-8) cạnh file Word. Nên bật: đọc file này là cách nhanh nhất để bạn tự kiểm tra chất lượng. |
| `-Dpi` | Độ phân giải dựng trang, mặc định 300. Tăng lên 400 nếu chữ gốc rất nhỏ. |
| `-Force` | Ghi đè file kết quả đã tồn tại. Mặc định script dừng lại để không xóa nhầm bản Word người dùng đã sửa tay. |
| `-Json` | Xuất kết quả dạng JSON. |

Tesseract xử lý từng trang một và mất vài giây mỗi trang A4, nên tài liệu vài chục
trang trở lên hãy chạy lệnh ở chế độ nền, và thử `-Pages 1-3` trước để xem chất
lượng.

Mã thoát: `0` thành công, `3` thiếu Tesseract hoặc dữ liệu ngôn ngữ (ở `check`), `4` PDF đã có chữ thật nên
không chuyển, `1` lỗi khác (kèm thông báo).

### 4. Kiểm tra rồi mới báo xong

OCR không bao giờ đúng hoàn toàn, nên trước khi trả lời:

- Đọc lướt file `.txt` (vài trang đầu và một trang giữa) để chắc chắn chữ ra là
  tiếng Việt có dấu, đọc được, không phải ký tự rác.
- Xem `Mean confidence` (độ tin cậy trung bình do Tesseract tự chấm, thang 100) và
  dòng `Low-confidence pages`: các trang dưới 75 điểm thường có nhiều lỗi và cần
  người dùng dò lại với bản gốc. Nêu rõ các số trang đó.
- Xem dòng `Nearly empty pages`: đó là các trang gần như không nhận ra chữ - thường
  là trang trắng, trang chỉ có con dấu/chữ ký, hoặc trang scan quá mờ. Nêu số
  trang đó cho người dùng.

## Kết quả trông như thế nào

File Word dùng khổ A4, font Times New Roman cỡ 14, lề kiểu văn bản hành chính. Các
dòng được ghép lại thành đoạn; dòng căn giữa (quốc hiệu, tên văn bản, tên chương)
được giữ căn giữa; tiêu đề viết hoa và các dòng "Điều ...", "Chương ...", "Mục ..."
được in đậm. Mỗi trang của bản gốc bắt đầu trên một trang mới của file Word, để
người dùng dễ đối chiếu trang với trang.

## Những điều cần nói thật với người dùng

- **Đây là bản để làm việc, không phải bản chính.** OCR hay nhầm dấu thanh, nhầm
  các ký tự giống nhau (`l`/`1`/`I`, `0`/`O`), và nhầm số - điều nguy hiểm nhất với
  văn bản pháp luật vì số điều, khoản, mức tiền, ngày tháng đều là số. Luôn nhắc
  người dùng đối chiếu các con số và trích dẫn quan trọng với bản PDF gốc, và dùng
  bản gốc khi cần trích dẫn chính thức.
- **Bảng biểu không được dựng lại.** Nội dung trong bảng ra thành các dòng chữ,
  các cột cách nhau bằng dấu tab; người dùng phải tự kẻ lại bảng nếu cần.
- **Không giữ hình ảnh, con dấu, chữ ký, chữ in nghiêng, cỡ chữ gốc.** Chỉ có chữ
  và bố cục đoạn văn cơ bản.
- **Bản scan xấu cho kết quả xấu.** Trang nghiêng, mờ, chữ viết tay, hoặc bị con
  dấu đỏ đè lên chữ sẽ sai nhiều. Nếu thấy chất lượng kém, nói thẳng và gợi ý tìm
  bản scan rõ hơn thay vì giao một file Word đầy lỗi mà không cảnh báo.
- **Nhãn chữ ký số** ở đầu trang 1 của các file `.signed.pdf` (dòng "Ký bởi: Cổng
  Thông tin điện tử Chính phủ ...") cũng bị nhận dạng thành chữ. Đó không phải nội
  dung văn bản; nhắc người dùng xóa đi nếu họ không cần.

## Khi script báo lỗi

- `Tesseract OCR is not installed ...` hoặc `Tesseract language data ... is missing`:
  quay lại bước 1.
- `Tesseract failed ...`: đọc thông báo đi kèm; thường do file ảnh hỏng hoặc định
  dạng ảnh lạ. Thử lưu lại ảnh dưới dạng PNG rồi chạy lại.
- `Run this script with Windows PowerShell 5.1 ...`: đang gọi bằng `pwsh`; đổi sang
  `powershell.exe`.
- `Windows could not open this PDF ...`: file hỏng hoặc có mật khẩu. Hỏi người dùng
  mật khẩu/bản khác; đừng tìm cách phá khóa.
- `Output already exists ...`: hỏi người dùng muốn ghi đè (`-Force`) hay lưu tên
  khác (`-OutFile`).
- `Unsupported file type ...`: chỉ nhận PDF và ảnh. File Word/Excel thì không cần
  skill này.
