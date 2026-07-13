import SwiftUI

struct AppInformationView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("odbr.aiImageAnalysisConsent.v1") private var hasImageAnalysisConsent = false

    var body: some View {
        NavigationStack {
            List {
                Section("AI 사진 분석") {
                    Text("사진 속 물건은 Google Gemini가 분석해요. 사진 전송과 안전한 연결에는 Google Firebase AI Logic과 App Check를 사용해요.")
                    Toggle("사진 분석 동의", isOn: $hasImageAnalysisConsent)
                }

                Section("분리배출 안내") {
                    LabeledContent("안내 버전", value: "\(DisposalPolicyCatalog.version)")
                    LabeledContent("마지막 확인일", value: DisposalPolicyCatalog.reviewedAt)
                    Link("공식 생활폐기물 안내", destination: DisposalPolicyCatalog.sourceURL)
                }

                Section("앱 정보") {
                    LabeledContent("앱 이름", value: "오디버려")
                    LabeledContent("버전", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                    Text("문의와 개인정보처리방침은 출시 전 등록된 공식 안내를 확인해 주세요.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .navigationTitle("설정 및 정보")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AppInformationView()
}
