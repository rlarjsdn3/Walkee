//
//  UserInfoViewModel.swift
//  Health
//
//  Created by 권도현 on 8/6/25.
//

import Foundation
import CoreData

final class UserInfoViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var users: [UserInfoEntity] = []
    @Published var errorMessage: String?

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchUsers()
    }

    //전체 사용자 조회
    func fetchUsers() {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserInfoEntity.createdAt, ascending: false)]

        do {
            users = try context.fetch(request)
        } catch {
            errorMessage = "사용자 불러오기 실패: \(error.localizedDescription)"
        }
    }

    //특정 사용자 조회 by id
    func fetchUser(by id: UUID) -> UserInfoEntity? {
        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            errorMessage = "사용자 조회 실패: \(error.localizedDescription)"
            return nil
        }
    }

    //사용자 추가 또는 업데이트
    func saveUser(id: UUID? = nil,
                  username: String,
                  age: Int16,
                  gender: String,
                  height: Double,
                  weight: Double,
                  diseases: [Disease]?,
                  createdAt: Date = Date()) {
        let user: UserInfoEntity
        if let id = id, let existing = fetchUser(by: id) {
            user = existing
        } else {
            user = UserInfoEntity(context: context)
            user.id = UUID()
            user.createdAt = createdAt
        }

        user.username = username
        user.age = age
        user.gender = gender
        user.height = height
        user.weight = weight
        user.diseases = diseases

        do {
            try context.save()
            fetchUsers()
        } catch {
            errorMessage = "사용자 저장 실패: \(error.localizedDescription)"
        }
    }

    // 삭제
    func deleteUser(_ user: UserInfoEntity) {
        context.delete(user)
        do {
            try context.save()
            fetchUsers()
        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
        }
    }

    //dailyStep 추가
    func addDailyStep(to user: UserInfoEntity, dailyStep: DailyStepEntity) {
        user.addToDailyStep(dailyStep)
        saveContext()
        fetchUsers()
    }

    //goalStepCount 추가
    func addGoalStepCount(to user: UserInfoEntity, goalStepCount: GoalStepCountEntity) {
        user.addToGoalStepCount(goalStepCount)
        saveContext()
        fetchUsers()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            errorMessage = "저장 실패: \(error.localizedDescription)"
        }
    }
}
