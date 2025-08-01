import Foundation

extension DIContainer {
    func registerNetworkService() {
        self.register(type: NetworkService.self, name: nil) { _ in
#if DEBUG
            return MockNetworkService()
#else
            return DefaultNetworkService()
#endif
        }
    }
}
