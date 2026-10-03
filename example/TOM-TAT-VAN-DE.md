# Tóm tắt vấn đề và cách giải quyết

Phiên làm việc ngày 03–04/10/2026: xây dựng hai skill `han-download-law-doc` và
`han-scan-to-word` trong `.claude/skills/`.

## Skill `han-download-law-doc` (tải văn bản pháp luật)

| # | Vấn đề | Cách giải quyết |
|---|---|---|
| 1 | thuvienphapluat.vn chặn truy cập tự động bằng Cloudflare (script nhận HTTP 403, trình duyệt bị hỏi xác minh). | Không vượt lớp chống bot. Chuyển sang nguồn nhà nước `vanban.chinhphu.vn` (cho phép script, có file PDF ký số). |
| 2 | vbpl.vn cấm script ở phần dữ liệu (`robots.txt` chặn `/api/`). | Không dùng vbpl.vn; chỉ gợi ý người dùng tự đối chiếu ở đó. |
| 3 | Máy không có Python và Node.js. | Viết script bằng PowerShell 5.1, không cần cài thêm gì. |
| 4 | Ô tìm kiếm của cổng Chính phủ là form ASP.NET, không có URL tìm kiếm trực tiếp; `__VIEWSTATE` quá dài làm hàm mã hóa URL báo lỗi. | Script đọc trang, gửi lại form kèm các trường ẩn, và mã hóa URL theo từng đoạn nhỏ. |
| 5 | Gõ số hiệu không dấu (`13/2023/ND-CP`) tìm không ra; cổng đôi khi nhập chữ Kirin trông giống chữ Latin. | Chuẩn hóa số hiệu khi so khớp (Đ/D, chữ Kirin, khoảng trắng) và tìm lại theo phần "số/năm". |
| 6 | Người dùng gọi skill mà không nêu tên văn bản, hoặc nêu tên gần đúng. | SKILL.md yêu cầu hỏi lại khi thiếu tên; khi tên không khớp thì thử tên tương tự và nói rõ đã tải văn bản nào. |
| 7 | Skill đặt ở thư mục gốc nên Claude không tự nhận. | Chuyển vào `.claude/skills/<tên skill>/` để gọi được bằng `/tên-skill` ở cả TUI và GUI. |

## Skill `han-scan-to-word` (PDF scan sang Word)

| # | Vấn đề | Cách giải quyết |
|---|---|---|
| 8 | Công cụ Write tự đổi chuỗi `\uXXXX` thành chữ tiếng Việt thật, làm PowerShell 5.1 báo lỗi cú pháp (file không có BOM). | Giữ script thuần ASCII; ghép chữ tiếng Việt bằng mã ký tự `[char]0x....`. |
| 9 | Dùng Word (COM) để chuyển PDF đã có chữ thì bị treo ở hộp thoại xác nhận của Word. | Bỏ nhánh này. PDF đã có chữ thật thì script dừng (mã thoát 4) và hướng dẫn mở thẳng bằng Word. |
| 10 | Lệnh `Add-WindowsCapability` báo "requires elevation". | Do cửa sổ PowerShell không có quyền quản trị; cần mở bằng "Run as administrator". |
| 11 | Cài xong vẫn không có OCR tiếng Việt: Windows OCR **không hỗ trợ tiếng Việt** (hướng dẫn ban đầu của Claude sai). | Viết lại phần nhận dạng chữ để dùng Tesseract OCR (`winget install --id UB-Mannheim.TesseractOCR -e`) với dữ liệu `vie.traineddata`. |
| 12 | Dữ liệu ngôn ngữ đặt trong `Program Files` cần quyền quản trị. | Lệnh `setup` tải dữ liệu vào `%LOCALAPPDATA%\han-scan-to-word\tessdata`, không cần quyền quản trị. |
| 13 | Tesseract báo `Can't open tsv` khi dùng thư mục dữ liệu riêng. | Bật xuất TSV bằng tham số `-c tessedit_create_tsv=1` thay cho file cấu hình `tsv`. |

## Kết quả và giới hạn còn lại

- Đã tải Bộ luật Lao động 45/2019/QH14 và chuyển cả 83 trang sang Word
  (`van-ban/45_2019_QH14/`), độ tin cậy trung bình 95/100, khoảng 5 phút.
- OCR vẫn có lỗi: 6 trên 220 tiêu đề "Điều" nhận sai, thỉnh thoảng mất dấu, sai số,
  phần con dấu/chữ ký ra chữ rác. Cần dò lại các con số với PDF gốc.
- Bảng biểu không được kẻ lại; không giữ hình ảnh, con dấu, chữ ký.
- Cổng Chính phủ không ghi tình trạng hiệu lực của văn bản; cần đối chiếu ở vbpl.vn.
- Tìm kiếm trả về tối đa 500 kết quả mỗi lần.
- Chưa chạy bộ đánh giá tự động của skill-creator (cần Python).
