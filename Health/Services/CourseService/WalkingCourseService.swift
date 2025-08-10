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

    private init() {}

    // GPX URL에서 썸네일 생성 (캐시 적용)
    func generateThumbnailAsync(from gpxURL: String) async -> UIImage? {
        // 캐시 확인
        if let cachedImage = thumbnailCache.object(forKey: gpxURL as NSString) {
            return cachedImage
        }

        // GPX 다운로드 및 처리
        let image = await downloadAndProcessGPX(urlString: gpxURL)

        if let image = image {
            thumbnailCache.setObject(image, forKey: gpxURL as NSString)
        }

        return image
    }

    private func downloadAndProcessGPX(urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let coordinates = parseGPXCoordinates(from: data)

            if coordinates.isEmpty {
                return nil
            }

            return await createMapSnapshot(coordinates: coordinates)

        } catch {
            print("❌ GPX 다운로드 실패: \(error)")
            return nil
        }
    }

    private func parseGPXCoordinates(from data: Data) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()

        guard let xmlString = String(data: data, encoding: .utf8) else {
            return coordinates
        }

        let pattern = "<trkpt lat=\"([^\"]+)\" lon=\"([^\"]+)\""

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsrange = NSRange(xmlString.startIndex..<xmlString.endIndex, in: xmlString)

            regex.enumerateMatches(in: xmlString, options: [], range: nsrange) { match, _, _ in
                guard let match = match,
                      let latRange = Range(match.range(at: 1), in: xmlString),
                      let lonRange = Range(match.range(at: 2), in: xmlString) else {
                    return
                }

                let latString = String(xmlString[latRange])
                let lonString = String(xmlString[lonRange])

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

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            return drawRouteOnSnapshot(snapshot: snapshot, coordinates: coordinates)
        } catch {
            print("스냅샷 생성 실패: \(error)")
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

            context.setFillColor(UIColor.systemGreen.cgColor)
            context.fillEllipse(in: CGRect(x: startPoint.x - 6, y: startPoint.y - 6, width: 12, height: 12))

            context.setFillColor(UIColor.systemRed.cgColor)
            context.fillEllipse(in: CGRect(x: endPoint.x - 6, y: endPoint.y - 6, width: 12, height: 12))
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage
    }
}
