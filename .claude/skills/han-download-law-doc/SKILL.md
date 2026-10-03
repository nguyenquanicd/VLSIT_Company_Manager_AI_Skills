---
name: han-download-law-doc
description: Tìm và tải file gốc (PDF ký số, DOC) của văn bản pháp luật Việt Nam từ Cổng Thông tin điện tử Chính phủ (vanban.chinhphu.vn) - luật, nghị định, thông tư, quyết định, chỉ thị, công văn. Dùng khi người dùng muốn tải, tìm, tra cứu hoặc lưu một văn bản pháp luật, nêu số hiệu như "59/2020/QH14" hay "13/2023/NĐ-CP", hỏi văn bản nào quy định về một vấn đề, cần bản chính thức để trích dẫn, hoặc nhắc tới thuvienphapluat.vn, vbpl.vn, công báo - kể cả khi không nói chữ "tải".
compatibility: Windows PowerShell 5.1 trở lên (có sẵn trên Windows 10/11) hoặc PowerShell 7; cần truy cập internet tới chinhphu.vn.
---

# Tải văn bản pháp luật chính thống

Skill này lấy **file gốc do Nhà nước công bố** (thường là PDF có chữ ký số) từ
`vanban.chinhphu.vn`, kèm một file `metadata.json` ghi số hiệu, ngày ban hành, ngày
có hiệu lực, cơ quan ban hành, người ký và đường dẫn nguồn.

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

## Quy trình nên theo

0. **Chưa có tên văn bản** → hỏi người dùng trước khi làm gì khác. Nếu skill được
   gọi mà không kèm tên, số hiệu hay chủ đề nào (ví dụ chỉ gõ tên
   skill `han-download-law-doc`, hoặc "tải giúp tôi văn bản pháp luật"), hãy hỏi một câu
   ngắn: họ cần văn bản nào - tên hoặc số hiệu, và nếu nhớ thì cả năm ban hành.
   Đừng tự chọn một văn bản thay họ và đừng chạy script khi chưa có câu trả lời.
1. **Có số hiệu** → `download -SoHieu` thẳng. Không cần tìm trước.
2. **Chỉ có tên hoặc chủ đề** → `search`, rồi:
   - nếu chỉ một kết quả hợp lý rõ ràng, tải luôn bằng `-DocId`;
   - nếu có nhiều văn bản cùng tên qua các thời kỳ (ví dụ Luật Đất đai 2013 và
     2024, hoặc luật gốc và luật sửa đổi), đưa danh sách ngắn cho người dùng chọn.
     Đoán sai phiên bản luật là lỗi có hậu quả thật, nên đây là lúc đáng hỏi.
3. **Báo lại** cho người dùng: số hiệu, tên văn bản, ngày ban hành, ngày có hiệu
   lực, và đường dẫn file đã lưu (dạng link bấm được).

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
