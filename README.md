# VLSIT Company Manager AI Skills

**[Tiếng Việt](#vi)** | **[English](#en)**

<a id="vi"></a>

## Tiếng Việt

Bộ skill cho Claude Code và OpenAI Codex phục vụ công việc quản lý, hành chính của
công ty, kèm hướng dẫn để hiểu skill là gì, cách dùng và cách tự xây dựng skill mới
trên Windows.

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
| [`han-download-law-doc`](.claude/skills/han-download-law-doc/SKILL.md) | Tìm và tải file gốc (PDF ký số) của văn bản pháp luật Việt Nam từ Cổng Thông tin điện tử Chính phủ `vanban.chinhphu.vn`, kèm `metadata.json` ghi số hiệu, ngày ban hành, ngày hiệu lực, link nguồn. Mặc định tải trọn bộ: bản mới nhất của văn bản cần tìm, các nghị định, thông tư hướng dẫn và sửa đổi đang áp dụng, và file `QUAN-HE-VAN-BAN.md` mô tả quan hệ giữa chúng cùng các lưu ý đặc biệt. Ví dụ: [bộ văn bản Bộ luật Lao động](example/van-ban/Bo-luat-Lao-dong-45_2019_QH14/QUAN-HE-VAN-BAN.md). |
| [`han-scan-to-word`](.claude/skills/han-scan-to-word/SKILL.md) | Phân tích và chuyển PDF scan hoặc ảnh chụp tài liệu thành file Word (`.docx`) bằng OCR tiếng Việt (Tesseract). |

Hai skill dùng nối tiếp được: tải văn bản về, rồi chuyển bản scan sang Word để tra
cứu và soạn thảo. Nội dung `SKILL.md` của hai skill viết bằng tiếng Việt.

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

### Cách dùng

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

#### Chạy script trực tiếp (không qua trợ lý)

```powershell
# Tìm và tải văn bản
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 search -Keyword "dữ liệu cá nhân"
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 download -SoHieu "59/2020/QH14" -OutDir .\van-ban

# Phân tích và chuyển PDF scan sang Word
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 analyze -Path .\example\van-ban\45_2019_QH14\45.signed.pdf
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 convert -Path .\example\van-ban\45_2019_QH14\45.signed.pdf -OutFile .\thu.docx -SaveText
```

Danh sách tham số đầy đủ nằm trong `SKILL.md` của từng skill.

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
│   ├── van-ban/                 # ví dụ mẫu: Bộ luật Lao động đã tải và file Word đã chuyển
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
- **Bản Word là bản làm việc:** OCR có thể sai dấu, sai số, sai tiêu đề điều; bảng
  biểu không được kẻ lại; không giữ hình, con dấu, chữ ký. Luôn dò các con số quan
  trọng với PDF gốc và dùng PDF gốc khi trích dẫn chính thức.
- **PDF đã có chữ thật** (bôi đen và copy được) không cần OCR: mở thẳng bằng Word
  rồi lưu thành `.docx`.
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
| [`han-download-law-doc`](.claude/skills/han-download-law-doc/SKILL.md) | Finds and downloads the original files (digitally signed PDFs) of Vietnamese legal documents from the Government portal `vanban.chinhphu.vn`, with a `metadata.json` recording the document number, issue date, effective date and source link. By default it downloads the full set: the latest version of the requested document, the implementing decrees, circulars and amendments currently applied, and a `QUAN-HE-VAN-BAN.md` file describing how they relate, with any special notes. Example: [the Labor Code set](example/van-ban/Bo-luat-Lao-dong-45_2019_QH14/QUAN-HE-VAN-BAN.md). |
| [`han-scan-to-word`](.claude/skills/han-scan-to-word/SKILL.md) | Analyzes a scanned PDF or a photographed document and converts it to an editable Word file (`.docx`) using Vietnamese OCR (Tesseract). |

The two skills chain together: download a document, then convert the scan to Word
for reference and drafting. The `SKILL.md` files of both skills are written in
Vietnamese.

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

### Usage

Start the assistant in the repository root; it discovers the skills in the
repository automatically.

**Claude Code** (run `claude` in a terminal, or open the folder in the desktop app):

```text
/han-download-law-doc 59/2020/QH14
/han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
/han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

**Codex** (run `codex` in a terminal):

```text
$han-download-law-doc 59/2020/QH14
$han-download-law-doc Luật Bảo vệ dữ liệu cá nhân
$han-scan-to-word example\van-ban\45_2019_QH14\45.signed.pdf
```

Or simply describe what you want in plain language in either tool, for example
"download decree 13/2023/NĐ-CP" or "convert this scanned file to Word".

- If you invoke a skill without naming a document or file, the assistant asks.
- An approximate document name is fine: the assistant tries similar names and tells
  you which document it actually downloaded.
- Downloads go to `van-ban/<document number>/` in the current working folder by
  default; the Word file is saved next to the source PDF. A sample result set is in
  `example/van-ban/`.
- If a newly added skill does not appear, restart the assistant. In Codex, `/skills`
  lists the skills that were discovered.
- Both skills need network access (`chinhphu.vn`, `github.com`). If Codex is running
  with restricted network access, it asks for your approval before running commands.

To use a skill from any folder on the machine, copy the skill folder into the
personal skills folder listed in the table under "What is a skill?".

#### Running the scripts directly (without an assistant)

```powershell
# Search for and download a document
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 search -Keyword "dữ liệu cá nhân"
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-download-law-doc\scripts\vanban.ps1 download -SoHieu "59/2020/QH14" -OutDir .\van-ban

# Analyze and convert a scanned PDF to Word
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 analyze -Path .\example\van-ban\45_2019_QH14\45.signed.pdf
powershell -NoProfile -ExecutionPolicy Bypass -File .claude\skills\han-scan-to-word\scripts\scan2word.ps1 convert -Path .\example\van-ban\45_2019_QH14\45.signed.pdf -OutFile .\test.docx -SaveText
```

The full parameter list is in each skill's `SKILL.md`.

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
│   ├── van-ban/                 # sample output: the downloaded Labor Code and its Word conversion
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
- **The Word file is a working copy:** OCR can get diacritics, numbers and article
  headings wrong; tables are not rebuilt; images, stamps and signatures are not
  kept. Always check important figures against the original PDF, and cite from the
  original PDF.
- **PDFs that already contain real text** (selectable and copyable) do not need OCR:
  open them directly in Word and save as `.docx`.
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
