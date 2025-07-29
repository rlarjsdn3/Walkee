//
//  CoreDataStack.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import CoreData
import Foundation

/// `CoreDataStack`은 Core Data의 기본 구성을 담당하는 클래스입니다.
///
/// 앱 전반에서 공유되는 `NSPersistentContainer`와 `NSManagedObjectContext`를 관리하며,
/// 데이터를 저장하거나 불러올 때의 핵심 역할을 수행합니다.
@MainActor
final class CoreDataStack {

    /// `CoreDataStack`의 전역 공유 인스턴스입니다.
    /// 싱글톤 패턴을 통해 앱 어디에서나 동일한 Core Data 구성을 사용할 수 있습니다.
    static let shared = CoreDataStack()
    private init() { }

    /// 메인 쓰레드에서 사용되는 기본 컨텍스트입니다.
    ///
    /// UI와 직접 연결되는 작업에서 사용되며,
    /// 내부적으로 `NSPersistentContainer.viewContext`를 반환합니다.
    var viewContext: NSManagedObjectContext {
        persistentCotnainer.viewContext
    }

    /// Core Data 저장소를 관리하는 `NSPersistentContainer`입니다.
    ///
    /// - `Model`이라는 이름의 데이터 모델 파일을 기반으로 초기화됩니다.
    /// - 디버그 환경에서는 영구 저장을 방지하기 위해 `/dev/null`로 저장소 경로를 지정합니다.
    /// - 저장소 로딩에 실패할 경우 앱을 종료하며 오류 메시지를 출력합니다.
    lazy var persistentCotnainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
#if DEBUG
        container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
#endif
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()

    /// 현재 컨텍스트의 변경사항을 저장합니다.
    ///
    /// 저장 중 오류가 발생할 경우 앱을 종료하며 오류 메시지를 출력합니다.
    func saveContext() {
        do {
            try viewContext.save()
        } catch {
            fatalError("Failed to save context: \(error.localizedDescription)")
        }
    }
}

extension CoreDataStack {
    
    /// 지정된 조건과 정렬 기준에 따라 Core Data에서 엔티티를 조회합니다.
    ///
    /// - Parameters:
    ///   - predicate: 선택적으로 조건을 지정할 수 있는 `NSPredicate`입니다. 기본값은 `nil`입니다.
    ///   - sortDescriptors: 정렬 조건을 지정하는 배열입니다. 기본값은 `nil`입니다.
    /// - Returns: 조건에 부합하는 `Entity` 객체들의 배열을 반환합니다.
    /// - Throws: 페치 요청 실행 중 오류가 발생할 경우 예외를 던집니다.
    func fetch<Entity>(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) throws -> [Entity] where Entity: NSFetchRequestResult {
        let request = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return try viewContext.fetch(request)
    }
    
    /// 새로운 `NSManagedObject` 엔티티를 컨텍스트에 추가합니다.
    ///
    /// 컨텍스트에 추가한 후, 자동으로 `saveContext()`를 호출하여 변경사항을 저장합니다.
    ///
    /// - Parameter entity: 삽입할 엔티티 객체입니다.
    /// - Throws: 저장 도중 오류가 발생할 수 있으므로 `throws`로 선언되어 있습니다.
    func insert<Entity>(_ entity: Entity) throws where Entity: NSManagedObject {
        defer { saveContext() }
        viewContext.insert(entity)
    }
    
    /// 지정된 `NSManagedObject` 엔티티를 컨텍스트에서 삭제합니다.
    ///
    /// 삭제한 후, 자동으로 `saveContext()`를 호출하여 변경사항을 저장합니다.
    ///
    /// - Parameter entity: 삭제할 엔티티 객체입니다.
    /// - Throws: 저장 도중 오류가 발생할 수 있으므로 `throws`로 선언되어 있습니다.
    func delete<Entity>(_ entity: Entity) throws where Entity: NSManagedObject {
        defer { saveContext() }
        viewContext.delete(entity)
    }
    
    /// 백그라운드 컨텍스트에서 비동기 작업을 실행합니다.
    ///
    /// 이 메서드는 `NSPersistentContainer`의 `performBackgroundTask`를 활용하여,
    /// 데이터 작업이 UI 쓰레드에 영향을 주지 않도록 비동기 처리합니다.
    ///
    /// - Parameter block: 백그라운드 컨텍스트에서 수행할 작업 블록입니다.
    /// - Throws: 작업 블록 내에서 오류가 발생할 경우 예외를 던질 수 있습니다.
     func performBackgroundTask(_ block: @Sendable @escaping (NSManagedObjectContext) throws -> Void) async rethrows {
        try await persistentCotnainer.performBackgroundTask(block)
    }
}
