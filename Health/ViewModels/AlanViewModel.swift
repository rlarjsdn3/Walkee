import Foundation

@MainActor
final class AlanViewModel {
	
	@Injected private var networkService: NetworkService

	private(set) var errorMessage: String?
	
	private var clientID: String {
		AppConfiguration.clientID
	}
	
	var didReceiveResponseText: ((String) -> Void)?
	
	// MARK: - 일반 질문 형식 APIEndpoint
	func sendQuestion(_ content: String) async -> String? {
		let endpoint = APIEndpoint.ask(content: content, clientID: clientID)
		
		do {
			let response = try await networkService.request(endpoint: endpoint, as: AlanQuestionResponse.self)
			didReceiveResponseText?(response.content)
			errorMessage = nil
			return response.content
		} catch {
			errorMessage = error.localizedDescription
			return nil
		}
	}
	
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

extension AlanViewModel {
	func buildStreamingURL(content: String, clientID: String) throws -> URL {
		let endpoint = APIEndpoint.askStreaming(content: content, clientID: clientID)
		var comps = URLComponents(url: endpoint.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
		comps?.queryItems = endpoint.queryItems
		guard let url = comps?.url else { throw NetworkError.badURL }
		return url
	}
}
