# Test Milu AI như người dùng thật

Bộ test này kiểm tra Milu AI y như khi bạn chat trong app:

- AI chạy thật trên máy chủ.
- Công cụ của app chạy trên dữ liệu mẫu (`SampleData`).
- Chữ và thẻ được kiểm tra đúng như chat hiển thị, sau khi app đã qua các bước chặn lời sai.
- Các lượt tiếp theo như gõ "ok", bấm Lưu, sửa thẻ cũng được chạy y như trong chat.

## Các file

| File | Là gì |
|---|---|
| `cases.json` | Các case: người dùng nói gì, Milu phải làm gì. Thêm case mới ở đây. |
| `test-cases.md` | Danh sách case dạng bảng, dễ đọc (tạo từ `cases.json`). |
| `report.md` | Kết quả lần chạy gần nhất, kèm hội thoại của từng case chưa đạt. |
| `make_report.py` | Tạo hai file `.md` ở trên. |
| `runs/` | Dữ liệu gốc của các lần chạy làm ra `report.md`: từng câu Milu nói, thẻ, công cụ đã gọi. |
| `../../Tests/AILiveTests.swift` | Bài test chạy các case. |

## Chạy lại

Bài test gọi máy chủ thật, nên chỉ chạy khi bạn đặt biến `TEST_RUNNER_MILU_LIVE`. Chạy test bình thường thì nó bỏ qua.

Máy chủ cho tối đa 300 lượt gọi mỗi giờ (dùng chung với app), nên chạy làm hai đợt. Trước mỗi đợt, đặt lại bộ đếm bằng lệnh `ssh mypc 'cd ~/apps/milu-server && docker compose restart api'`.

```bash
TEST_RUNNER_MILU_LIVE=/tmp/live-1.json TEST_RUNNER_MILU_LIVE_ONLY="T,H,N,K,D" xcodebuild -scheme Milu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MiluTests/AILiveTests
```

```bash
TEST_RUNNER_MILU_LIVE=/tmp/live-2.json TEST_RUNNER_MILU_LIVE_ONLY="M,S,Q,R,L,X,A,G,V" xcodebuild -scheme Milu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MiluTests/AILiveTests
```

```bash
python3 -I docs/ai-tests/make_report.py /tmp/live-1.json /tmp/live-2.json
```

`TEST_RUNNER_MILU_LIVE_ONLY` chọn case theo mã (`H04`) hoặc theo chữ cái của nhóm (`H`). Các mã cách nhau bằng dấu phẩy.

AI trả lời mỗi lần một khác, nên một case có thể lúc đạt lúc không. Gặp case chưa đạt, hãy chạy riêng nó vài lần trước khi kết luận là lỗi.
