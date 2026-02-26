import Foundation

public protocol LanguageModel: Sendable {
    associatedtype UnavailableReason

    /// The type of custom generation options this model accepts.
    ///
    /// Models can define their own custom options types with extended properties
    /// by setting this to a custom type conforming to ``CustomGenerationOptions``.
    /// The default is `Never`, indicating no custom options are supported.
    associatedtype CustomGenerationOptions: AnyLanguageModel.CustomGenerationOptions = Never

    var availability: Availability<UnavailableReason> { get }

    func prewarm(
        for session: LanguageModelSession,
        promptPrefix: Prompt?,
        tools: [any Tool]?
    )

    func respond<Content>(
        within session: LanguageModelSession,
        to prompt: Prompt,
        generating type: Content.Type,
        includeSchemaInPrompt: Bool,
        options: GenerationOptions
    ) async throws -> LanguageModelSession.Response<Content> where Content: Generable

    func streamResponse<Content>(
        within session: LanguageModelSession,
        to prompt: Prompt,
        generating type: Content.Type,
        includeSchemaInPrompt: Bool,
        options: GenerationOptions
    ) -> sending LanguageModelSession.ResponseStream<Content> where Content: Generable

    func logFeedbackAttachment(
        within session: LanguageModelSession,
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue],
        desiredOutput: Transcript.Entry?
    ) -> Data

    /// Invalidates any cached state associated with the given session.
    ///
    /// Called when a session's transcript is replaced. Models that maintain
    /// per-session caches (such as MLX KV caches) should evict the entry
    /// for the given session. The default implementation does nothing.
    func invalidateCache(for session: LanguageModelSession)
}

// MARK: - Default Implementation

extension LanguageModel {
    public var isAvailable: Bool {
        if case .available = availability {
            return true
        } else {
            return false
        }
    }

    public func prewarm(
        for session: LanguageModelSession,
        promptPrefix: Prompt? = nil,
        tools: [any Tool]? = nil
    ) {
        return
    }

    public func logFeedbackAttachment(
        within session: LanguageModelSession,
        sentiment: LanguageModelFeedback.Sentiment? = nil,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredOutput: Transcript.Entry? = nil
    ) -> Data {
        return Data()
    }

    public func invalidateCache(for session: LanguageModelSession) {}
}

extension LanguageModel where UnavailableReason == Never {
    public var availability: Availability<UnavailableReason> {
        return .available
    }
}
