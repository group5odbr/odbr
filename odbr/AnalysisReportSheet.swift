import SwiftUI

struct AnalysisReportSheet: View {
    let report: AnalysisReport

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    ReportSection(title: "최종 판정") {
                        ReportRow(title: "분류", detail: report.result.title)
                        ReportRow(title: "판정 방식", detail: report.result.source.title)
                        ReportRow(title: "신뢰도", detail: confidenceText)

                        if !report.result.candidates.isEmpty {
                            ReportRow(title: "다른 후보", detail: candidateText)
                        }

                        ForEach(report.result.evidences) { evidence in
                            ReportRow(title: evidence.title, detail: evidence.detail)
                        }
                    }

                    DisclosureGroup("기술 상세") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                            ReportSection(title: "Gemini 이미지 판정") {
                                ReportRow(title: "상태", detail: report.aiModel.status)
                                ReportRow(title: "상세", detail: report.aiModel.detail)
                            }

                            ReportSection(title: "기기 내 표기 인식") {
                                if let failureReason = report.ocr.failureReason {
                                    ReportRow(title: "OCR 상태", detail: failureReason)
                                }
                                ReportRow(title: "마크 판정", detail: signalDetail)
                                ReportRow(title: "인식 텍스트", detail: ocrText)
                            }
                        }
                    }
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .tint(AppTheme.deepGreen)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("분석 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var confidenceText: String {
        report.result.isUncertain ? "판정 보류" : "\(report.result.confidence)%"
    }

    private var candidateText: String {
        report.result.candidates.map(\.title).joined(separator: ", ")
    }

    private var ocrText: String {
        let text = report.ocr.textLines.joined(separator: ", ")
        return text.isEmpty ? "인식된 텍스트 없음" : text
    }

    private var signalDetail: String {
        guard let signal = report.ocr.signal else {
            return "확정 가능한 표기 없음"
        }

        return "\(signal.category.title) · \(signal.confidence)% · \(signal.evidence.detail)"
    }
}

private struct ReportSection<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                content
            }
        }
        .utilityCard()
    }
}

private struct ReportRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            Text(detail)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
