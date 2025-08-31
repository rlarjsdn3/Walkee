//
//  WalkingCourseService.swift
//  Health
//
//  Created by juks86 on 8/9/25.
//

import UIKit
import MapKit

/// 추천 걷기 코스 데이터를 관리하고 지도 썸네일을 생성하는 서비스 클래스
///
/// 이 클래스는 로컬 JSON 파일에서 산책 코스를 로드하고, GPX 파일을 다운로드하여
/// 지도 썸네일을 생성하는 기능을 제공합니다. 성능 최적화를 위해 다양한 캐시 메커니즘을 사용합니다.

class WalkingCourseService {
    @MainActor static let shared = WalkingCourseService()

    //썸네일 캐시
    private var thumbnailCache = NSCache<NSString, UIImage>()
    //좌표 캐시
    private var coordinatesCache = NSCache<NSString, NSArray>()
    //코스 데이터 캐시(한 번 로드하면 계속 사용)
    private var coursesCache: [WalkingCourse]?

    private init() {}

    /// 로컬 JSON 파일에서 산책 코스 데이터를 불러옵니다.
    ///
    /// - Returns: 추천 걷기 코스 배열. 파일이 없거나 파싱에 실패하면 빈 배열
    ///
    /// ## 동작 방식
    /// 1. 캐시된 데이터가 있으면 즉시 반환 (성능 최적화)
    /// 2. Bundle에서 `walkingCourse.json` 파일 찾기
    /// 3. JSON 파일을 읽어서 `WalkingCourse` 구조체 배열로 변환
    /// 4. 결과를 캐시에 저장하고 반환
    func loadWalkingCourses() -> [WalkingCourse] {

        if let cachedCourses = coursesCache {
            return cachedCourses
        }

        // 1. Bundle에서 JSON 파일 경로 찾기
        guard let path = Bundle.main.path(forResource: "walkingCourse", ofType: "json") else {
            return []
        }

        // 2. 파일 경로를 URL로 변환
        let url = URL(fileURLWithPath: path)

        do {
            // 3. JSON 파일 읽기
            let data = try Data(contentsOf: url)

            // 4. JSON 데이터를 구조체로 변환
            let decoder = JSONDecoder()
            let localCourses = try decoder.decode(LocalWalkingCourse.self, from: data)

            // 5. 캐시에 저장하고 반환
            coursesCache = localCourses.courses
            return localCourses.courses

        } catch {
            return []
        }
    }

    /// GPX URL에서 좌표 데이터를 가져오거나 다운로드합니다.
    ///
    /// - Parameter gpxURL: GPX 파일의 URL 문자열
    /// - Returns: 좌표 배열
    ///
    /// ## 캐시 메커니즘
    /// 1. 캐시에 좌표가 있으면 즉시 반환
    /// 2. 캐시에 없으면 GPX 파일을 다운로드
    /// 3. 파싱한 좌표를 캐시에 저장하고 반환
    private func getOrDownloadCoordinates(from gpxURL: String) async -> [CLLocationCoordinate2D] {
        // 좌표 캐시 확인
        if let cachedCoordinates = coordinatesCache.object(forKey: gpxURL as NSString) {
            return cachedCoordinates as! [CLLocationCoordinate2D]
        }

        // 캐시에 없으면 다운로드
        guard let url = URL(string: gpxURL) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let coordinates = parseGPXCoordinates(from: data)

            // 좌표 캐싱
            coordinatesCache.setObject(coordinates as NSArray, forKey: gpxURL as NSString)
            return coordinates
        } catch {
            return []
        }
    }

    /// GPX URL에서 지도 썸네일을 비동기로 생성합니다.
    ///
    /// - Parameter gpxURL: GPX 파일의 URL 문자열
    /// - Returns: 생성된 썸네일 이미지 또는 `nil` (실패한 경우)
    ///
    /// ## 기능 설명
    /// - GPX 파일을 다운로드하여 좌표 데이터를 추출
    /// - 좌표를 기반으로 지도 스냅샷 생성
    /// - 경로를 파란색 선으로 표시하고 시작점(S), 끝점(E) 마커 추가
    /// - 생성된 이미지는 자동으로 캐시됨
    func generateThumbnailAsync(from gpxURL: String) async -> UIImage? {
        // 캐시 확인
        if let cachedImage = thumbnailCache.object(forKey: gpxURL as NSString) {
            return cachedImage
        }

        // 직접 처리
        let image = await downloadAndProcessGPX(urlString: gpxURL)
        if let image = image {
            thumbnailCache.setObject(image, forKey: gpxURL as NSString)
        }
        return image
    }

    /// 캐시된 썸네일 이미지를 즉시 반환합니다.
    func getCachedThumbnail(for gpxURL: String) -> UIImage? {
        return thumbnailCache.object(forKey: gpxURL as NSString)
    }

    ///좌표값 다운로드해서 이미지를 생성합니다.
    private func downloadAndProcessGPX(urlString: String) async -> UIImage? {
        let coordinates = await getOrDownloadCoordinates(from: urlString)

        if coordinates.isEmpty {
            return nil
        }

        return await createMapSnapshot(coordinates: coordinates)
    }

    /// GPX 파일의 첫 번째 좌표를 가져옵니다.
    ///
    /// - Parameter gpxURL: GPX 파일의 URL 문자열
    /// - Returns: 첫 번째 좌표 또는 `nil` (파일이 없거나 좌표가 없는 경우)
    ///
    /// 산책 코스의 시작 지점을 표시하는 데 사용됩니다.
    func getFirstCoordinate(from gpxURL: String) async -> CLLocationCoordinate2D? {
        let coordinates = await getOrDownloadCoordinates(from: gpxURL)
        return coordinates.first
    }

    /// GPX 데이터에서 좌표 리스트를 파싱합니다.
    ///
    /// - Parameter data: GPX 파일의 Data
    /// - Returns: 파싱된 좌표 배열
    ///
    /// ## 파싱 방식
    /// - 첫 번째 `<trk>` 태그 내의 모든 `<trkpt>` 요소를 추출
    /// - 정규식을 사용하여 lat, lon 속성값을 파싱
    /// - 잘못된 좌표값은 자동으로 제외됨
    func parseGPXCoordinates(from data: Data) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()

        guard let xmlString = String(data: data, encoding: .utf8) else {
            return coordinates
        }

        // 첫 번째 트랙만 추출
        var targetContent = xmlString
        if let firstTrackStart = xmlString.range(of: "<trk>") {
            let afterFirstTrack = String(xmlString[firstTrackStart.upperBound...])
            if let firstTrackEnd = afterFirstTrack.range(of: "</trk>") {
                targetContent = String(afterFirstTrack[..<firstTrackEnd.lowerBound])
            }
        }

        let pattern = "<trkpt lat=\"([^\"]+)\" lon=\"([^\"]+)\""

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsrange = NSRange(targetContent.startIndex..<targetContent.endIndex, in: targetContent)

            regex.enumerateMatches(in: targetContent, options: [], range: nsrange) { match, _, _ in
                guard let match = match,
                      let latRange = Range(match.range(at: 1), in: targetContent),
                      let lonRange = Range(match.range(at: 2), in: targetContent) else {
                    return
                }

                let latString = String(targetContent[latRange])
                let lonString = String(targetContent[lonRange])

                if let lat = Double(latString), let lon = Double(lonString) {
                    coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                }
            }
        } catch {
            print(error)
        }

        return coordinates
    }

    /// 좌표 배열을 기반으로 지도 스냅샷을 생성합니다.
    ///
    /// - Parameter coordinates: 경로를 구성하는 좌표 배열
    /// - Returns: 생성된 지도 스냅샷 이미지
    ///
    /// ## 생성되는 이미지 특징
    /// - 크기: 300x150 포인트
    /// - 지도 타입: 표준 지도
    /// - 경로가 모두 보이도록 자동으로 확대/축소 조정
    private func createMapSnapshot(coordinates: [CLLocationCoordinate2D]) async -> UIImage? {
        guard coordinates.count > 1 else {
            return nil
        }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        let mapRect = polyline.boundingMapRect
        let region = MKCoordinateRegion(mapRect)

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta * 1.5,
                longitudeDelta: region.span.longitudeDelta * 1.5
            )
        )
        options.size = CGSize(width: 300, height: 150)
        options.scale = await UIScreen.main.scale
        options.mapType = .standard
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            return drawRouteOnSnapshot(snapshot: snapshot, coordinates: coordinates)
        } catch {
            return nil
        }
    }

    /// 지도 스냅샷에 경로와 마커를 그립니다.
    ///
    /// - Parameters:
    ///   - snapshot: 기본 지도 스냅샷
    ///   - coordinates: 경로를 구성하는 좌표 배열
    /// - Returns: 경로와 마커가 그려진 최종 이미지
    ///
    /// ## 그려지는 요소
    /// - 파란색 경로선 (두께 3포인트)
    /// - 시작점: 초록색 원에 "S" 텍스트
    /// - 끝점: 빨간색 원에 "E" 텍스트
    private func drawRouteOnSnapshot(snapshot: MKMapSnapshotter.Snapshot, coordinates: [CLLocationCoordinate2D]) -> UIImage? {
        let image = snapshot.image

        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        image.draw(at: .zero)

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }

        // 경로 그리기
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(3)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        for (index, coordinate) in coordinates.enumerated() {
            let point = snapshot.point(for: coordinate)

            if index == 0 {
                context.move(to: point)
            } else {
                context.addLine(to: point)
            }
        }

        context.strokePath()

        // 시작점과 끝점 마커
        if let startCoord = coordinates.first,
           let endCoord = coordinates.last {

            let startPoint = snapshot.point(for: startCoord)
            let endPoint = snapshot.point(for: endCoord)

            // 배경 원 그리기
            context.setFillColor(UIColor.systemGreen.cgColor)
            context.fillEllipse(in: CGRect(x: startPoint.x - 6, y: startPoint.y - 6, width: 12, height: 12))

            context.setFillColor(UIColor.systemRed.cgColor)
            context.fillEllipse(in: CGRect(x: endPoint.x - 6, y: endPoint.y - 6, width: 12, height: 12))

            // S, E 텍스트 그리기
            let font = UIFont.preferredFont(forTextStyle: .caption2)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]

            // S 텍스트
            let sText = "S"
            let sSize = sText.size(withAttributes: textAttributes)
            let sRect = CGRect(
                x: startPoint.x - sSize.width / 2,
                y: startPoint.y - sSize.height / 2,
                width: sSize.width,
                height: sSize.height
            )
            sText.draw(in: sRect, withAttributes: textAttributes)

            // E 텍스트
            let eText = "E"
            let eSize = eText.size(withAttributes: textAttributes)
            let eRect = CGRect(
                x: endPoint.x - eSize.width / 2,
                y: endPoint.y - eSize.height / 2,
                width: eSize.width,
                height: eSize.height
            )
            eText.draw(in: eRect, withAttributes: textAttributes)
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage
    }
}

extension WalkingCourse {
    /// 거리를 킬로미터 단위의 정수로 변환합니다.
    ///
    /// - Returns: 킬로미터 단위의 거리 (정수)
    ///
    /// `crsDstnc` 필드가 이미 숫자 문자열이므로 직접 Int로 변환합니다.
    /// 변환에 실패하면 0을 반환합니다.
    var distanceInKm: Int {
        return Int(crsDstnc) ?? 0
    }
}
