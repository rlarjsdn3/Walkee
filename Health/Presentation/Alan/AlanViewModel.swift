import Foundation

@MainActor
final class AlanViewModel {

    @Injected private var networkService: NetworkService

    private(set) var responseText: String = ""
    private(set) var errorMessage: String?

    private var clientID: String {
        AppConfiguration.clientID
    }

    func sendQuestion(_ content: String) async {
        let endpoint = APIEndpoint.ask(content: content, clientID: clientID)

        do {
            let response = try await networkService.request(endpoint: endpoint, as: AlanQuestionResponse.self)
            responseText = response.content
            errorMessage = nil
        } catch {
            responseText = ""
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
