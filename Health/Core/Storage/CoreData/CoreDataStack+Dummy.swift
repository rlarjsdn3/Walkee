//
//  CoreDataStack+Dummy.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import Foundation
import CoreData

extension CoreDataStack {
    
    /// 디버그 환경에서만 더미 데이터를 Core Data에 삽입합니다.
    ///
    /// 이 메서드는 테스트 및 UI 미리보기용 데이터를 생성할 때 활용됩니다.
    /// 실제 운영 환경에서는 실행되지 않도록 `#if DEBUG` 조건으로 보호되어 있습니다.
    func insertDummyData() {
#if DEBUG
        let context = viewContext
        
        // 이미 데이터가 있으면 중복 삽입 방지
        let fetchRequest: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        if let existingUsers = try? context.fetch(fetchRequest), !existingUsers.isEmpty {
            print("더미 데이터가 이미 존재합니다. 삽입을 건너뜁니다.")
            return
        }
        
        //UserInfoEntity 더미 생성
        
        
        let dummyUser = UserInfoEntity(context: context)
        dummyUser.id = UUID()
        dummyUser.createdAt = Date()
        dummyUser.gender = "남성"
        
        /*
        dummyUser.age = 25
        dummyUser.height = 175.0
        dummyUser.weight = 68.0
        dummyUser.diseases = [.arthritis, .stroke]
         */
     
        
        //GoalStepCountEntity 더미 생성 및 연결
        let dummyGoal = GoalStepCountEntity(context: context)
        dummyGoal.id = UUID()
        dummyGoal.goalStepCount = 10000
        dummyGoal.effectiveDate = Date()
        dummyUser.addToGoalStepCount(dummyGoal)
        
        //DailyStepEntity 7일치 생성 및 연결
        let calendar = Calendar.current
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let normalizedDate = calendar.startOfDay(for: date)
            
            let dailyStep = DailyStepEntity(context: context)
            dailyStep.id = UUID()
            dailyStep.date = normalizedDate
            dailyStep.stepCount = Int32.random(in: 3000...15000)
            dailyStep.goalStepCount = dummyGoal.goalStepCount
            dummyUser.addToDailyStep(dailyStep)
        }


        // 4. 저장
        do {
            try context.save()
            print("더미 데이터 삽입 성공")
        } catch {
            print("더미 데이터 삽입 중 오류 발생: \(error.localizedDescription)")
        }
#endif
    }
    
}
