import Foundation

struct AlanQuestionResponse: Decodable {
    let action: Action
    let content: String

    struct Action: Decodable {
        let name: String
        let speak: String
    }
}
