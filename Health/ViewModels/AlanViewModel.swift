import Foundation

@MainActor
final class AlanViewModel {

    @Injected private var networkService: NetworkService

    private(set) var errorMessage: String?

    private var clientID: String {
        AppConfiguration.clientID
    }

    var didReceiveResponseText: ((String) -> Void)?

    func sendQuestion(_ content: String) async {
        let endpoint = APIEndpoint.ask(content: content, clientID: clientID)

        do {
            let response = try await networkService.request(endpoint: endpoint, as: AlanQuestionResponse.self)
            didReceiveResponseText?(response.content)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // TODO: SSE Streaming 추가

    func resetAgentState() async {
        let endpoint = APIEndpoint.resetState(clientID: clientID)

        do {
            _ = try await networkService.request(endpoint: endpoint, as: AlanResetStateResponse.self)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
