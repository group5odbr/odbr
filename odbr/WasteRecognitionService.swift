import UIKit

final class WasteRecognitionService {
    static let shared = WasteRecognitionService()

    private let markRecognizer = KoreanDisposalMarkRecognizer()
    private let multimodalInferencer = MultimodalDisposalInferencer()

    private init() {
    }

    func analyzeWithReport(_ image: UIImage) async -> AnalysisReport {
        let focusedImage = RecognitionImagePreprocessor.centeredSubject(from: image)
        async let ocrInspection = markRecognizer.inspect(in: focusedImage)
        async let multimodalInference = multimodalInferencer.infer(image: image)
        let (ocr, inference) = await (ocrInspection, multimodalInference)
        guard !Task.isCancelled else {
            return AnalysisReport(
                result: DisposalResult(
                    route: .unknown,
                    source: .localFallback,
                    confidence: 0,
                    evidences: [DisposalEvidence(title: "분석 취소", detail: "요청이 취소되었어요.")],
                    candidates: []
                ),
                ocr: ocr,
                aiModel: inference.inspection
            )
        }

        let result = DisposalDecisionEngine.result(
            multimodalDecision: inference.decision,
            localMark: ocr.signal,
            onlineFailureReason: inference.onlineFailureReason
        )

        return AnalysisReport(
            result: result,
            ocr: ocr,
            aiModel: inference.inspection
        )
    }

}

nonisolated private enum RecognitionImagePreprocessor {
    static func centeredSubject(from image: UIImage) -> UIImage {
        guard
            let cgImage = image.cgImage,
            cgImage.width > 0,
            cgImage.height > 0
        else {
            return image
        }

        let side = Int(Double(min(cgImage.width, cgImage.height)) * 0.90)
        guard side > 0 else {
            return image
        }

        let cropRect = CGRect(
            x: (cgImage.width - side) / 2,
            y: (cgImage.height - side) / 2,
            width: side,
            height: side
        ).integral

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return image
        }

        return UIImage(
            cgImage: cropped,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }
}
