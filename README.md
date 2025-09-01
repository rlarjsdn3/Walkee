<div align="center">

# Walkee

<img width="150" alt="appIcon_light" src="https://github.com/user-attachments/assets/bddadda1-3e0b-4afd-9e5f-b93d2c30988c" />

<br />
<br />

**Walkee**는 HealthKit과 연동된 걷기 데이터를 기반으로<br />
Alan AI가 개인 맞춤형 활동 및 걷기 코스를 추천하는 헬스케어 앱입니다.

</div>

<br />

## 📌 프로젝트 개요
- **HealthKit** 기반 걷기 데이터 수집 및 분석
- **Alan AI**를 통한 맞춤형 활동/걷기 추천
- **Core Data** 기반 데이터 저장 및 WidgetKit 스냅샷 연동
- **사용자 프로필·위치** 기반 걷기 코스 추천

<br />

## ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| 📊 차트 시각화 | 주간·월간 그래프 및 목표 대비 변화율 |
| 📅 캘린더 기반 UI | 날짜별 걸음 수, 목표치, 진행률 표시 |
| 🗺 걷기 코스 추천 | 공공데이터·신체 정보 기반 AI 코스 추천 |
| 🤖 개인 맞춤 분석 | 개인 프로필(성별·체형·지병) 기반 AI 분석 |
| 📱 위젯 | 오늘 걸음 수, 거리, 칼로리, 주간 평균 표시 |

<br />

## 🏗 아키텍처
- **DIContainer** 기반 의존성 주입  
- **MVVM + Service Layer** 구조  
- **Swift Concurrency (async/await)** 기반 비동기 처리  
- **App Group(UserDefaults) + WidgetKit** 연계  

<br />

## 🏛 프로젝트 계층 구조

| 계층 | 주요 역할 | 예시 파일 |
|------|----------|-----------|
| **Application** | 앱 실행/환경설정 | `AppDelegate`, `SceneDelegate`, `AppConfiguration` |
| **Core** | 공통 유틸/보안/DI | `DIContainer`, `CoreDataStack`, `KeychainWrapper` |
| **Model** | 데이터 모델 | `UserInfoEntity`, `DailyStepEntity`, `AlanStreamingResponse`, `WalkingCourse` |
| **Presentation** | UI 화면/컴포넌트 | Calendar, Dashboard, Chatbot, Onboarding, Profile |
| **Services** | 데이터 서비스 계층 | `HealthService`, `CalendarStepService`, `WalkingCourseService`, `StepSyncService` |
| **ViewModels** | UI와 서비스 계층을 연결, 데이터 상태 관리 | `CalendarViewModel`, `DashboardViewModel`, `UserInfoViewModel`, `AlanViewModel` |

<br />

## 🗂 데이터 플로우
1. **HealthKit** ➡️ `DefaultHealthService` ➡️ CoreData  
2. **CoreDataStack** ➡️ `CalendarStepService` / `DashboardSnapshotStore`  
3. **Alan AI** SSE ➡️ `AlanStreamingResponse` 파싱 ➡️ UI 반영  
4. **LocationPermissionService** ➡️ `WalkingCourseService` ➡️ 지도 썸네일 생성  
5. **SharedStore(AppGroup)** ➡️ WidgetKit ➡️ 홈화면 위젯 갱신

<br />

## 📊 주요 데이터 모델

| 모델 | 설명 |
|------|------|
| **UserInfoEntity** | 사용자 프로필 (성별, 나이, 키, 몸무게, 질병) |
| **DailyStepEntity** | 날짜별 걸음 수 기록 |
| **GoalStepCountEntity** | 목표 걸음 수 기록 |
| **HealthDashboardSnapshot** | 위젯/대시보드용 통합 데이터 |
| **WalkingCourse** | 공공데이터 기반 걷기 코스 |

<br />

## 🧪 테스트

| 테스트 대상 | 방식 |
|-------------|------|
| CoreDataUserService | 더미 데이터 기반 단위 테스트 |
| DIContainer | 의존성 주입 검증 |
| HealthService | MockHealthService 활용 |
| ViewModels | `CalendarViewModelTests` (캘린더 데이터 검증), `LLMRecommendationViewModelTests` (AI 추천 로직 검증) 등 |

<br />

## 📸 주요 화면

<table width="100%">
  <tr>
    <td align="center" width="16.6%">👋 <strong>온보딩</strong></td>
    <td align="center" width="16.6%">📊 <strong>대시보드 탭</strong></td>
    <td align="center" width="16.6%">📅 <strong>캘린더 탭</strong></td>
    <td align="center" width="16.6%">💡 <strong>맞춤케어 탭</strong></td>
    <td align="center" width="16.6%">🤖 <strong>Alan AI 챗봇</strong></td>
    <td align="center" width="16.6%">👤 <strong>프로필 탭</strong></td>
  </tr>
  <tr>
    <td align="center" width="16.6%">
      <img width="1179" height="2556" alt="onboarding.png" src="https://github.com/user-attachments/assets/dedd685b-6c9e-40ad-b90f-0922ddd801a6" />
    </td>
    <td align="center" width="16.6%">
      <img width="1179" height="2556" alt="dashboard.png" src="https://github.com/user-attachments/assets/0f318d75-17ad-4afe-a591-f4118ddaa35d" />
    </td>
    <td align="center" width="16.6%">
      <img width="1179" height="2556" alt="calendar.png" src="https://github.com/user-attachments/assets/245ad033-323f-468a-8e1a-c402b4b2827d" />
    </td>
    <td align="center" width="16.6%">
      <img width="1179" height="2556" alt="personal.png" src="https://github.com/user-attachments/assets/9758cc66-ec21-44d7-81fc-87b10904ecd2" />  
    </td>
    <td align="center" width="16.6%">
      <img width="1179" height="2556" alt="chatbot.png" src="https://github.com/user-attachments/assets/4543a9f5-96be-4bef-8f90-6e0a59015f06" />
    </td>
    <td align="center" width="16.6%">
      <img width="1179" height="2556" alt="profile.png" src="https://github.com/user-attachments/assets/6cc4814f-a5cc-4126-aace-99b69919466a" />  
    </td>
  </tr>
  <tr>
    <td align="center" width="16.6%">
      <span>• 접근 권한 설정</span><br />
      <span>• 프로필 입력</span><br />
    </td>
    <td align="center" width="16.6%">
      <span>• 걸음 수·칼로리</span><br />
      <span>• AI 요약 리포트</span><br />
    </td>
    <td align="center" width="16.6%">
      <span>• 목표 달성률</span><br />
      <span>• 일별 대시보드</span><br />
    </td>
    <td align="center" width="16.6%">
      <span>• 월간 기록·AI 요약</span><br />
      <span>• 추천 걷기 코스</span><br />
    </td>
    <td align="center" width="16.6%">
      <span>• 걷기 코스 제안</span><br />
      <span>• 대화형 분석</span><br />
      </td>
    <td align="center" width="16.6%">
      <span>• 프로필 설정</span><br>
      <span>• 개발자 문의</span><br>
      </td>
  </tr>
</table>

<br />

## 👨‍💻 팀원

<table width="100%">
  <tr>
    <td align="center" width="16.6%"><strong>팀장</strong></td>
    <td align="center" width="16.6%"><strong>부팀장</strong></td>
    <td align="center" width="16.6%"><strong>팀원</strong></td>
    <td align="center" width="16.6%"><strong>팀원</strong></td>
    <td align="center" width="16.6%"><strong>팀원</strong></td>
    <td align="center" width="16.6%"><strong>팀원</strong></td>
  </tr>
  <tr>
    <!-- 김건우 -->
    <td align="center" width="16.6%">
      <a href="https://github.com/rlarjsdn3">
        <img width="150" alt="image" src="https://github.com/user-attachments/assets/80e43131-646e-4f72-aa3a-91c5a8da16c6" />
      </a><br>
      <strong>김건우</strong><br>
      <a href="https://github.com/rlarjsdn3">
        <span>rlarjsdn3</span>
      </a>
    </td>
    <!-- 김서현 -->
    <td align="center" width="16.6%">
      <a href="https://github.com/cestbonciel">
        <img width="150" alt="image" src="https://github.com/user-attachments/assets/835064d2-a742-4c41-8a82-7590ecf67fcb" />
      </a><br>
      <strong>김서현</strong><br>
      <a href="https://github.com/cestbonciel">
        <span>cestbonciel</span>
      </a>
    </td>
    <!-- 권도현 -->
    <td align="center" width="16.6%">
      <a href="https://github.com/kwondohyun12">
        <img width="150" alt="image" src="https://github.com/user-attachments/assets/fc90757b-e604-4d04-a40f-4db0ece88c4a" />
      </a><br>
      <strong>권도현</strong><br>
      <a href="https://github.com/kwondohyun12">
        <span>kwondohyun12</span>
      </a>
    </td>
    <!-- 김종성 -->
    <td align="center" width="16.6%">
      <a href="https://github.com/jseongee">
        <img width="150" alt="image" src="https://github.com/user-attachments/assets/0b1c41c9-108b-4558-8bed-d0d1ab1eea54" />
      </a><br>
      <strong>김종성</strong><br>
      <a href="https://github.com/jseongee">
        <span>jseongee</span>
      </a>
    </td>
    <!-- 노기승 -->
    <td align="center" width="16.6%">
      <a href="https://github.com/giseungNoh">
        <img width="150" alt="image" src="https://github.com/user-attachments/assets/cd0d0c09-e4fe-41b7-a2c5-6e4815a2eb24" />
      </a><br>
      <strong>노기승</strong><br>
      <a href="https://github.com/giseungNoh">
        <span>giseungNoh</span>
      </a>
    </td>
    <!-- 하재준 -->
    <td align="center" width="16.6%">
      <a href="https://github.com/haejaejoon">
        <img width="150" alt="image" src="https://github.com/user-attachments/assets/54138042-d621-4e5a-a4b6-12a814cb0f82" />
      </a><br>
      <strong>하재준</strong><br>
      <a href="https://github.com/haejaejoon">
        <span>haejaejoon</span>
      </a>
    </td>
  </tr>
  <tr>
    <td align="center" width="16.6%">대시보드 탭</td>
    <td align="center" width="16.6%">Alan AI 챗봇</td>
    <td align="center" width="16.6%">온보딩</td>
    <td align="center" width="16.6%">캘린더 탭</td>
    <td align="center" width="16.6%">맞춤케어 탭</td>
    <td align="center" width="16.6%">프로필 탭</td>
  </tr>
</table>
