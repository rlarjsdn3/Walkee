//
//  AlanStreamingResponse.swift
//  Health
//
//  SSE 스트림 이벤트 모델
//

import Foundation

/// Alan SSE(response) 이벤트 모델
///
/// Alan API: `/api/v1/question/sse-streaming`
///
/// 이벤트는 다음 형식으로 전송됩니다:
/// ```text
/// event: response
/// data: {"type":"continue","data":{"content":"..."}} // 반복
/// data: {"type":"complete","data":{"content":""}}  ^[490]^  // 각주처럼 달림. 매번 그런 것은 아님.종료 신호
/// ```
///
/// - Note: `type == .continue`일 때 `data.content`를 누적 표시합니다.
/// - Note: `type == .complete`를 수신하면 스트림을 종료합니다.
/// - SeeAlso: `AlanSSEClient` – SSE 연결/파싱 유틸
struct AlanStreamingResponse: Decodable {
	enum StreamingType: String, Decodable {
		case action       // 응답 기다릴 때 생성되는 ai 검색 및 결과 관련 텍스트
		case `continue`   // 조각 단어들 `계속` 내려옴
		case complete     // 완성 문장 마지막에 내려옴
	}

	struct StreamingData: Decodable {
		let content: String?
		let speak: String?    
	}

	let type: StreamingType
	let data: StreamingData
}
