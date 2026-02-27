#if MLX
    import Foundation

    // MARK: - Download Progress

    /// Reports progress of a model download.
    public struct DownloadProgress: Sendable, Equatable {
        /// Fraction of the download completed, from 0.0 to 1.0.
        public var fractionCompleted: Double

        /// Number of bytes downloaded so far, if known.
        public var completedBytes: Int64?

        /// Total expected bytes, if known.
        public var totalBytes: Int64?

        /// Current download speed in bytes per second, if known.
        public var bytesPerSecond: Double?

        public init(
            fractionCompleted: Double,
            completedBytes: Int64? = nil,
            totalBytes: Int64? = nil,
            bytesPerSecond: Double? = nil
        ) {
            self.fractionCompleted = fractionCompleted
            self.completedBytes = completedBytes
            self.totalBytes = totalBytes
            self.bytesPerSecond = bytesPerSecond
        }
    }

    // MARK: - Download State

    /// The on-disk state of a downloadable model.
    public enum ModelDownloadState: Sendable, Equatable {
        /// The model files are not present on disk.
        case notDownloaded
        /// The model is currently being downloaded.
        case downloading(DownloadProgress)
        /// The model is fully downloaded and ready to load.
        case downloaded

        public static func == (lhs: ModelDownloadState, rhs: ModelDownloadState) -> Bool {
            switch (lhs, rhs) {
            case (.notDownloaded, .notDownloaded):
                return true
            case (.downloaded, .downloaded):
                return true
            case (.downloading(let a), .downloading(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    // MARK: - DownloadableLanguageModel Protocol

    /// A language model whose weights can be downloaded, inspected, and deleted.
    ///
    /// Backends that run locally (e.g. MLX) conform to this protocol to expose
    /// download management. API-only backends (OpenAI, Anthropic, etc.) do not
    /// need to conform — consumers can check conformance with:
    ///
    /// ```swift
    /// if let downloadable = model as? any DownloadableLanguageModel { ... }
    /// ```
    public protocol DownloadableLanguageModel: LanguageModel {
        /// Whether the model's files are fully present on disk.
        var isDownloaded: Bool { get }

        /// The current download state of this model.
        var downloadState: ModelDownloadState { get }

        /// Starts downloading the model and returns a stream of progress updates.
        ///
        /// If the model is already downloaded, the stream completes immediately.
        /// Cancelling the consuming `Task` cancels the download.
        func download() -> AsyncStream<DownloadProgress>

        /// Removes the downloaded model files from disk.
        ///
        /// Also cancels any in-flight download and removes the model from the
        /// in-memory cache.
        func deleteDownload() async throws

        /// The total size of the downloaded model on disk, in bytes.
        ///
        /// Returns `nil` if the model is not downloaded or the size cannot be determined.
        var downloadedSizeOnDisk: Int64? { get }
    }
#endif
