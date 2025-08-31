//
//  CourseViewController.swift
//  Health
//
//  Created by juks86 on 8/22/25.
//

import UIKit
import MapKit
import TSAlertController

/// 추천 걷기 코스의 상세 경로를 지도에 표시하는 ViewController
///
/// 이 클래스는 GPX 파일에서 파싱한 좌표 데이터를 기반으로 지도에 경로를 그리고,
/// 시작점과 종점 마커를 표시합니다. 사용자가 시작점을 탭하면 Apple Maps로 길찾기를
/// 연결할 수 있는 기능도 제공합니다.
class DetailCourseViewController: UIViewController,Alertable {
    var courseCoordinates: [CLLocationCoordinate2D] = []
    var courseInfo: WalkingCourse?

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupMap()
        setupCloseButton()
    }

    /// 지도 뷰의 기본 설정을 구성합니다
    private func setupMapView() {
        mapView.delegate = self
    }

    /// 네비게이션 바의 제목과 닫기 버튼을 설정합니다.
    private func setupCloseButton() {
        // 제목 설정
        if let courseInfo = courseInfo {
            title = courseInfo.crsKorNm
        } else {
            title = "코스 경로"
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )

        navigationItem.leftBarButtonItem = nil
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    /// 지도에 코스 경로와 시작/종점 마커를 표시합니다.
    private func setupMap() {
        guard !courseCoordinates.isEmpty else { return }

        let polyline = MKPolyline(coordinates: courseCoordinates, count: courseCoordinates.count)
        mapView.addOverlay(polyline)

        // 시작점과 종점 좌표 확인
        if let startCoordinate = courseCoordinates.first,
           let endCoordinate = courseCoordinates.last {

            let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
            let endLocation = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
            let distance = startLocation.distance(from: endLocation)

            // 50미터 이내면 같은 지점으로 간주
            if distance < 50 {
                // 하나의 마커만 표시 (순환 코스)
                let circuitAnnotation = MKPointAnnotation()
                circuitAnnotation.coordinate = startCoordinate
                circuitAnnotation.title = "출발/도착"
                mapView.addAnnotation(circuitAnnotation)
            } else {
                // 별도 마커 표시
                let startAnnotation = MKPointAnnotation()
                startAnnotation.coordinate = startCoordinate
                startAnnotation.title = "시작점"
                mapView.addAnnotation(startAnnotation)

                let endAnnotation = MKPointAnnotation()
                endAnnotation.coordinate = endCoordinate
                endAnnotation.title = "종점"
                mapView.addAnnotation(endAnnotation)
            }
        }

        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: false)
    }

    /// 지도 마커의 외형을 설정합니다.
    ///
    /// - Parameter annotation: 표시할 마커의 annotation 객체
    /// - Returns: 설정된 MKAnnotationView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "CoursePoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }

        if let markerView = annotationView as? MKMarkerAnnotationView {
            if annotation.title == "시작점" {
                markerView.markerTintColor = .systemGreen
                markerView.glyphText = "S"
            } else if annotation.title == "종점" {
                markerView.markerTintColor = .systemRed
                markerView.glyphText = "E"
            }
        }

        return annotationView
    }
}

// MARK: - MKMapViewDelegate
extension DetailCourseViewController: MKMapViewDelegate {

    /// 지도 경로선의 렌더링 스타일을 설정합니다.
    ///
    /// - Parameter overlay: 렌더링할 overlay 객체
    /// - Returns: 설정된 MKOverlayRenderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3.0
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    /// 마커가 선택되었을 때의 동작을 처리합니다.
    ///
    /// - Parameter view: 선택된 annotation view
    ///
    /// 시작점이나 출발/도착 마커를 탭하면 Apple Maps 길찾기 옵션을 제공하는
    /// 액션시트를 표시합니다. 마커 선택 상태는 즉시 해제됩니다.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation?.title == "시작점" || view.annotation?.title == "출발/도착" {
            showDirectionsActionSheet()
        }
        mapView.deselectAnnotation(view.annotation, animated: false)
    }

    /// Apple Maps 길찾기 옵션을 제공하는 액션시트를 표시합니다.
    ///
    /// 도보와 자동차 두 가지 이동 방법을 선택할 수 있는 커스텀 액션시트를 표시합니다.
    private func showDirectionsActionSheet() {
        let actionSheetView = createDirectionsActionSheetView()

        showActionSheet(
            actionSheetView,
            confirmTitle: "닫기",
            onConfirmAction: { _ in }
        )
    }

    /// 길찾기 옵션 액션시트의 UI를 생성합니다.
    ///
    /// - Returns: 길찾기 옵션이 포함된 커스텀 뷰
    private func createDirectionsActionSheetView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        // 제목 추가
        let titleLabel = UILabel()
        titleLabel.text = "이동 방법을 선택해주세요"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label

        // 수평 스택뷰로 버튼 배치
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually

        // 도보 버튼 배경
        let walkingBackgroundView = UIView()
        walkingBackgroundView.backgroundColor = .boxBg
        walkingBackgroundView.layer.cornerRadius = 16

        let walkingButton = createDirectionButton(title: "도보", systemImage: "figure.walk", mode: MKLaunchOptionsDirectionsModeWalking)
        walkingBackgroundView.addSubview(walkingButton)

        // 자동차 버튼 배경
        let drivingBackgroundView = UIView()
        drivingBackgroundView.backgroundColor = .boxBg
        drivingBackgroundView.layer.cornerRadius = 16

        let drivingButton = createDirectionButton(title: "자동차", systemImage: "car.fill", mode: MKLaunchOptionsDirectionsModeDriving)
        drivingBackgroundView.addSubview(drivingButton)

        // 제약조건 설정
        walkingButton.translatesAutoresizingMaskIntoConstraints = false
        drivingButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            walkingButton.topAnchor.constraint(equalTo: walkingBackgroundView.topAnchor, constant: 8),
            walkingButton.leadingAnchor.constraint(equalTo: walkingBackgroundView.leadingAnchor, constant: 8),
            walkingButton.trailingAnchor.constraint(equalTo: walkingBackgroundView.trailingAnchor, constant: -8),
            walkingButton.bottomAnchor.constraint(equalTo: walkingBackgroundView.bottomAnchor, constant: -8),

            drivingButton.topAnchor.constraint(equalTo: drivingBackgroundView.topAnchor, constant: 8),
            drivingButton.leadingAnchor.constraint(equalTo: drivingBackgroundView.leadingAnchor, constant: 8),
            drivingButton.trailingAnchor.constraint(equalTo: drivingBackgroundView.trailingAnchor, constant: -8),
            drivingButton.bottomAnchor.constraint(equalTo: drivingBackgroundView.bottomAnchor, constant: -8)
        ])

        buttonStackView.addArrangedSubview(walkingBackgroundView)
        buttonStackView.addArrangedSubview(drivingBackgroundView)

        // 메인 스택뷰에 제목과 버튼 추가
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(buttonStackView)

        containerView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])

        return containerView
    }

    /// 길찾기 모드별 버튼을 생성합니다.
    ///
    /// - Parameters:
    ///   - title: 버튼에 표시할 텍스트
    ///   - systemImage: 버튼 아이콘의 SF Symbol 이름
    ///   - mode: MapKit 길찾기 모드 상수
    /// - Returns: 설정된 UIButton 인스턴스
    private func createDirectionButton(title: String, systemImage: String, mode: String) -> UIButton {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePlacement = .leading
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        button.configuration = config
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(directionButtonTapped(_:)), for: .touchUpInside)
        button.tag = mode.hashValue

        // 하이라이트 효과
        button.configurationUpdateHandler = { button in
            switch button.state {
            case .highlighted:
                button.alpha = 0.75
            default:
                button.alpha = 1.0
            }
        }

        return button
    }

    /// 길찾기 버튼이 탭되었을 때의 동작을 처리합니다.
    ///
    /// - Parameter sender: 탭된 버튼 객체
    @objc private func directionButtonTapped(_ sender: UIButton) {
        let mode: String
        let modeTitle: String

        switch sender.tag {
        case MKLaunchOptionsDirectionsModeWalking.hashValue:
            mode = MKLaunchOptionsDirectionsModeWalking
            modeTitle = "도보"
        case MKLaunchOptionsDirectionsModeDriving.hashValue:
            mode = MKLaunchOptionsDirectionsModeDriving
            modeTitle = "자동차"
        default:
            return
        }

        // 액션시트 먼저 닫기
        presentedViewController?.dismiss(animated: true) {
            // 알림창 표시
            self.showAlert(
                "경로 안내",
                message: "Apple Maps에서 \(modeTitle) 길찾기를 실행하시겠습니까?",
                primaryTitle: "확인",
                onPrimaryAction: { _ in
                    self.startDirections(mode: mode)
                },
                cancelTitle: "취소",
                onCancelAction: { _ in
                }
            )
        }
    }

    /// Apple Maps 앱에서 길찾기를 시작합니다.
    ///
    /// - Parameter mode: 길찾기 모드 (도보/자동차)
    private func startDirections(mode: String) {
        guard let startCoordinate = courseCoordinates.first else { return }

        let placemark = MKPlacemark(coordinate: startCoordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = courseInfo?.crsKorNm ?? "코스 시작점"

        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: mode
        ]

        mapItem.openInMaps(launchOptions: launchOptions)
    }
}
