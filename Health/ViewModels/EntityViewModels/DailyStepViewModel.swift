//
//  DailyStepViewModel.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//

import Foundation
import CoreData

final class DailyStepViewModel: ObservableObject {

    private let context: NSManagedObjectContext

    @Published var dailySteps: [DailyStepEntity] = []
    @Published var errorMessage: String?

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchAllDailySteps()
    }

    // 전체 DailyStepEntity 목록 불러오기
    func fetchAllDailySteps() {
        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyStepEntity.date, ascending: false)]

        do {
            dailySteps = try context.fetch(request)
        } catch {
            errorMessage = "Daily Steps 불러오기 실패: \(error.localizedDescription)"
        }
    }

    // 특정 id로 DailyStepEntity 가져오기
    func fetchDailyStep(by id: UUID) -> DailyStepEntity? {
        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            errorMessage = "특정 Daily Step 불러오기 실패: \(error.localizedDescription)"
            return nil
        }
    }

    func fetchDailyStep(_ date: Date) -> DailyStepEntity? {
        let normalizedDate = date.startOfDay()
        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", normalizedDate as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            errorMessage = "특정 날짜에 맞는 Daily Step 불러오기 실패: \(error.localizedDescription)"
            return nil
        }
    }

    // 새 DailyStepEntity 저장 또는 기존 업데이트
    func saveDailyStep(
        id: UUID? = nil,
        date: Date,
        stepCount: Int32,
        goalStepCount: Int32
    ) {
        let normalizedDate = date.startOfDay()

        let entity: DailyStepEntity
        if let id = id, let existing = fetchDailyStep(by: id) {
            entity = existing
        } else {
            entity = DailyStepEntity(context: context)
            entity.id = UUID()
        }

        entity.date = normalizedDate
        entity.stepCount = stepCount
        entity.goalStepCount = goalStepCount

        do {
            try context.save()
            fetchAllDailySteps()
        } catch {
            errorMessage = "Daily Step 저장 실패: \(error.localizedDescription)"
        }
    }

    /// 해당 날짜에 대응하는 DailyStep이 있으면 업데이트, 없으면 새로 생성합니다.
    ///
    /// - Parameters:
    ///   - date: 저장할 날짜 (가능하면 00:00 정규화 추천)
    ///   - stepCount: 해당 날짜의 걸음 수
    ///   - goalStepCount: 해당 날짜에 유효한 목표 걸음 수 스냅샷
    func upsertDailyStep(
        for date: Date = Date(),
        stepCount: Int? = nil,
        goalStepCount: Int? = nil
    ) {
        let normalizedDate = date.startOfDay()

        let request: NSFetchRequest<DailyStepEntity> = DailyStepEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", normalizedDate as CVarArg)
        request.fetchLimit = 1

        do {
            let existing = try context.fetch(request).first
            let entity = existing ?? DailyStepEntity(context: context)

            if existing == nil {
                entity.id = UUID()
                entity.date = normalizedDate
                entity.stepCount = Int32(stepCount ?? 0)
                entity.goalStepCount = Int32(goalStepCount ?? 0)
            } else {
                if let stepCount {
                    entity.stepCount = Int32(stepCount)
                }
                if let goalStepCount {
                    entity.goalStepCount = Int32(goalStepCount)
                }
            }

            try context.save()
            fetchAllDailySteps()
        } catch {
            errorMessage = "Daily Step upsert 실패: \(error.localizedDescription)"
        }
    }

    /// 마지막 저장 날짜 이후 오늘까지 누락된 날짜들을 반환합니다.
    ///
    /// - Parameter today: 오늘 날짜 (00:00으로 정규화된 값 권장)
    /// - Returns: 누락된 날짜 배열 (오름차순)
    func fetchMissingDates(until today: Date) -> [Date] {
        let normalizedToday = today.startOfDay()
        let savedDates = dailySteps.compactMap { $0.date?.startOfDay() }
        let lastSavedDate = savedDates.max() ?? Calendar.current.date(byAdding: .day, value: -7, to: today)!

        var dates: [Date] = []
        var current = Calendar.current.date(byAdding: .day, value: 1, to: lastSavedDate)!

        while current <= normalizedToday {
            dates.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }

        return dates
    }

    // 삭제
    func deleteDailyStep(_ dailyStep: DailyStepEntity) {
        context.delete(dailyStep)
        do {
            try context.save()
            fetchAllDailySteps()
        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
        }
    }
}
