//
//  PromptOption.swift
//  Health
//
//  Created by 김건우 on 8/15/25.
//

import Foundation

enum PromptOption {
    /// 자유 대화형 프롬프트
    case chat
    
    /// 일일 건강 데이터 요약
    case dailySummary
    
    /// 월간 건강 데이터 요약
    case monthlySummary
}

extension PromptOption: CustomStringConvertible {
    
    /// 요청 사항
    var description: String {
        switch self {
        case .chat:
            return """
                   위 데이터를 바탕으로, 아래 사용자의 질문에 대한 답을 해주세요. 
                   사용자가 건강과 연관되지 않은 질문을 한다면 공손하게 답을 할 수 없다고 해주세요.
                   """
        case .dailySummary:
            return """
                   위 데이터를 바탕으로 오늘 하루 건강 활동을 요약하고, 개선점과 조언을 제시해주세요. 
                   요청 시간이 새벽이거나 이른 아침이라면 데이터가 충분하지 않아 공손하게 요약을 할 수 없다고 해주세요. 
                   활동 및 건강 상태가 양호하다면 칭찬을 아끼지 말아주세요. 활동 및 건강 상태가 양호하지 않더라도 따듯한 격려의 말을 아끼지 말아주세요.
                   지난 한달 간 걸음 수 차트 데이터는 무시해주세요. 
                   출처는 표시하지 않고, 마크다운 문법과 개행 문자는 사용하지 마세요.
                   200자 이내로만 작성해주세요. 
                   """
        case .monthlySummary:
            return """
                   위 데이터를 바탕으로 지난 한 달간의 건강 활동을 요약하고, 개선점과 조언을 제시해주세요. 
                   요청 시간이 새벽이거나 이른 아침이라면 데이터가 충분하지 않아 공손하게 요약을 할 수 없다고 해주세요. 
                   활동 및 건강 상태가 양호하다면 칭찬을 아끼지 말아주세요. 활동 및 건강 상태가 양호하지 않더라도 따듯한 격려의 말을 아끼지 말아주세요.
                   출처는 표시하지 않고, 마크다운 문법과 개행 문자는 사용하지 마세요.
                   300자 이내로만 작성해주세요. 
                   """
        }
    }
}
