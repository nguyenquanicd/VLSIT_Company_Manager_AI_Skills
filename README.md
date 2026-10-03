# VLSIT Company Manager AI Skills

Bộ skill cho Claude Code và OpenAI Codex phục vụ công việc quản lý, hành chính của
công ty, kèm hướng dẫn để hiểu skill là gì, cách dùng và cách tự xây dựng skill mới
trên Windows.

## Skill là gì?

Skill là một thư mục chứa hướng dẫn để trợ lý AI (Claude Code, Codex) thực hiện một
quy trình lặp lại theo đúng cách bạn muốn. Tối thiểu, skill chỉ cần một file
`SKILL.md`; skill phức tạp hơn có thêm script để làm các bước cần chính xác.

```
ten-skill/
├── SKILL.md      # bắt buộc: tên, mô tả khi nào dùng, và các bước thực hiện
└── scripts/      # tùy chọn: script mà hướng dẫn trong SKILL.md gọi tới
```

`SKILL.md` mở đầu bằng hai trường `name` và `description`. Trợ lý luôn đọc hai
trường này; phần hướng dẫn bên dưới chỉ được nạp khi skill được chọn. Vì vậy
`description` quyết định skill có được dùng đúng lúc hay không.

Claude Code và Codex dùng chung định dạng skill nhưng tìm ở hai thư mục khác nhau,
nên kho này đặt cùng một bộ skill ở cả hai nơi:

| Công cụ | Skill trong kho | Skill cá nhân (dùng ở mọi kho) | Cách gọi |
|---|---|---|---|
| Claude Code | `.claude\skills\` (bản gốc) | `C:\Users\<tên>\.claude\skills\` | `/tên-skill` |
| OpenAI Codex | `.agents\skills\` (bản sao y hệt) | `C:\Users\<tên>\.agents\skills\` | `$tên-skill`, hoặc chọn trong `/skills` |

Cả hai công cụ cũng tự chọn skill khi yêu cầu của bạn khớp với `description`, không
cần gõ tên skill.

## Các skill hiện có

| Skill | Công dụng |
|---|---|
| [`han-download-law-doc`](.claude/skills/han-download-law-doc/SKILL.md) | Tìm và tải file gốc (PDF ký số) của văn bản pháp luật Việt Nam từ Cổng Thông tin điện tử Chính phủ `vanban.chinhphu.vn`, kèm `metadata.json` ghi số hiệu, ngày ban hành, ngày hiệu lực, link nguồn. |
| [`han-scan-to-word`](.claude/skills/han-scan-to-word/SKILL.md) | Phân tích và chuyển PDF scan hoặc ảnh chụp tài liệu thành file Word (`.docx`) bằng OCR tiếng Việt (Tesseract). |

Hai skill dùng nối tiếp được: tải văn bản về, rồi chuyển bản scan sang Word để tra
cứu và soạn thảo.

## Yêu cầu

- Windows 10/11 với Windows PowerShell 5.1 (có sẵn).
- [Claude Code](https://claude.com/claude-code) (bản terminal hoặc ứng dụng desktop)
  hoặc OpenAI Codex (CLI hoặc tiện ích IDE).
- Kết nối internet tới `chinhphu.vn` (cho `han-download-law-doc`).
- Riêng `han-scan-to-word` cần Tesseract OCR và dữ liệu tiếng Việt; skill tự cài
  ở lần dùng đầu, xem mục cài đặt bên dưới.

Không cần Python, Node.js, Microsoft Word hay quyền quản trị.

## Cài đặt

Lấy kho về máy:

```bash
git clone https://github.com/nguyenquanicd/VLSIT_Company_Manager_AI_Skills.git
```

`han-download-law-doc` dùng được ngay. `han-scan-to-word` cần Tesseract: lần đầu
gọi skill, trợ lý kiểm tra máy, và nếu còn thiếu thì hỏi bạn chọn một trong hai
cách dưới đây. Máy đã cài đủ thì các lần sau skill chạy thẳng, không hỏi lại.

**Cách 1 - skill tự cài (không cần quyền quản trị).** Tải bản Tesseract "mang theo"
kèm dữ liệu tiếng Việt (zip khoảng 47 MB từ mục Releases của kho này) và giải nén
vào `%LOCALAPPDATA%\han-scan-to-word` (khoảng 130 MB). Gỡ bằng cách xóa thư mục đó.
Cũng có thể tự chạy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 setup
```

Máy không có internet: chép file zip sang rồi thêm `-BundlePath "<đường dẫn zip>"`.

**Cách 2 - tự cài Tesseract bằng winget** (Windows sẽ hỏi quyền quản trị), rồi chạy
lệnh `setup` ở trên để lấy dữ liệu tiếng Việt:

```powershell
winget install --id UB-Mannheim.TesseractOCR -e
```

Kiểm tra bất cứ lúc nào, kết quả mong đợi là `READY`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 check
```

## Cách dùng

Mở trợ lý tại thư mục gốc của kho này; nó tự nhận các skill trong kho.

**Claude Code** (gõ `claude` trong terminal, hoặc mở thư mục bằng ứng dụng desktop):

```text
/han-download-law-doc 59/2020/QH14
/han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
/han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

**Codex** (gõ `codex` trong terminal):

```text
$han-download-law-doc 59/2020/QH14
$han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
$han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

Hoặc nói yêu cầu bằng lời thường ở cả hai công cụ, ví dụ "tải nghị định
13/2023/NĐ-CP" hay "chuyển file scan này sang Word".

- Gọi skill mà không nêu tên văn bản hoặc file, trợ lý sẽ hỏi lại.
- Tên văn bản gần đúng vẫn được: trợ lý thử các tên tương tự và nói rõ đã tải văn
  bản nào.
- Văn bản tải về mặc định nằm trong `van-ban/<số hiệu>/` ở thư mục đang làm việc;
  file Word nằm cạnh file PDF gốc. Một bộ kết quả mẫu có sẵn trong `example/van-ban/`.
- Skill mới thêm mà chưa thấy xuất hiện: khởi động lại trợ lý. Trong Codex, lệnh
  `/skills` liệt kê các skill đã được nhận.
- Hai skill này cần truy cập mạng (`chinhphu.vn`, `github.com`). Nếu Codex đang
  chạy ở chế độ hạn chế mạng, nó sẽ hỏi bạn cho phép trước khi chạy lệnh.

Để dùng skill ở mọi thư mục trên máy, chép thư mục skill vào thư mục skill cá nhân
ghi trong bảng ở mục "Skill là gì?".

### Chạy script trực tiếp (không qua trợ lý)

```powershell
# Tìm và tải văn bản
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 search -Keyword "dữ liệu cá nhân"
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 download -SoHieu "59/2020/QH14" -OutDir .\van-ban

# Phân tích và chuyển PDF scan sang Word
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 analyze -Path .\example\van-ban\45_2019_QH14\45.signed.pdf
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 convert -Path .\example\van-ban\45_2019_QH14\45.signed.pdf -OutFile .\thu.docx -SaveText
```

Danh sách tham số đầy đủ nằm trong `SKILL.md` của từng skill.

## Tự xây dựng skill mới

Có hai cách tạo skill.

**Cách 1 - nhờ trợ lý tạo.** Mở trợ lý tại thư mục gốc của kho, gọi skill
`skill-creator` (`/skill-creator` trong Claude Code nếu đã cài, `$skill-creator`
trong Codex), rồi mô tả: mục tiêu của skill, khi nào nên dùng, đầu vào, và kết quả
mong muốn. Trợ lý sẽ viết `SKILL.md` và script, bạn chạy thử rồi yêu cầu sửa.

**Cách 2 - tạo thủ công.** Chạy PowerShell từ thư mục gốc của kho:

```powershell
New-Item -ItemType Directory -Force ".claude\skills\ten-skill"
notepad ".claude\skills\ten-skill\SKILL.md"
```

Rồi viết `SKILL.md` theo mẫu:

```markdown
---
name: ten-skill
description: Skill làm việc gì, và dùng khi nào - nêu rõ các tình huống, từ khóa mà người dùng hay nói.
---

# Tên skill

Mô tả ngắn skill làm gì và không làm gì.

## Quy trình

1. Bước đầu tiên. Nếu thiếu thông tin đầu vào thì hỏi người dùng.
2. Bước tiếp theo, kèm lệnh cần chạy nếu có.
3. Kiểm tra kết quả trước khi báo xong.

## Kết quả

- Lưu ở đâu, tên file thế nào.
- Báo lại cho người dùng những gì, kể cả phần chưa kiểm tra được.
```

Hai skill trong kho là ví dụ đầy đủ để tham khảo cách viết.

Một số điểm nên giữ khi viết skill:

- **Tên** viết thường, nối bằng dấu gạch ngang, trùng với tên thư mục. Kho này dùng
  tiền tố `han-` cho skill hành chính.
- **`description`** nêu cả việc skill làm lẫn tình huống nên dùng, viết trên một
  dòng, nên dưới 500 ký tự, và không chứa cụm dấu hai chấm kèm dấu cách (sẽ làm hỏng
  phần đầu file).
- **Giải thích lý do** của từng yêu cầu thay vì chỉ ra lệnh; trợ lý xử lý tình huống
  lạ tốt hơn khi hiểu vì sao.
- **Không viết riêng cho một công cụ:** tránh nhắc tên Claude hay Codex, tránh ghi
  cú pháp gọi `/` hay `$` trong `SKILL.md`, để một bản dùng được cho cả hai.
- **Skill phải nói thật về giới hạn:** không bịa nội dung thiếu, không báo "đã kiểm
  tra" khi chưa kiểm tra được.
- **Script PowerShell** chỉ dùng ký tự ASCII để Windows PowerShell 5.1 đọc đúng trên
  mọi máy.

**Đồng bộ sang Codex.** Chỉ sửa skill trong `.claude\skills\`, rồi chạy lệnh sau để
chép sang `.agents\skills\`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\sync-codex-skills.ps1
```

Thêm `-Check` để chỉ kiểm tra hai nơi có khớp nhau không mà không chép gì.

Tài liệu chính thức: [Codex skills](https://learn.chatgpt.com/docs/build-skills),
[Claude Code](https://claude.com/claude-code).

## Cấu trúc thư mục

```
.
├── .claude/skills/              # bản gốc, Claude Code đọc ở đây
│   ├── han-download-law-doc/
│   │   ├── SKILL.md
│   │   └── scripts/vanban.ps1
│   └── han-scan-to-word/
│       ├── SKILL.md
│       └── scripts/scan2word.ps1
├── .agents/skills/              # bản sao cho Codex, tạo bằng tools/sync-codex-skills.ps1
├── tools/
│   └── sync-codex-skills.ps1
├── example/
│   ├── van-ban/                 # ví dụ mẫu: Bộ luật Lao động đã tải và file Word đã chuyển
│   └── TOM-TAT-VAN-DE.md        # các vấn đề đã gặp khi xây dựng skill và cách xử lý
├── dist/                        # gói Tesseract để đăng lên Releases (không đưa vào git)
└── README.md
```

## Giới hạn cần biết

- **Nguồn văn bản:** chỉ lấy từ `vanban.chinhphu.vn`. Không lấy từ thuvienphapluat.vn
  (trang này chặn truy cập tự động) hay vbpl.vn (cấm script ở phần dữ liệu). Văn bản
  địa phương hoặc rất cũ có thể không có.
- **Tình trạng hiệu lực:** cổng Chính phủ không ghi văn bản đã hết hiệu lực hay bị
  sửa đổi, thay thế. Cần đối chiếu tại vbpl.vn trước khi trích dẫn.
- **Bản Word là bản làm việc:** OCR có thể sai dấu, sai số, sai tiêu đề điều; bảng
  biểu không được kẻ lại; không giữ hình, con dấu, chữ ký. Luôn dò các con số quan
  trọng với PDF gốc và dùng PDF gốc khi trích dẫn chính thức.
- **PDF đã có chữ thật** (bôi đen và copy được) không cần OCR: mở thẳng bằng Word
  rồi lưu thành `.docx`.
- **Chỉ chạy trên Windows:** script dùng Windows PowerShell 5.1 và bộ đọc PDF của
  Windows.

Chi tiết các vấn đề đã gặp và cách xử lý: [example/TOM-TAT-VAN-DE.md](example/TOM-TAT-VAN-DE.md).

## Dành cho người quản lý kho: đăng gói Tesseract

Cách cài tự động tải file `tesseract-portable-5.4.0-win64.zip` từ release có tag
`tesseract-portable-5.4.0` của kho này. File được tạo sẵn trong `dist/` và phải được
đăng lên Releases một lần. Script kiểm tra mã SHA-256 của file trước khi giải nén,
nên nếu thay file zip khác thì phải cập nhật `$script:BundleSha256` trong
`scan2word.ps1` rồi chạy lại lệnh đồng bộ sang Codex. Gói chứa Tesseract 5.4.0
(giấy phép Apache 2.0, kèm file `LICENSE`).
