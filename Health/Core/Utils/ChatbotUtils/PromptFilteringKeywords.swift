//
//  PromptFilteringKeywords.swift
//  Health
//
//  Created by Seohyun Kim on 8/17/25.
//

import Foundation

/// 걷기 챗봇 프롬프트 필터링을 위한 도메인 키워드 정의
///
/// 사용자 입력에서 개인정보(주소) 마스킹 시 걷기 앱 특성에 맞는 키워드들을 제공합니다.
/// - 주소 끝나는 지점을 판별하는 키워드
/// - 사용자 질문이 시작되는 지점을 판별하는 키워드
/// - 걷기/의료/커뮤니티 등 도메인 특화 용어들
struct PromptFilteringKeywords {
	
	// MARK: - 주소 마스킹: 주소 끝나는 지점 판별
	struct AddressTermination {
		/// 일반적인 주소 마지막 키워드들
		static let general = [
			"동", "로", "길", "아파트", "빌딩", "타워", "호", "번지", "층",
			"단지", "마을", "테라스", "빌라", "오피스텔", "상가", "센터"
		]
		
		/// 걷기 관련 장소 키워드들
		static let walkingPlaces = [
			"공원", "강변", "해변", "산", "언덕", "둘레길", "산책로",
			"체육공원", "근린공원", "생태공원", "테마공원", "올림픽공원",
			"한강공원", "남산", "북한산", "관악산", "불암산"
		]
		
		/// 모든 주소 종료 키워드 (general + walkingPlaces)
		static let all = general + walkingPlaces
	}
	
	// MARK: - 프롬프트 시작: 사용자 질문 시작 지점 판별
	struct PromptIntention {
		/// 위치 관련 키워드
		static let location = [
			"근처", "쪽", "주변", "인근", "가까운", "부근", "에서", "으로", "로",
			"가서", "에", "안에", "내", "옆", "앞", "뒤", "사이"
		]
		
		/// 걷기/운동 활동 관련 키워드
		static let walkingActivities = [
			"걷기", "산책", "보행", "러닝", "조깅", "하이킹", "트레킹", "등산",
			"코스", "길", "로드", "산책로", "둘레길", "트레일", "워킹",
			"파워워킹", "노르딕워킹", "걸음", "걸어", "뛰기", "달리기"
		]
		
		/// 의료/건강 관련 키워드 (관절, 걷기 관련 질환)
		static let healthcare = [
			"병원", "의원", "클리닉", "재활", "치료", "진료", "검진", "상담",
			"관절", "무릎", "발목", "허리", "척추", "어깨", "손목", "팔꿈치",
			"골다공증", "관절염", "류마티스", "디스크", "인대", "연골",
			"물리치료", "도수치료", "운동치료", "재활의학과", "정형외과"
		]
		
		/// 정보 요청 키워드
		static let informationRequest = [
			"추천", "알려", "찾아", "소개", "안내", "정보", "어디", "뭐", "어떤",
			"좋은", "괜찮은", "유명한", "인기", "최고", "베스트", "맛집",
			"궁금", "문의", "질문", "도움", "설명", "검색"
		]
		
		/// 커뮤니티/이벤트 관련 키워드
		static let community = [
			"대회", "동호회", "모임", "운동", "클럽", "그룹", "팀", "멤버",
			"마라톤", "워크", "챌린지", "이벤트", "참가", "등록", "신청",
			"같이", "함께", "동반", "파트너", "친구", "사람"
		]
		
		/// 모든 프롬프트 의도 키워드
		static let all = location + walkingActivities + healthcare + informationRequest + community
	}
	
	// MARK: - 편의 접근 메서드
	/// 주소 종료 키워드들을 반환
	static func getAddressTerminationKeywords() -> [String] {
		return AddressTermination.all
	}
	
	/// 프롬프트 의도 키워드들을 반환
	static func getPromptIntentionKeywords() -> [String] {
		return PromptIntention.all
	}
	
	/// 특정 카테고리의 키워드만 반환
	static func getKeywords(for category: FilteringCategory) -> [String] {
		switch category {
		case .addressGeneral:
			return AddressTermination.general
		case .addressWalkingPlaces:
			return AddressTermination.walkingPlaces
		case .promptLocation:
			return PromptIntention.location
		case .promptWalkingActivities:
			return PromptIntention.walkingActivities
		case .promptHealthcare:
			return PromptIntention.healthcare
		case .promptInformationRequest:
			return PromptIntention.informationRequest
		case .promptCommunity:
			return PromptIntention.community
		}
	}
}

// MARK: - 필터링 카테고리 열거형
enum FilteringCategory {
	case addressGeneral
	case addressWalkingPlaces
	case promptLocation
	case promptWalkingActivities
	case promptHealthcare
	case promptInformationRequest
	case promptCommunity
}

// MARK: - 프롬프트 분석 유틸리티
extension PromptFilteringKeywords {
	/// 텍스트에서 첫 번째로 발견되는 키워드와 그 위치를 반환
	static func findFirstKeyword(in text: String, from keywords: [String]) -> (keyword: String, range: Range<String.Index>)? {
		var earliestRange: Range<String.Index>?
		var foundKeyword: String?
		
		for keyword in keywords {
			if let range = text.range(of: keyword) {
				if earliestRange == nil || range.lowerBound < earliestRange!.lowerBound {
					earliestRange = range
					foundKeyword = keyword
				}
			}
		}
		
		if let keyword = foundKeyword, let range = earliestRange {
			return (keyword: keyword, range: range)
		}
		
		return nil
	}
	
	/// 텍스트가 특정 카테고리의 키워드를 포함하는지 확인
	static func containsKeywords(in text: String, category: FilteringCategory) -> Bool {
		let keywords = getKeywords(for: category)
		return keywords.contains { text.contains($0) }
	}
	
	/// 프롬프트 의도 분석 (어떤 카테고리의 질문인지 판별)
	static func analyzePromptIntention(in text: String) -> [FilteringCategory] {
		var detectedCategories: [FilteringCategory] = []
		
		let intentionCategories: [FilteringCategory] = [
			.promptLocation, .promptWalkingActivities, .promptHealthcare,
			.promptInformationRequest, .promptCommunity
		]
		
		for category in intentionCategories {
			if containsKeywords(in: text, category: category) {
				detectedCategories.append(category)
			}
		}
		
		return detectedCategories
	}
}
