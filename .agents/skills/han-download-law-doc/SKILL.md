---
name: han-download-law-doc
description: Tìm và tải file gốc (PDF ký số) của văn bản pháp luật Việt Nam từ Cổng Thông tin điện tử Chính phủ (vanban.chinhphu.vn), kèm trọn bộ nghị định, thông tư, văn bản hướng dẫn và sửa đổi liên quan, chọn bản mới nhất còn hiệu lực, và lập file mô tả quan hệ giữa các văn bản. Dùng khi người dùng muốn tải, tìm, tra cứu một văn bản pháp luật, nêu số hiệu như "59/2020/QH14", hỏi văn bản nào quy định hay hướng dẫn một vấn đề, hoặc nhắc tới thuvienphapluat.vn, vbpl.vn - kể cả khi không nói chữ "tải".
compatibility: Windows PowerShell 5.1 trở lên (có sẵn trên Windows 10/11) hoặc PowerShell 7; cần truy cập internet tới chinhphu.vn.
---

# Tải văn bản pháp luật chính thống

Skill này lấy **file gốc do Nhà nước công bố** (thường là PDF có chữ ký số) từ
`vanban.chinhphu.vn`, kèm một file `metadata.json` ghi số hiệu, ngày ban hành, ngày
có hiệu lực, cơ quan ban hành, người ký và đường dẫn nguồn. Mặc định nó tải **trọn
bộ**: văn bản người dùng cần, các văn bản hướng dẫn và sửa đổi đang áp dụng, và một
file `QUAN-HE-VAN-BAN.md` giải thích quan hệ giữa chúng.

## Vì sao không lấy từ thuvienphapluat.vn

Người dùng hay gọi tên thuvienphapluat.vn vì quen, nhưng thứ họ thật sự cần là
văn bản đúng và dùng được. Trang đó là dịch vụ thương mại của một công ty tư nhân,
đặt lớp chống bot Cloudflare (script nhận HTTP 403, trình duyệt bị hỏi "xác minh
bạn là người") và khóa nút tải file sau tài khoản trả phí. Đừng tìm cách vượt qua
lớp bảo vệ đó - không giả lập trình duyệt, không giải CAPTCHA, không dùng thư viện
né Cloudflare.

Cổng Chính phủ thì cho phép truy cập tự động (`robots.txt`: `Allow: /`), miễn phí,
và là bản có giá trị tham chiếu chính thức - tức là tốt hơn cho đúng mục đích
"văn bản chính thống". Nếu người dùng nhắc thuvienphapluat.vn, hãy nói ngắn gọn
một câu lý do rồi tải từ cổng Chính phủ. Chỉ khi họ cần thứ riêng của TVPL (lược
đồ văn bản, bản dịch tiếng Anh, ghi chú hiệu lực) thì hướng dẫn họ tự mở trang đó
trong trình duyệt của mình.

## Cách dùng

Mọi thao tác đi qua một script: `scripts/vanban.ps1` (đường dẫn tính từ thư mục
skill này). Chạy bằng PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<thư mục skill>\scripts\vanban.ps1" <action> ...
```

### 1. Tìm (`search`)

```powershell
... vanban.ps1 search -Keyword "59/2020/QH14"
... vanban.ps1 search -Keyword "bảo vệ dữ liệu cá nhân" -Top 20
... vanban.ps1 search -Keyword "doanh nghiệp" -Loai luat -Year 2025
```

Mỗi dòng kết quả có dạng `[docId] số hiệu | ngày ban hành | trích yếu | files: n`.

| Tham số | Ý nghĩa |
|---|---|
| `-Keyword` | Số hiệu hoặc cụm từ trong trích yếu. Cổng so khớp theo chuỗi ký tự, nên gõ **có dấu** và dùng cụm ngắn, đặc trưng ("dữ liệu cá nhân" tốt hơn một câu dài). |
| `-Loai` | `hienphap`, `sacluat`, `luat` (luật và pháp lệnh), `nghidinh`, `quyetdinh`, `thongtu`. Bỏ trống = mọi loại. |
| `-Year` | Năm ban hành. |
| `-Top` | Số kết quả tối đa (mặc định 20, tối đa 500). |
| `-Class` | `1` = văn bản quy phạm pháp luật (mặc định). `2` = văn bản chỉ đạo điều hành (chỉ thị, công điện, công văn, quyết định cá biệt của Thủ tướng...). Không thấy ở lớp 1 thì thử lớp 2. |
| `-Json` | Xuất JSON thay vì văn bản, khi cần xử lý tiếp. |

### 2. Xem chi tiết (`info`)

```powershell
... vanban.ps1 info -DocId 216536
```

In toàn bộ thuộc tính và danh sách file đính kèm mà không tải gì. Dùng khi cần
kiểm tra ngày hiệu lực hay người ký trước khi quyết định tải.

### 3. Tải (`download`)

```powershell
... vanban.ps1 download -SoHieu "59/2020/QH14; 13/2023/NĐ-CP" -OutDir ".\van-ban"
... vanban.ps1 download -DocId 216536,216510 -OutDir ".\van-ban"
```

- `-SoHieu`: một hoặc nhiều số hiệu, ngăn cách bằng `;`. Chỉ tải khi số hiệu khớp
  **chính xác** (đã bỏ qua khác biệt hoa/thường, khoảng trắng, `Đ`/`D`, và các chữ
  Kirin trông giống chữ Latin mà cổng đôi khi nhập nhầm). Gõ `13/2023/ND-CP` không
  dấu vẫn được.
- `-DocId`: dùng khi đã có id từ bước tìm - cách chắc chắn nhất khi tìm theo chủ đề.
- `-OutDir`: mặc định `.\van-ban` trong thư mục làm việc hiện tại. Nếu người dùng
  nêu nơi lưu thì dùng nơi đó.
- `-Force`: tải đè file đã có (mặc định bỏ qua file đã tồn tại).

Kết quả trên đĩa:

```
van-ban/
└── 59_2020_QH14/
    ├── 59.signed.pdf      ← tên file giữ nguyên như trên cổng
    ├── 59tiep.pdf
    └── metadata.json
```

Mã thoát `2` nghĩa là có ít nhất một văn bản không tìm thấy hoặc không có file -
script vẫn tải xong các văn bản còn lại và in mục `NOT FOUND` kèm các kết quả gần
nhất.

### 4. Tìm văn bản liên quan (`related`)

```powershell
... vanban.ps1 related -SoHieu "45/2019/QH14"
... vanban.ps1 related -DocId 198540 -Keyword "tuổi nghỉ hưu;lao động nước ngoài;hợp đồng lao động"
```

Nhận đúng một văn bản gốc, rồi tìm trên cổng (cả lớp 1 và lớp 2) mọi văn bản nhắc
tới nó theo **số hiệu** và theo **tên**. Dòng đầu là văn bản gốc kèm ngày ban hành,
ngày có hiệu lực, và cờ `** NOT YET IN FORCE **` nếu chưa tới ngày hiệu lực. Mỗi
dòng sau là một ứng viên:

```
[docId] số hiệu | ngày ban hành | AFTER hoặc BEFORE | C1 hoặc C2 | trích yếu
```

- `AFTER` / `BEFORE`: ban hành sau hay trước văn bản gốc. Văn bản hướng dẫn một luật
  thì phải ban hành sau luật đó, nên nhóm `AFTER` là nơi tìm văn bản đang áp dụng;
  nhóm `BEFORE` phần lớn là văn bản của phiên bản luật cũ.
- `-Keyword`: thêm cụm từ tìm kiếm, ngăn cách bằng `;`. Rất cần, vì script chỉ tìm
  theo tên và số hiệu của văn bản gốc - xem "Vì sao phải thêm từ khóa" bên dưới.

Script chỉ **gom ứng viên**. Việc xác định từng văn bản quan hệ thế nào với văn bản
gốc là phần của bạn, dựa trên câu chữ của trích yếu.

## Quy trình nên theo

Mặc định, người dùng cần **trọn bộ** chứ không chỉ một file: văn bản họ hỏi, kèm các
nghị định, thông tư, văn bản hướng dẫn thi hành và sửa đổi đang áp dụng, cùng một
file giải thích quan hệ giữa chúng. Một luật đứng riêng thường không đủ để làm
việc, vì phần lớn chi tiết thực thi nằm ở văn bản hướng dẫn. Chỉ tải riêng một văn
bản khi người dùng nói rõ họ chỉ cần đúng văn bản đó.

0. **Chưa có tên văn bản** → hỏi người dùng trước khi làm gì khác. Nếu skill được
   gọi mà không kèm tên, số hiệu hay chủ đề nào (ví dụ chỉ gõ tên skill
   `han-download-law-doc`, hoặc "tải giúp tôi văn bản pháp luật"), hãy hỏi một câu
   ngắn: họ cần văn bản nào - tên hoặc số hiệu, và nếu nhớ thì cả năm ban hành.
   Đừng tự chọn một văn bản thay họ và đừng chạy script khi chưa có câu trả lời.
1. **Xác định văn bản gốc** bằng `search` (theo số hiệu hoặc tên; xem "Khi tên
   người dùng đưa không khớp").
2. **Chọn bản mới nhất còn hiệu lực** của văn bản gốc - xem mục "Luôn lấy bản mới
   nhất đang còn hiệu lực".
3. **Gom văn bản liên quan** bằng `related`, chạy thêm với `-Keyword` cho các mảng
   nội dung chính của văn bản gốc.
4. **Phân loại và chọn lọc** từng ứng viên: quan hệ gì với văn bản gốc, còn áp dụng
   hay đã bị thay thế. Bỏ ứng viên không liên quan (trùng từ khóa nhưng khác chủ đề).
5. **Tải** tất cả văn bản được chọn vào một thư mục chung bằng một lệnh `download
   -DocId ... -OutDir "van-ban\<tên bộ>"`, ví dụ
   `van-ban\Bo-luat-Lao-dong-45_2019_QH14`. Nếu bộ có trên 20 văn bản, nói số lượng
   cho người dùng và hỏi họ muốn tải hết hay chỉ nhóm chính.
6. **Viết file quan hệ** `QUAN-HE-VAN-BAN.md` vào thư mục đó - xem mẫu bên dưới.
7. **Báo lại**: văn bản gốc (số hiệu, tên, ngày ban hành, ngày hiệu lực), số văn bản
   đã tải theo từng nhóm, link tới thư mục và file quan hệ, và **mọi lưu ý đặc biệt**.

## Luôn lấy bản mới nhất đang còn hiệu lực

Cổng Chính phủ **không ghi** văn bản còn hay hết hiệu lực. Vì vậy việc này là suy
luận từ bằng chứng, và phải nói rõ với người dùng là suy luận. Cách làm:

- **Văn bản gốc.** Tìm theo tên để xem có văn bản cùng tên, cùng loại, ban hành
  muộn hơn không (Luật Đất đai 2013 và 2024; Bộ luật Lao động 2012 và 2019). Nếu có,
  bản mới nhất là bản cần tải. Nếu người dùng nêu đích danh số hiệu của bản cũ, vẫn
  tải bản mới nhất làm văn bản gốc và nói rõ: bản họ nêu đã có bản thay thế. Chỉ
  tải thêm bản cũ nếu họ cần (ví dụ để xử lý vụ việc phát sinh trước ngày bản mới
  có hiệu lực).
- **Chưa có hiệu lực.** Nếu script báo `NOT YET IN FORCE`, bản mới nhất chưa áp
  dụng: tải cả bản mới lẫn bản đang có hiệu lực, và nêu rõ ngày chuyển giao.
- **Văn bản sửa đổi, bổ sung.** Trích yếu dạng "Luật sửa đổi, bổ sung một số điều
  của ..." ban hành sau văn bản gốc là một phần của bộ: văn bản gốc phải đọc cùng
  nó. Tìm cả "văn bản hợp nhất" (ký hiệu `VBHN`), nếu có thì tải kèm vì đó là bản
  đã gộp sẵn các sửa đổi.
- **Văn bản hướng dẫn.** Chỉ lấy văn bản thuộc nhóm `AFTER` và thật sự hướng dẫn
  văn bản gốc. Trong nhóm đó, nếu hai văn bản cùng nội dung (cùng trích yếu, hoặc
  văn bản sau ghi "thay thế", "sửa đổi, bổ sung Nghị định số ...") thì bản sau là
  bản áp dụng; bản trước chỉ ghi vào file quan hệ, không tải, trừ khi nó chỉ bị
  sửa một phần - khi đó tải cả hai.
- **Nhóm `BEFORE`** hướng dẫn phiên bản luật cũ: không tải, nhưng ghi các văn bản
  chính vào mục "không tải" của file quan hệ để người dùng biết chúng tồn tại.
- **Khi cần bằng chứng chắc hơn** cho văn bản gốc hoặc một trường hợp mơ hồ: điều
  khoản "Hiệu lực thi hành" ở cuối văn bản ghi rõ nó thay thế, bãi bỏ văn bản nào.
  Dùng skill `han-scan-to-word` với `-Pages` cho vài trang cuối của file đã tải để
  đọc điều khoản đó, rồi ghi vào cột "Căn cứ xác định".

Đừng bao giờ viết "còn hiệu lực" như một sự thật đã kiểm chứng. Viết "theo các văn
bản tìm được trên cổng Chính phủ, chưa thấy văn bản thay thế" và nhắc người dùng đối
chiếu ở vbpl.vn.

### Vì sao phải thêm từ khóa

Lệnh `related` tìm theo tên và số hiệu của văn bản gốc, nên bỏ sót các văn bản
hướng dẫn không nhắc tên luật trong trích yếu. Ví dụ với Bộ luật Lao động 2019,
tìm theo tên chỉ ra Nghị định 145/2020/NĐ-CP; nghị định về tuổi nghỉ hưu hay về
lao động nước ngoài có trích yếu không chứa chữ "Bộ luật Lao động".

Để bù lại, hãy liệt kê các mảng nội dung chính của văn bản gốc và chạy `related`
hoặc `search` với từng cụm ("tuổi nghỉ hưu", "lao động nước ngoài", "tiền lương tối
thiểu", "xử phạt vi phạm hành chính" kèm lĩnh vực...). Hiểu biết sẵn có của bạn về
văn bản nào hướng dẫn luật nào là **đầu mối để tìm**, không phải kết quả: mỗi số
hiệu bạn nhớ phải được tìm thấy trên cổng thì mới được đưa vào bộ, và trí nhớ có
thể đã cũ - một nghị định bạn nhớ có thể đã bị thay thế sau thời điểm bạn biết.

Vì vậy bộ văn bản **không được cam kết là đầy đủ**. Ghi điều này vào file quan hệ.

## File quan hệ `QUAN-HE-VAN-BAN.md`

Viết bằng tiếng Việt, đặt ở gốc thư mục bộ văn bản, theo đúng khung sau. File này
là thứ người dùng mở đầu tiên, nên nó phải tự đứng được: ai đọc cũng hiểu bộ văn bản
gồm gì, văn bản nào phụ thuộc văn bản nào, và điều gì cần cẩn thận.

```markdown
# Quan hệ giữa các văn bản: <tên văn bản gốc>

Lập ngày <ngày>. Nguồn: vanban.chinhphu.vn.

## Văn bản gốc

| Số hiệu | Tên | Ngày ban hành | Có hiệu lực từ | Thư mục |
|---|---|---|---|---|

## Lưu ý đặc biệt

- <mỗi lưu ý một dòng; nếu không có thì ghi "Không có lưu ý đặc biệt.">

## Sơ đồ quan hệ

<cây chữ: văn bản gốc ở trên, văn bản sửa đổi và hướng dẫn thụt vào bên dưới,
văn bản hướng dẫn nghị định thụt thêm một cấp>

## Các văn bản đã tải

| Số hiệu | Tên / trích yếu | Ngày ban hành | Có hiệu lực từ | Quan hệ với văn bản gốc | Căn cứ xác định | Thư mục |
|---|---|---|---|---|---|---|

## Văn bản liên quan không tải

| Số hiệu | Trích yếu | Ngày ban hành | Lý do không tải |
|---|---|---|---|

## Giới hạn của bản tổng hợp này

- Tình trạng hiệu lực là suy luận từ ngày ban hành và trích yếu, không phải dữ liệu
  chính thức. Đối chiếu tại vbpl.vn trước khi trích dẫn.
- Danh sách có thể chưa đầy đủ: <nêu các mảng đã tìm và các từ khóa đã dùng>.
```

Cột **Quan hệ với văn bản gốc** dùng một trong các cách gọi sau để người dùng lọc
được:

| Quan hệ | Khi nào dùng |
|---|---|
| Sửa đổi, bổ sung văn bản gốc | Văn bản cùng cấp ban hành sau, thay đổi một số điều của văn bản gốc. |
| Văn bản hợp nhất | Bản gộp văn bản gốc với các lần sửa đổi. |
| Quy định chi tiết / hướng dẫn thi hành | Nghị định, thông tư cụ thể hóa các điều của văn bản gốc. |
| Hướng dẫn văn bản hướng dẫn | Thông tư hướng dẫn một nghị định trong bộ (quan hệ cấp hai). |
| Xử phạt vi phạm | Nghị định xử phạt vi phạm hành chính trong lĩnh vực của văn bản gốc. |
| Văn bản gốc thay thế văn bản này | Phiên bản trước của văn bản gốc (thường nằm ở mục không tải). |
| Liên quan khác | Có dẫn chiếu tới văn bản gốc nhưng không thuộc các loại trên; nêu rõ là gì. |

Cột **Căn cứ xác định** ghi vì sao bạn kết luận quan hệ đó: "trích yếu ghi rõ",
"điều khoản thi hành của văn bản (đã đọc)", hoặc "suy luận từ nội dung và ngày ban
hành". Người dùng cần biết kết luận nào chắc, kết luận nào là phán đoán.

## Lưu ý đặc biệt phải báo cho người dùng

Những điều sau đây làm thay đổi cách người dùng được phép dựa vào bộ văn bản, nên
phải nêu **cả trong câu trả lời lẫn trong file quan hệ**, không được để chìm trong
bảng:

- Văn bản gốc hoặc văn bản quan trọng trong bộ **chưa có hiệu lực**, kèm ngày bắt
  đầu có hiệu lực.
- Văn bản người dùng hỏi **đã có bản mới thay thế**, và bạn đã tải bản mới.
- Văn bản gốc **đã bị sửa đổi** bởi văn bản khác: phải đọc cùng nhau.
- Có **giai đoạn chuyển tiếp**: bản cũ và bản mới cùng tồn tại, hoặc văn bản hướng
  dẫn của bản cũ còn được áp dụng tạm.
- Văn bản mới nhưng **chưa thấy văn bản hướng dẫn** trên cổng.
- Văn bản trong bộ **không có file đính kèm**, hoặc file tải về không hợp lệ.
- Có văn bản bạn biết là liên quan nhưng **không tìm thấy trên cổng**.
- Kết luận về hiệu lực hoặc quan hệ của một văn bản quan trọng chỉ là **phán đoán**.

Nếu không có lưu ý nào, nói rõ là không có, thay vì bỏ trống.

## Khi tên người dùng đưa không khớp

Người dùng thường nhớ tên văn bản gần đúng: sai chính tả, thiếu dấu, gọi theo tên
quen miệng ("luật bảo vệ thông tin cá nhân" thay cho "Luật Bảo vệ dữ liệu cá
nhân"), hoặc nhớ nhầm số hay năm. Cổng lại so khớp theo đúng chuỗi ký tự, nên một
lần tìm không ra chưa có nghĩa là văn bản không tồn tại. Trước khi báo không tìm
thấy, hãy tự thử các tên tương tự:

- **Rút gọn về phần cốt lõi**: bỏ chữ chỉ loại văn bản và các từ đệm ("Luật", "Nghị
  định về", "quy định"), chỉ giữ cụm đặc trưng - "dữ liệu cá nhân", "đất đai".
- **Sửa lỗi gõ**: thêm dấu tiếng Việt, sửa chính tả, thử cách viết khác của cùng
  một từ.
- **Thử từ đồng nghĩa hoặc tên chính thức** mà bạn biết: "sổ đỏ" → "giấy chứng nhận
  quyền sử dụng đất", "luật lao động" → "Bộ luật Lao động".
- **Nới bộ lọc**: bỏ `-Year`, bỏ `-Loai`, đổi sang `-Class 2`.
- **Số hiệu nghi sai**: nếu `download -SoHieu` báo `NOT FOUND`, xem danh sách
  "closest results" script in ra, và tìm lại theo tên văn bản nếu người dùng có
  nêu - có thể họ nhớ nhầm số, năm hoặc ký hiệu cơ quan.

Sau khi tìm bằng tên tương tự:

- Một kết quả khớp rõ ràng với ý người dùng → tải luôn, và **nói rõ** là đã tải văn
  bản nào thay cho tên họ đưa, ví dụ: "Không có văn bản tên 'Luật bảo vệ thông tin
  cá nhân'; tôi đã tải Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15." Người dùng cần
  biết có sự thay thế để tự kiểm tra, vì họ có thể sẽ trích dẫn văn bản này.
- Nhiều kết quả đều có thể đúng → đưa danh sách ngắn (số hiệu, ngày, trích yếu) để
  họ chọn.
- Thử vài biến thể vẫn không có gì gần → báo không tìm thấy, liệt kê các tên đã
  thử, và hỏi lại tên hoặc số hiệu chính xác hơn.

## Những điều cần nói thật với người dùng

- **Tình trạng hiệu lực**: cổng này ghi ngày ban hành và ngày có hiệu lực, nhưng
  không ghi văn bản "còn hiệu lực", "hết hiệu lực" hay đã bị sửa đổi, thay thế.
  Đừng khẳng định một văn bản còn hiệu lực chỉ vì tải được nó. Nếu người dùng cần
  biết điều đó, tìm thêm văn bản sửa đổi/thay thế bằng `search` theo tên, và nói rõ
  là nên đối chiếu tại vbpl.vn (CSDL quốc gia về pháp luật của Bộ Tư pháp).
- **Không tìm thấy**: cổng mạnh về văn bản của Quốc hội, Chính phủ, Thủ tướng và
  các bộ; văn bản địa phương hoặc rất cũ có thể thiếu. Khi `search` không ra, thử
  lại với từ khóa ngắn hơn, bỏ `-Loai`/`-Year`, đổi `-Class 2`. Vẫn không có thì
  nói thẳng là không có trên cổng Chính phủ và gợi ý người dùng tự tra ở vbpl.vn
  hoặc congbao.chinhphu.vn - đừng bịa nội dung hay lấy từ nguồn không chính thức
  rồi gọi là bản chính thống.
- **PDF scan**: nhiều file là bản scan có dấu đỏ, không có lớp chữ. Nếu người dùng
  muốn đọc hay trích nội dung, cần bước OCR riêng (skill `han-scan-to-word`), và nên nói rõ văn
  bản OCR có thể sai chính tả, không thay được bản gốc.
- **Một văn bản nhiều file**: văn bản dài thường bị cắt thành nhiều phần
  (`59.signed.pdf`, `59tiep.pdf`) hoặc có phụ lục riêng. Tất cả đều được tải; hãy
  nhắc người dùng rằng nội dung nằm trên nhiều file.

## Giữ phép lịch sự với máy chủ

Script tự nghỉ khoảng 0,8 giây giữa các yêu cầu và tự thử lại khi lỗi tạm thời. Đây
là máy chủ công, nên đừng hạ `-DelayMs` xuống thấp và đừng chạy nhiều tiến trình
song song để tải nhanh hơn. Tải vài chục văn bản một lượt là bình thường; nếu người
dùng muốn sao chép cả kho dữ liệu thì hỏi lại mục đích trước.

## Khi script báo lỗi

- `Search form not found ...`: cổng đã đổi giao diện. Mở
  `https://vanban.chinhphu.vn/he-thong-van-ban?classid=1&mode=1` xem cấu trúc mới
  và sửa các biểu thức trong `Search-Documents` / `ConvertFrom-ResultPage`.
- `Request failed ... HTTP 5xx` hoặc timeout: cổng đang quá tải, đợi vài phút rồi
  chạy lại; file đã tải sẽ được bỏ qua.
- `downloaded-but-not-a-valid-pdf`: máy chủ trả về thứ không phải PDF (thường là
  trang lỗi). Báo cho người dùng và đưa link nguồn trong `metadata.json` để họ tự
  kiểm tra.
