import Foundation

struct AlanStreamingResponse: Decodable {
    let type: StreamingType
    let data: StreamingData

    enum StreamingType: String, Decodable {
    case `continue`
    case complete
    }

    struct StreamingData: Decodable {
        let content: String
    }
}
