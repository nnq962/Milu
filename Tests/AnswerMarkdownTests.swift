import Testing
@testable import Milu

/// Milu's answers in the chat's one layout, whatever list marks the model wrote (user report
/// 2026-11-12: a "*" showed beside a "•").
struct AnswerMarkdownTests {
    @Test func starAndDashItemsBecomeBullets() {
        let text = "Tháng này bạn chi **980.000đ**.\n\n* Gần một củ rồi.\n- Thử lên list nha."
        #expect(AnswerMarkdown.normalized(text) == "Tháng này bạn chi **980.000đ**.\n\n• Gần một củ rồi.\n• Thử lên list nha.")
    }

    @Test func doubledMarksBecomeOneBullet() {
        #expect(AnswerMarkdown.normalized("• * Ăn uống: **1tr**") == "• Ăn uống: **1tr**")
    }

    @Test func boldOrItalicAtALineStartIsNotAnItem() {
        #expect(AnswerMarkdown.normalized("**Tổng:** 1tr") == "**Tổng:** 1tr")
        #expect(AnswerMarkdown.normalized("*nhẹ thôi*") == "*nhẹ thôi*")
    }

    @Test func aNegativeSumIsNotAnItem() {
        #expect(AnswerMarkdown.normalized("-6.430.000đ") == "-6.430.000đ")
    }

    @Test func indentedItemsBecomeSubBullets() {
        #expect(AnswerMarkdown.normalized("• Tài khoản:\n  * MoMo: 45k") == "• Tài khoản:\n    ◦ MoMo: 45k")
    }

    @Test func headingsBecomeBoldAndRulesGo() {
        #expect(AnswerMarkdown.normalized("## Chi tiêu\n---\nỔn áp") == "**Chi tiêu**\nỔn áp")
    }

    @Test func blankLinesAreTrimmed() {
        let text = "\n\nCâu chính.\n\n\n\n• Một\n\n• Hai\n\n"
        #expect(AnswerMarkdown.normalized(text) == "Câu chính.\n\n• Một\n• Hai")
    }
}
