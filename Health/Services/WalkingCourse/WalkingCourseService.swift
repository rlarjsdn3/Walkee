//
//  WalkingCourseService.swift
//  Health
//
//  Created by juks86 on 8/9/25.
//

import UIKit
import MapKit

class WalkingCourseService {
    @MainActor static let shared = WalkingCourseService()

    // 썸네일 캐시
    private var thumbnailCache = NSCache<NSString, UIImage>()
    //좌표 캐시
    private var coordinatesCache = NSCache<NSString, NSArray>()
    //코스 데이터 캐시(한 번 로드하면 계속 사용)
    private var coursesCache: [WalkingCourse]?

    private init() {}

    // 로컬 JSON에서 코스 데이터를 불러오는 함수
    func loadWalkingCourses() -> [WalkingCourse] {
        // 이미 로드했으면 캐시된 데이터 반환
        if let cachedCourses = coursesCache {
            return cachedCourses
        }

        // 1. Bundle에서 JSON 파일 경로 찾기
        guard let path = Bundle.main.path(forResource: "walkingCourse", ofType: "json") else {
            print(" JSON 파일을 찾을 수 없습니다")
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
            print("JSON 파일 읽기 실패: \(error.localizedDescription)")
            return []
        }
    }

    // 좌표 캐싱을 위한 공통 메서드
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
            print("GPX 다운로드 실패: \(error)")
            return []
        }
    }

    // GPX URL에서 썸네일 생성 (캐시 적용)
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

    func getCachedThumbnail(for gpxURL: String) -> UIImage? {
        return thumbnailCache.object(forKey: gpxURL as NSString)
    }

    //좌표값 다운로드해서 이미지 생성
    private func downloadAndProcessGPX(urlString: String) async -> UIImage? {
        let coordinates = await getOrDownloadCoordinates(from: urlString)

        if coordinates.isEmpty {
            return nil
        }

        return await createMapSnapshot(coordinates: coordinates)
    }

    //첫번째 좌표값 가져오기
    func getFirstCoordinate(from gpxURL: String) async -> CLLocationCoordinate2D? {
        let coordinates = await getOrDownloadCoordinates(from: gpxURL)
        return coordinates.first
    }

    //좌표 리스트만 반환
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
            print("정규식 에러: \(error)")
        }

        return coordinates
    }

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
    // 거리를 Double로 변환하는 계산 프로퍼티
    var distanceInKm: Int {
        // crsDstnc가 이미 숫자 문자열이므로 바로 변환
        return Int(crsDstnc) ?? 0
    }
}
