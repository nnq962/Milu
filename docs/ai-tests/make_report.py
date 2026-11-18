"""Makes the readable pages of the Milu AI live test.

    python3 -I docs/ai-tests/make_report.py                 # test-cases.md from cases.json
    python3 -I docs/ai-tests/make_report.py run1.json ...   # and report.md from the runs

The runs are what Tests/AILiveTests.swift writes (TEST_RUNNER_MILU_LIVE=<file>); several are
merged, a later one winning for a case run twice.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def money(value) -> str:
    return f"{int(value):,}".replace(",", ".") + "đ"


def describe_card(card: dict) -> str:
    parts = []
    if "rows" in card:
        parts.append(f"{card['rows']} khoản")
    if "amounts" in card:
        parts.append(", ".join(money(a) for a in card["amounts"]))
    if "amountsInclude" in card:
        parts.append("có " + ", ".join(money(a) for a in card["amountsInclude"]))
    if "kind" in card:
        parts.append("khoản thu" if card["kind"] == "income" else "khoản chi")
    if "category" in card:
        parts.append("mục " + " hoặc ".join(card["category"]))
    if "notCategory" in card:
        parts.append("không phải mục " + " / ".join(card["notCategory"]))
    if "newItem" in card:
        parts.append(f"đề xuất mục mới “{card['newItem']}”")
    if "account" in card:
        parts.append("tài khoản " + " / ".join(card["account"]))
    if card.get("accountChosen"):
        parts.append("ghi “Milu tự chọn” tài khoản")
    if "date" in card:
        parts.append({"today": "hôm nay", "yesterday": "hôm qua"}.get(card["date"], f"ngày {card['date']}"))
    if "note" in card:
        parts.append(f"ghi chú có “{card['note']}”")
    if card.get("warning"):
        parts.append("cảnh báo trùng")
    if card.get("replaces"):
        parts.append("thay thẻ cũ")
    return "thẻ chờ Lưu" + (": " + ", ".join(parts) if parts else "")


def describe(expect: dict) -> str:
    if not expect:
        return ""
    if expect.get("anyOf"):
        return " **hoặc** ".join(describe(option) for option in expect["anyOf"])
    parts = []
    if "card" in expect:
        parts.append(describe_card(expect["card"]))
    if expect.get("noCard"):
        parts.append("không ra thẻ")
    if expect.get("asks"):
        parts.append("hỏi lại")
    names = {"transfer": "chuyển tiền", "loan": "vay nợ", "goal": "hũ"}
    for kind in expect.get("refused", []):
        parts.append(f"nói thật chưa ghi được {names.get(kind, kind)}, chỉ cách ghi tay")
    if "tool" in expect:
        parts.append("tra bằng " + " / ".join(expect["tool"]))
    if expect.get("noTool"):
        parts.append("không gọi công cụ")
    if "deleteCard" in expect:
        parts.append("hiện thẻ xác nhận xoá" if expect["deleteCard"] else "không hiện thẻ xoá")
    for group in expect.get("has", []):
        parts.append("nói “" + "” hoặc “".join(group) + "”")
    if expect.get("not"):
        parts.append("không nói “" + "”, “".join(expect["not"]) + "”")
    if expect.get("once"):
        parts.append("“" + "”, “".join(expect["once"]) + "” chỉ nói một lần")
    if "saved" in expect:
        parts.append(f"đã lưu {expect['saved']} khoản")
    if "newItemSaved" in expect:
        parts.append(f"đã tạo mục “{expect['newItemSaved']}”")
    return "; ".join(parts)


def said(turn: dict) -> str:
    if "tap" in turn:
        return {"save": "*(bấm Lưu)*", "cancel": "*(bấm Huỷ)*"}.get(turn["tap"], turn["tap"])
    return f"“{turn['say']}”"


def test_cases(data: dict) -> str:
    lines = ["# Bộ test Milu AI", "",
             "Mỗi case là một cuộc chat mới trên dữ liệu mẫu của app. Chạy bằng `Tests/AILiveTests.swift`"
             " (xem README.md). Mọi câu trả lời còn được kiểm chung: không mở đầu bằng “Ủa”/“Ê”,"
             " không lộ mã thẻ hay lời nhắc hệ thống, không nói “thẻ” với người dùng (trừ thẻ tín dụng), không trống.", ""]
    for letter, name in data["groups"].items():
        cases = [c for c in data["cases"] if c["id"].startswith(letter)]
        lines += [f"## {letter} · {name} ({len(cases)} case)", "",
                  "| ID | Tình huống | Người dùng | Milu phải |", "|---|---|---|---|"]
        for case in cases:
            for index, turn in enumerate(case["turns"]):
                first = index == 0
                lines.append(f"| {case['id'] if first else ''} | {case['title'] if first else '↳'} | "
                             f"{said(turn)} | {describe(turn.get('expect', {}))} |")
        lines.append("")
    return "\n".join(lines)


def seen_card(card) -> str:
    if not card:
        return ""
    rows = []
    for row in card["rows"]:
        bits = [row["category"] + (" (mục mới)" if row["isNew"] else ""), money(row["amount"]),
                "thu" if row["kind"] == "income" else "chi",
                row["account"] + (" (Milu tự chọn)" if row["accountChosen"] else ""), row["date"]]
        if row["note"]:
            bits.append(f"ghi chú “{row['note']}”")
        if row.get("warning"):
            bits.append(f"⚠️ {row['warning']}")
        rows.append(" · ".join(bits))
    head = "Thẻ" + (" (thay thẻ cũ)" if card["replaces"] else "")
    return head + ": " + " | ".join(rows)


def report(cases: list[dict], groups: dict, date: str, runs: int) -> str:
    passed = sum(c["passed"] for c in cases)
    lines = [f"# Kết quả test Milu AI ({date})", "",
             f"**{passed}/{len(cases)} case đạt** ({round(100 * passed / max(1, len(cases)))}%).", ""]
    if runs > 1:
        lines += [f"Gộp {runs} lần chạy: case nào chạy lại thì lấy lần sau cùng. AI trả lời mỗi lần một khác, "
                  "nên một case đạt ở đây vẫn có thể có lúc trượt.", ""]
    lines += ["| Nhóm | Đạt |", "|---|---|"]
    for letter, name in groups.items():
        group = [c for c in cases if c["id"].startswith(letter)]
        if group:
            ok = sum(c["passed"] for c in group)
            lines.append(f"| {letter} · {name} | {ok}/{len(group)}{'' if ok == len(group) else ' ⚠️'} |")
    failed = [c for c in cases if not c["passed"]]
    lines += ["", f"## Case chưa đạt ({len(failed)})", ""]
    for case in failed:
        lines += [f"### {case['id']} · {case['title']}", ""]
        for turn in case["turns"]:
            lines.append(f"- **Người dùng:** {said(turn)}")
            text = turn["text"].strip().replace("\n", " ⏎ ")
            lines.append(f"  - **Milu:** {text}" if text else "  - **Milu:** *(trống)*")
            if turn.get("card"):
                lines.append(f"  - {seen_card(turn['card'])}")
            if turn.get("tools"):
                lines.append(f"  - Công cụ: {', '.join(turn['tools'])}")
            if turn.get("error"):
                lines.append(f"  - Lỗi: {turn['error']}")
            for problem in turn.get("problems", []):
                lines.append(f"  - ❌ {problem}")
        lines.append("")
    lines += [f"## Case đạt ({len(cases) - len(failed)})", "", "| ID | Tình huống | Milu trả lời (lượt cuối) |", "|---|---|---|"]
    for case in cases:
        if case["passed"]:
            last = case["turns"][-1]
            shown = seen_card(last.get("card")) or last["text"].strip().replace("\n", " ⏎ ")
            lines.append(f"| {case['id']} | {case['title']} | {shown[:160].replace('|', '/')} |")
    return "\n".join(lines) + "\n"


def main() -> None:
    data = json.loads((HERE / "cases.json").read_text(encoding="utf-8"))
    (HERE / "test-cases.md").write_text(test_cases(data) + "\n", encoding="utf-8")
    runs = [json.loads(Path(path).read_text(encoding="utf-8")) for path in sys.argv[1:]]
    if not runs:
        return
    merged = {}
    for run in runs:
        for case in run["cases"]:
            merged[case["id"]] = case
    order = {case["id"]: index for index, case in enumerate(data["cases"])}
    cases = sorted(merged.values(), key=lambda c: order.get(c["id"], 10_000))
    (HERE / "report.md").write_text(report(cases, data["groups"], runs[-1]["date"], len(runs)), encoding="utf-8")
    print(f"{sum(c['passed'] for c in cases)}/{len(cases)}")


if __name__ == "__main__":
    main()
