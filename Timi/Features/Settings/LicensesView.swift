import SwiftUI

/// Giấy phép mã nguồn mở: the notice each bundled third-party work asks to ship with the app,
/// read from the text files in Resources.
struct LicensesView: View {
    private struct Work: Identifiable {
        let name: String
        let use: String
        let file: String
        var id: String { file }

        var text: String {
            guard let url = Bundle.main.url(forResource: file, withExtension: "txt"),
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
            return Self.reflowed(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        /// The files wrap lines at about 80 characters; on a phone that leaves ragged lines, so a
        /// long line that does not end a sentence is joined to the next one.
        private static func reflowed(_ text: String) -> String {
            let lines = text.components(separatedBy: "\n")
            var result = ""
            for (index, line) in lines.enumerated() {
                result += line
                guard index < lines.count - 1 else { break }
                let next = lines[index + 1]
                let wrapped = line.count >= 60 && !next.isEmpty && !".:".contains(line.last ?? ".")
                result += wrapped ? " " : "\n"
            }
            return result
        }
    }

    private let works = [
        Work(name: "Hugeicons", use: "Biểu tượng · MIT", file: "Hugeicons-LICENSE"),
        Work(name: "Manrope", use: "Phông chữ · SIL Open Font License 1.1", file: "OFL"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                ForEach(works) { work in
                    FormGroup(title: work.name, footer: work.use) {
                        Text(work.text)
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(RowMetrics.horizontal)
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Giấy phép mã nguồn mở")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { LicensesView() }
}
