# VLSIT Company Manager AI Skills

**[Tiếng Việt](#vi)** | **[English](#en)**

<a id="vi"></a>

## Tiếng Việt

Bộ skill cho Claude Code và OpenAI Codex phục vụ công việc quản lý, hành chính của
công ty, kèm hướng dẫn để hiểu skill là gì, các cách kích hoạt và dùng, và cách tự
xây dựng skill mới trên Windows.

### Skill là gì?

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

### Các skill hiện có

| Skill | Công dụng |
|---|---|
| [`han-download-law-doc`](.claude/skills/han-download-law-doc/SKILL.md) | Tìm và tải file gốc (PDF ký số) của văn bản pháp luật Việt Nam từ Cổng Thông tin điện tử Chính phủ `vanban.chinhphu.vn`, kèm `metadata.json` ghi số hiệu, ngày ban hành, ngày hiệu lực, link nguồn. Mặc định tải trọn bộ: bản mới nhất của văn bản cần tìm, các nghị định, thông tư hướng dẫn và sửa đổi đang áp dụng, và file `QUAN-HE-VAN-BAN.md` mô tả quan hệ giữa chúng cùng các lưu ý đặc biệt. Ví dụ: [bộ Bộ luật Lao động](example/van-ban/Bo-luat-Lao-dong-45_2019_QH14/QUAN-HE-VAN-BAN.md) (9 văn bản), [bộ Luật Thương mại](example/van-ban/Luat-Thuong-mai-36_2005_QH11/QUAN-HE-VAN-BAN.md) (67 văn bản). |
| [`han-scan-to-word`](.claude/skills/han-scan-to-word/SKILL.md) | Phân tích và chuyển PDF scan hoặc ảnh chụp tài liệu thành file Word (`.docx`) bằng OCR tiếng Việt (Tesseract). |

Hai skill dùng nối tiếp được: tải văn bản về, rồi chuyển bản scan sang Word để tra
cứu và soạn thảo.

Quy ước ngôn ngữ của kho: `SKILL.md` và script chỉ viết bằng tiếng Anh chuyên ngành;
README và các tài liệu hướng dẫn viết song ngữ Anh - Việt. Trợ lý vẫn trả lời bạn
bằng ngôn ngữ bạn dùng, và file quan hệ `QUAN-HE-VAN-BAN.md` vẫn viết bằng tiếng
Việt vì nó mô tả văn bản pháp luật Việt Nam.

### Yêu cầu

- Windows 10/11 với Windows PowerShell 5.1 (có sẵn).
- [Claude Code](https://claude.com/claude-code) (bản terminal hoặc ứng dụng desktop)
  hoặc OpenAI Codex (CLI hoặc tiện ích IDE).
- Kết nối internet tới `chinhphu.vn` (cho `han-download-law-doc`).
- Riêng `han-scan-to-word` cần Tesseract OCR và dữ liệu tiếng Việt; skill tự cài
  ở lần dùng đầu, xem mục cài đặt bên dưới.

Không cần Python, Node.js, Microsoft Word hay quyền quản trị.

### Cài đặt

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

### Các cách kích hoạt và dùng skill

Có năm cách, xếp từ thủ công nhất đến cài đặt đầy đủ. Chọn theo mức bạn muốn trợ lý
tự nhận skill:

| # | Cách | Cần cài gì | Dùng được ở đâu | Phù hợp khi |
|---|---|---|---|---|
| 1 | Chạy script trực tiếp | Không | Mọi thư mục | Không dùng trợ lý AI, hoặc muốn tự động hóa bằng script |
| 2 | Bảo trợ lý đọc `SKILL.md` | Không | Mọi thư mục | Dùng thử một lần, hoặc trợ lý chưa nhận skill |
| 3 | Mở trợ lý tại kho này | Chỉ cần clone kho | Trong kho này | Cách đơn giản nhất để dùng thường xuyên |
| 4 | Cài skill cá nhân | Chép thư mục skill | Mọi thư mục trên máy | Muốn dùng skill khi làm việc ở kho khác |
| 5 | Cài vào một dự án khác | Chép thư mục skill vào dự án | Trong dự án đó | Muốn cả nhóm của dự án đó cùng dùng |

Ở cách 3, 4 và 5, trợ lý tự nhận skill; xem "Gọi skill" bên dưới.

#### Cách 1 - chạy script trực tiếp (không qua trợ lý)

Thủ công hoàn toàn: bạn tự gõ lệnh và tự đọc kết quả. Không có phần suy luận của
trợ lý (chọn bản mới nhất, phân loại quan hệ, viết file quan hệ).

```powershell
# Tìm, xem văn bản liên quan, và tải
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 search -Keyword "dữ liệu cá nhân"
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 related -SoHieu "45/2019/QH14"
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 download -SoHieu "59/2020/QH14" -OutDir .\van-ban

# Phân tích và chuyển PDF scan sang Word
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 analyze -Path .\example\van-ban\45_2019_QH14\45.signed.pdf
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 convert -Path .\example\van-ban\45_2019_QH14\45.signed.pdf -OutFile .\thu.docx -SaveText
```

Danh sách tham số đầy đủ nằm trong `SKILL.md` của từng skill.

#### Cách 2 - bảo trợ lý đọc `SKILL.md`

Không cần cài gì và dùng được ở bất kỳ thư mục nào: chỉ đường dẫn tới file hướng
dẫn, rồi nêu yêu cầu. Trợ lý đọc file và làm theo, kể cả khi nó chưa nhận skill.

```text
Đọc file C:\duong-dan\VLSIT_Company_Manager_AI_Skills\.claude\skills\han-download-law-doc\SKILL.md
rồi làm theo để tải Luật Doanh nghiệp.
```

Trong Claude Code có thể gõ `@` rồi chọn file hoặc thư mục skill thay cho việc gõ
đường dẫn.

#### Cách 3 - mở trợ lý tại kho này

Skill nằm sẵn trong kho, nên chỉ cần mở trợ lý ở thư mục gốc của kho:

```powershell
cd C:\duong-dan\VLSIT_Company_Manager_AI_Skills
claude      # hoặc: codex
```

Với ứng dụng Claude desktop, chọn thư mục kho làm thư mục làm việc.

#### Cách 4 - cài skill cá nhân (dùng ở mọi thư mục)

Chép các thư mục skill vào thư mục skill cá nhân. Chạy từ thư mục gốc của kho:

```powershell
# Claude Code
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item ".claude\skills\han-*" "$env:USERPROFILE\.claude\skills\" -Recurse -Force

# Codex
New-Item -ItemType Directory -Force "$env:USERPROFILE\.agents\skills" | Out-Null
Copy-Item ".agents\skills\han-*" "$env:USERPROFILE\.agents\skills\" -Recurse -Force
```

Bản chép không tự cập nhật: sau khi `git pull`, chạy lại lệnh chép. Nếu muốn bản cá
nhân luôn theo kho, thay lệnh chép bằng liên kết thư mục (junction), không cần
quyền quản trị:

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skills\han-download-law-doc" -Target "$PWD\.claude\skills\han-download-law-doc"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skills\han-scan-to-word" -Target "$PWD\.claude\skills\han-scan-to-word"
```

Gỡ cài đặt: xóa các thư mục `han-*` trong thư mục skill cá nhân.

#### Cách 5 - cài vào một dự án khác

Chép thư mục skill vào `.claude\skills\` (Claude Code) hoặc `.agents\skills\`
(Codex) của dự án đó (tạo thư mục này trước nếu chưa có), rồi commit để cả nhóm
cùng có:

```powershell
Copy-Item ".claude\skills\han-*" "C:\duong-dan\du-an-khac\.claude\skills\" -Recurse -Force
Copy-Item ".agents\skills\han-*" "C:\duong-dan\du-an-khac\.agents\skills\" -Recurse -Force
```

#### Gọi skill

Sau khi skill được nhận (cách 3, 4, 5), có hai cách gọi.

**Gọi đích danh.** Trong Claude Code:

```text
/han-download-law-doc 59/2020/QH14
/han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
/han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

Trong Codex:

```text
$han-download-law-doc 59/2020/QH14
$han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
$han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

**Nói bằng lời thường.** Trợ lý tự chọn skill khi yêu cầu khớp với `description`,
ví dụ "tải nghị định 13/2023/NĐ-CP và các văn bản hướng dẫn" hay "chuyển file scan
này sang Word".

Kiểm tra skill đã được nhận chưa: trong Claude Code gõ `/` và tìm tên skill trong
danh sách; trong Codex gõ `/skills`. Skill mới thêm mà chưa thấy thì khởi động lại
trợ lý.

Khi dùng:

- Gọi skill mà không nêu tên văn bản hoặc file, trợ lý sẽ hỏi lại.
- Tên văn bản gần đúng vẫn được: trợ lý thử các tên tương tự và nói rõ đã tải văn
  bản nào.
- Văn bản tải về mặc định nằm trong `van-ban/` ở thư mục đang làm việc; file Word
  nằm cạnh file PDF gốc. Kết quả mẫu có sẵn trong `example/van-ban/`.
- Hai skill cần truy cập mạng (`chinhphu.vn`, `github.com`). Nếu Codex đang chạy ở
  chế độ hạn chế mạng, nó sẽ hỏi bạn cho phép trước khi chạy lệnh.
- Skill chỉ chạy trên máy Windows của bạn. Không dùng được trong Claude trên web hay
  ứng dụng điện thoại, vì script cần Windows PowerShell.

### Tự xây dựng skill mới

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
description: What the skill does and when to use it - name the situations and keywords users typically mention.
---

# Skill title

A short statement of what the skill does and does not do.

## Workflow

1. First step. If required input is missing, ask the user.
2. Next step, with the command to run if there is one.
3. Check the result before reporting completion.

## Output

- Where the result is saved and how files are named.
- What to report back to the user, including anything that could not be verified.
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
- **Viết `SKILL.md` bằng tiếng Anh chuyên ngành**, kể cả `description`. Thuật ngữ
  tiếng Việt chỉ giữ khi nó là dữ liệu thật (từ khóa tìm kiếm, tên văn bản, nội dung
  file kết quả), và nên chú nghĩa tiếng Anh lần đầu xuất hiện.
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

### Cấu trúc thư mục

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
│   ├── van-ban/
│   │   ├── Bo-luat-Lao-dong-45_2019_QH14/   # ví dụ mẫu 1: 9 văn bản + file quan hệ
│   │   ├── Luat-Thuong-mai-36_2005_QH11/    # ví dụ mẫu 2: 67 văn bản + file quan hệ
│   │   └── 45_2019_QH14/                    # một văn bản tải riêng + bản Word chuyển từ bản scan
│   └── TOM-TAT-VAN-DE.md        # các vấn đề đã gặp khi xây dựng skill và cách xử lý
├── dist/                        # gói Tesseract để đăng lên Releases (không đưa vào git)
└── README.md
```

### Giới hạn cần biết

- **Nguồn văn bản:** chỉ lấy từ `vanban.chinhphu.vn`. Không lấy từ thuvienphapluat.vn
  (trang này chặn truy cập tự động) hay vbpl.vn (cấm script ở phần dữ liệu). Văn bản
  địa phương hoặc rất cũ có thể không có.
- **Tình trạng hiệu lực:** cổng Chính phủ không ghi văn bản đã hết hiệu lực hay bị
  sửa đổi, thay thế. Skill suy luận "bản mới nhất còn hiệu lực" từ ngày ban hành và
  trích yếu, và ghi rõ đó là suy luận. Cần đối chiếu tại vbpl.vn trước khi trích dẫn.
- **Bộ văn bản liên quan có thể chưa đầy đủ:** văn bản hướng dẫn không nhắc tên luật
  trong trích yếu chỉ tìm được qua từ khóa theo từng mảng nội dung. File quan hệ ghi
  lại những từ khóa đã dùng.
- **Cổng Chính phủ thỉnh thoảng trả kết quả sai:** trang tìm kiếm đôi khi trả danh
  sách rỗng và trang chi tiết đôi khi báo "không tìm thấy" dù văn bản có thật; script
  tự thử lại vài lần trước khi tin kết quả rỗng. Mỗi truy vấn từ khóa chỉ trả tối đa
  50 văn bản mới nhất, nên với `-Top` lớn hơn 50 script chia truy vấn theo năm và in
  dòng `NOTE` nếu vẫn có thể còn thiếu. Văn bản dùng kết quả "không tìm thấy" cần thử
  lại bằng cụm từ ngắn hơn hoặc bằng số hiệu.
- **Bản Word là bản làm việc:** OCR có thể sai dấu, sai số, sai tiêu đề điều; bảng
  biểu không được kẻ lại; không giữ hình, con dấu, chữ ký. Luôn dò các con số quan
  trọng với PDF gốc và dùng PDF gốc khi trích dẫn chính thức.
- **PDF đã có chữ thật** (bôi đen và copy được) không cần OCR: mở thẳng bằng Word
  rồi lưu thành `.docx`.
- **Văn bản cũ có thể dùng font tiếng Việt kiểu cũ:** nhiều file RTF/DOC ban hành
  trước khoảng năm 2007 (ví dụ Luật Thương mại 2005) được gõ bằng font TCVN3 như
  `.VnTime`, `.VnArial`. Máy không cài các font này sẽ hiện ký tự lạ (ví dụ "Trõ
  trêng hîp" thay cho "Trừ trường hợp") dù file không hỏng, và Word thường không đọc
  được nội dung. Các skill hiện chưa tự chuyển mã. Thư mục
  `example/van-ban/Luat-Thuong-mai-36_2005_QH11/36_2005_QH11/` có file gốc
  `15224_l36qh.rtf` cùng bản đã chuyển sang Unicode (`15224_l36qh.docx`) để tham
  khảo; bản chuyển này được làm riêng một lần, kho chưa có công cụ làm lại tự động.
- **Chỉ chạy trên Windows:** script dùng Windows PowerShell 5.1 và bộ đọc PDF của
  Windows.

Chi tiết các vấn đề đã gặp và cách xử lý: [example/TOM-TAT-VAN-DE.md](example/TOM-TAT-VAN-DE.md).

### Dành cho người quản lý kho: đăng gói Tesseract

Cách cài tự động tải file `tesseract-portable-5.4.0-win64.zip` từ release có tag
`tesseract-portable-5.4.0` của kho này. File được tạo sẵn trong `dist/` và phải được
đăng lên Releases một lần. Script kiểm tra mã SHA-256 của file trước khi giải nén,
nên nếu thay file zip khác thì phải cập nhật `$script:BundleSha256` trong
`scan2word.ps1` rồi chạy lại lệnh đồng bộ sang Codex. Gói chứa Tesseract 5.4.0
(giấy phép Apache 2.0, kèm file `LICENSE`).

---

<a id="en"></a>

## English

A set of skills for Claude Code and OpenAI Codex that support company management and
administrative work, together with a guide to what a skill is, how to use one, and
how to build your own on Windows.

### What is a skill?

A skill is a folder of instructions that teaches an AI assistant (Claude Code,
Codex) to carry out a repeatable workflow the way you want it done. At minimum a
skill is a single `SKILL.md` file; larger skills add scripts for the steps that must
be exact.

```
skill-name/
├── SKILL.md      # required: name, when to use it, and the steps to follow
└── scripts/      # optional: scripts that the instructions in SKILL.md call
```

`SKILL.md` starts with two fields, `name` and `description`. The assistant always
reads these two; the instructions below them are loaded only when the skill is
selected. The `description` therefore decides whether the skill is used at the right
moment.

Claude Code and Codex share the same skill format but look in different folders, so
this repository keeps the same skills in both places:

| Tool | Skills in the repository | Personal skills (all repositories) | How to invoke |
|---|---|---|---|
| Claude Code | `.claude\skills\` (source) | `C:\Users\<name>\.claude\skills\` | `/skill-name` |
| OpenAI Codex | `.agents\skills\` (exact copy) | `C:\Users\<name>\.agents\skills\` | `$skill-name`, or pick it in `/skills` |

Both tools also select a skill on their own when your request matches its
`description`, without you typing the skill name.

### Available skills

| Skill | Purpose |
|---|---|
| [`han-download-law-doc`](.claude/skills/han-download-law-doc/SKILL.md) | Finds and downloads the original files (digitally signed PDFs) of Vietnamese legal documents from the Government portal `vanban.chinhphu.vn`, with a `metadata.json` recording the document number, issue date, effective date and source link. By default it downloads the full set: the latest version of the requested document, the implementing decrees, circulars and amendments currently applied, and a `QUAN-HE-VAN-BAN.md` file describing how they relate, with any special notes. Examples: [the Labor Code set](example/van-ban/Bo-luat-Lao-dong-45_2019_QH14/QUAN-HE-VAN-BAN.md) (9 documents), [the Law on Commerce set](example/van-ban/Luat-Thuong-mai-36_2005_QH11/QUAN-HE-VAN-BAN.md) (67 documents). |
| [`han-scan-to-word`](.claude/skills/han-scan-to-word/SKILL.md) | Analyzes a scanned PDF or a photographed document and converts it to an editable Word file (`.docx`) using Vietnamese OCR (Tesseract). |

The two skills chain together: download a document, then convert the scan to Word
for reference and drafting.

Language convention of this repository: `SKILL.md` files and scripts are written in
professional English only; the README and guides are bilingual, English and
Vietnamese. The assistant still replies in the language you use, and the
relationship file `QUAN-HE-VAN-BAN.md` is still written in Vietnamese because it
describes Vietnamese legal documents.

### Requirements

- Windows 10/11 with Windows PowerShell 5.1 (built in).
- [Claude Code](https://claude.com/claude-code) (terminal or desktop app) or OpenAI
  Codex (CLI or IDE extension).
- Internet access to `chinhphu.vn` (for `han-download-law-doc`).
- `han-scan-to-word` additionally needs Tesseract OCR and Vietnamese language data;
  the skill installs them on first use, see Installation below.

No Python, Node.js, Microsoft Word or administrator rights are needed.

### Installation

Clone the repository:

```bash
git clone https://github.com/nguyenquanicd/VLSIT_Company_Manager_AI_Skills.git
```

`han-download-law-doc` works immediately. `han-scan-to-word` needs Tesseract: the
first time the skill is used, the assistant checks the machine and, if something is
missing, asks you to choose one of the two options below. Once the machine is set
up, later runs go straight to work without asking again.

**Option 1 - the skill installs it (no administrator rights).** It downloads a
portable Tesseract with Vietnamese data (a zip of about 47 MB from this repository's
Releases) and unpacks it into `%LOCALAPPDATA%\han-scan-to-word` (about 130 MB).
Delete that folder to uninstall. You can also run it yourself:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 setup
```

On a machine without internet, copy the zip over and add `-BundlePath "<path to zip>"`.

**Option 2 - install Tesseract yourself with winget** (Windows asks for
administrator rights), then run the `setup` command above to fetch the Vietnamese
data:

```powershell
winget install --id UB-Mannheim.TesseractOCR -e
```

Check at any time; the expected result is `READY`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 check
```

### Ways to activate and use the skills

There are five ways, ordered from fully manual to fully installed. Choose by how
much you want the assistant to discover the skills on its own:

| # | Way | What to install | Where it works | Good for |
|---|---|---|---|---|
| 1 | Run the scripts directly | Nothing | Any folder | No AI assistant, or automating with your own scripts |
| 2 | Tell the assistant to read `SKILL.md` | Nothing | Any folder | A one-off trial, or when the assistant has not discovered the skill |
| 3 | Start the assistant in this repository | Just clone the repository | Inside this repository | The simplest way for regular use |
| 4 | Install as personal skills | Copy the skill folders | Any folder on the machine | Using the skills while working in other repositories |
| 5 | Install into another project | Copy the skill folders into that project | Inside that project | Sharing the skills with that project's team |

With ways 3, 4 and 5 the assistant discovers the skills itself; see "Invoking a
skill" below.

#### Way 1 - run the scripts directly (without an assistant)

Fully manual: you type the commands and read the results. None of the assistant's
judgement is involved (choosing the latest version, classifying relationships,
writing the relationship file).

```powershell
# Search, list related documents, and download
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 search -Keyword "dữ liệu cá nhân"
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 related -SoHieu "45/2019/QH14"
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 download -SoHieu "59/2020/QH14" -OutDir .\van-ban

# Analyze and convert a scanned PDF to Word
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 analyze -Path .\example\van-ban\45_2019_QH14\45.signed.pdf
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 convert -Path .\example\van-ban\45_2019_QH14\45.signed.pdf -OutFile .\test.docx -SaveText
```

The full parameter list is in each skill's `SKILL.md`.

#### Way 2 - tell the assistant to read `SKILL.md`

Nothing to install, and it works from any folder: point to the instruction file and
state your request. The assistant reads the file and follows it, even if it has not
discovered the skill.

```text
Read C:\path\to\VLSIT_Company_Manager_AI_Skills\.claude\skills\han-download-law-doc\SKILL.md
and follow it to download the Law on Enterprises.
```

In Claude Code you can type `@` and pick the skill file or folder instead of typing
the path.

#### Way 3 - start the assistant in this repository

The skills are already in the repository, so just start the assistant in its root:

```powershell
cd C:\path\to\VLSIT_Company_Manager_AI_Skills
claude      # or: codex
```

In the Claude desktop app, choose the repository folder as the working folder.

#### Way 4 - install as personal skills (works in every folder)

Copy the skill folders into your personal skills folder. Run from the repository
root:

```powershell
# Claude Code
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item ".claude\skills\han-*" "$env:USERPROFILE\.claude\skills\" -Recurse -Force

# Codex
New-Item -ItemType Directory -Force "$env:USERPROFILE\.agents\skills" | Out-Null
Copy-Item ".agents\skills\han-*" "$env:USERPROFILE\.agents\skills\" -Recurse -Force
```

A copy does not update itself: after `git pull`, run the copy commands again. To
keep the personal skills tied to the repository instead, replace the copy with a
folder link (junction); no administrator rights are needed:

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skills\han-download-law-doc" -Target "$PWD\.claude\skills\han-download-law-doc"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skills\han-scan-to-word" -Target "$PWD\.claude\skills\han-scan-to-word"
```

To uninstall, delete the `han-*` folders from the personal skills folder.

#### Way 5 - install into another project

Copy the skill folders into that project's `.claude\skills\` (Claude Code) or
`.agents\skills\` (Codex) - create that folder first if it does not exist - then
commit them so the whole team gets them:

```powershell
Copy-Item ".claude\skills\han-*" "C:\path\to\other-project\.claude\skills\" -Recurse -Force
Copy-Item ".agents\skills\han-*" "C:\path\to\other-project\.agents\skills\" -Recurse -Force
```

#### Invoking a skill

Once the skills are discovered (ways 3, 4, 5), there are two ways to invoke them.

**By name.** In Claude Code:

```text
/han-download-law-doc 59/2020/QH14
/han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
/han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

In Codex:

```text
$han-download-law-doc 59/2020/QH14
$han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
$han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

**In plain language.** The assistant selects a skill on its own when the request
matches its `description`, for example "download decree 13/2023/NĐ-CP and its
implementing documents" or "convert this scanned file to Word".

To check that a skill was discovered: in Claude Code type `/` and look for the
skill name in the list; in Codex type `/skills`. If a newly added skill does not
appear, restart the assistant.

While using them:

- If you invoke a skill without naming a document or file, the assistant asks.
- An approximate document name is fine: the assistant tries similar names and tells
  you which document it actually downloaded.
- Downloads go to `van-ban/` in the current working folder by default; the Word
  file is saved next to the source PDF. Sample results are in `example/van-ban/`.
- Both skills need network access (`chinhphu.vn`, `github.com`). If Codex is running
  with restricted network access, it asks for your approval before running commands.
- The skills run only on your Windows machine. They do not work in Claude on the
  web or in the mobile apps, because the scripts need Windows PowerShell.

### Building a new skill

There are two ways to create a skill.

**Option 1 - let the assistant create it.** Start the assistant in the repository
root, invoke the `skill-creator` skill (`/skill-creator` in Claude Code if it is
installed, `$skill-creator` in Codex), and describe the goal of the skill, when it
should be used, its inputs, and the expected output. The assistant writes `SKILL.md`
and any scripts; you try it and ask for changes.

**Option 2 - create it manually.** Run PowerShell from the repository root:

```powershell
New-Item -ItemType Directory -Force ".claude\skills\skill-name"
notepad ".claude\skills\skill-name\SKILL.md"
```

Then write `SKILL.md` from this template:

```markdown
---
name: skill-name
description: What the skill does and when to use it - name the situations and keywords users typically mention.
---

# Skill title

A short statement of what the skill does and does not do.

## Workflow

1. First step. If required input is missing, ask the user.
2. Next step, with the command to run if there is one.
3. Check the result before reporting completion.

## Output

- Where the result is saved and how files are named.
- What to report back to the user, including anything that could not be verified.
```

The two skills in this repository are complete examples to learn from.

Points worth keeping when writing a skill:

- **Name:** lowercase, hyphen-separated, identical to the folder name. This
  repository uses the `han-` prefix for administrative skills.
- **`description`:** state both what the skill does and when to use it, on one
  line, preferably under 500 characters, and without a colon followed by a space
  (that breaks the file header).
- **Explain the reason** behind each instruction instead of only giving orders; the
  assistant handles unusual cases better when it understands why.
- **Write `SKILL.md` in professional English**, including the `description`. Keep
  Vietnamese terms only where they are real data (search keywords, document names,
  the content of output files), and gloss them in English on first use.
- **Stay tool-neutral:** do not mention Claude or Codex, and do not write the `/` or
  `$` invocation syntax inside `SKILL.md`, so one file works for both tools.
- **Be honest about limits:** a skill must not invent missing content or report
  something as verified when it could not be checked.
- **PowerShell scripts** use ASCII characters only, so that Windows PowerShell 5.1
  reads them correctly on every machine.

**Sync to Codex.** Edit skills only in `.claude\skills\`, then run this command to
copy them to `.agents\skills\`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\sync-codex-skills.ps1
```

Add `-Check` to only verify that the two locations match, without copying anything.

Official documentation: [Codex skills](https://learn.chatgpt.com/docs/build-skills),
[Claude Code](https://claude.com/claude-code).

### Repository layout

```
.
├── .claude/skills/              # source of truth, read by Claude Code
│   ├── han-download-law-doc/
│   │   ├── SKILL.md
│   │   └── scripts/vanban.ps1
│   └── han-scan-to-word/
│       ├── SKILL.md
│       └── scripts/scan2word.ps1
├── .agents/skills/              # copy for Codex, generated by tools/sync-codex-skills.ps1
├── tools/
│   └── sync-codex-skills.ps1
├── example/
│   ├── van-ban/
│   │   ├── Bo-luat-Lao-dong-45_2019_QH14/   # sample set 1: 9 documents + relationship file
│   │   ├── Luat-Thuong-mai-36_2005_QH11/    # sample set 2: 67 documents + relationship file
│   │   └── 45_2019_QH14/                    # one document downloaded alone + Word file converted from the scan
│   └── TOM-TAT-VAN-DE.md        # problems met while building the skills and how they were solved (Vietnamese)
├── dist/                        # Tesseract bundle to publish under Releases (not in git)
└── README.md
```

### Known limitations

- **Document source:** documents come only from `vanban.chinhphu.vn`. Nothing is
  taken from thuvienphapluat.vn (it blocks automated access) or vbpl.vn (its data
  endpoints disallow scripts). Local-government or very old documents may be missing.
- **Validity status:** the Government portal does not say whether a document has
  expired or been amended or replaced. The skill infers "latest version in force"
  from issue dates and titles, and labels it as an inference. Cross-check at vbpl.vn
  before citing.
- **The related-document set may be incomplete:** implementing documents that do not
  name the law in their title are only found through topic keywords. The
  relationship file records the keywords that were used.
- **The Government portal sometimes returns wrong answers:** the search page
  occasionally returns an empty list, and a document page occasionally says "not
  found" for a document that exists; the script retries a few times before believing
  an empty result. A keyword query returns at most the 50 newest documents, so for
  `-Top` above 50 the script splits the query by year and prints a `NOTE` line when
  something may still be missing. Before concluding that a document does not exist,
  retry with a shorter phrase or with the document number.
- **The Word file is a working copy:** OCR can get diacritics, numbers and article
  headings wrong; tables are not rebuilt; images, stamps and signatures are not
  kept. Always check important figures against the original PDF, and cite from the
  original PDF.
- **PDFs that already contain real text** (selectable and copyable) do not need OCR:
  open them directly in Word and save as `.docx`.
- **Older documents may use legacy Vietnamese fonts:** many RTF/DOC files issued
  before about 2007 (for example the 2005 Law on Commerce) were typed in TCVN3 fonts
  such as `.VnTime` and `.VnArial`. On a machine without those fonts they show
  garbage characters (for example "Trõ trêng hîp" instead of "Trừ trường hợp") even
  though the file is intact, and Word usually cannot read the content. The skills do
  not convert these automatically yet. The folder
  `example/van-ban/Luat-Thuong-mai-36_2005_QH11/36_2005_QH11/` holds the original
  `15224_l36qh.rtf` together with a copy converted to Unicode (`15224_l36qh.docx`)
  for reference; that copy was made separately, once, and the repository has no tool
  to repeat the conversion automatically.
- **Windows only:** the scripts rely on Windows PowerShell 5.1 and the PDF renderer
  built into Windows.

Details of the problems met and how they were solved (in Vietnamese):
[example/TOM-TAT-VAN-DE.md](example/TOM-TAT-VAN-DE.md).

### For maintainers: publishing the Tesseract bundle

The automatic install downloads `tesseract-portable-5.4.0-win64.zip` from the
release tagged `tesseract-portable-5.4.0` in this repository. The file is built into
`dist/` and has to be published under Releases once. The script verifies the file's
SHA-256 before unpacking it, so if you replace the zip you must update
`$script:BundleSha256` in `scan2word.ps1` and run the Codex sync command again. The
bundle contains Tesseract 5.4.0 (Apache 2.0 license, `LICENSE` file included).
