//
//  OnboardingViewController.swift
//  Health
//
//  Created by 권도현 on 8/1/25.
//

import UIKit

class OnboardingViewController: CoreGradientViewController, UIScrollViewDelegate {

    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var continueButtonTrailing: NSLayoutConstraint!

    private var iPadWidthConstraint: NSLayoutConstraint?
    private var iPadCenterXConstraint: NSLayoutConstraint?
    private var didReachLastPage = false       // 마지막 페이지 도달 경험
    private var pages: [UIView] = []

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let pageControl = UIPageControl()

    private let firstPageView = UIView()
    private let secondPageView = UIView()
    private let thirdPageView = UIView()

    private var lastViewedPage: Int = 0

    private var currentPage: Int {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return 0 }
        return Int(round(scrollView.contentOffset.x / pageWidth))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupPages()
        setupPageControl()
        setupContinueButton()

        pageControl.currentPage = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 마지막으로 보던 페이지로 이동
        let offsetX = CGFloat(lastViewedPage) * scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
        pageControl.currentPage = lastViewedPage

        // 마지막 페이지 도달 경험이 있으면 버튼 활성화 유지
        continueButton.isEnabled = didReachLastPage
        continueButton.backgroundColor = didReachLastPage ? .accent : .buttonBackground
    }

    private func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.delegate = self

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12)
        ])

        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    private func setupPages() {
        pages = [firstPageView, secondPageView, thirdPageView]

        pages.forEach { page in
            page.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(page)
            page.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
        }

        configureAllPages()
    }

    private func configureAllPages() {
        configureCentralPage(firstPageView,
                             imageName: "dashboardIcon",
                             title: "대시보드",
                             subtitle: "일일 걸음 및 건강 요약",
                             description: "당신의 걸음, 하루하루가 건강으로 이어집니다. 일일 걸음 수와 보행 패턴을 한눈에 확인하고, AI가 요약해주는 맞춤 건강 인사이트를 만나보세요.")

        configureCentralPage(secondPageView,
                             imageName: "calandarIcon",
                             title: "캘린더",
                             subtitle: "목표 달성 현황 & 기록",
                             description: "캘린더에서 일일 목표 달성 현황과 액티비티 링을 확인하고, 달력에서 과거의 걸음과 보행 건강 데이터를 쉽게 돌아볼 수 있어요.")

        configureCentralPage(thirdPageView,
                             imageName: "chatbotIcon",
                             title: "맞춤케어",
                             subtitle: "개인화 코스 & 챗봇",
                             description: "건강 앱 데이터 기반 사용자에게 난이도별 맞춤 걸음코스 추천과 분석은 물론, 걷기·러닝에 특화된 챗봇과 함께 건강한 습관을 만들어보세요!")
    }

    private func configureCentralPage(_ page: UIView,
                                      imageName: String,
                                      title: String,
                                      subtitle: String,
                                      description: String) {

        page.subviews.forEach { $0.removeFromSuperview() }

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: imageName)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = description
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        let isIpad = traitCollection.userInterfaceIdiom == .pad
        titleLabel.font = UIFont.systemFont(ofSize: isIpad ? 50 : 36, weight: .black)
        subtitleLabel.font = UIFont.systemFont(ofSize: isIpad ? 24 : 20, weight: .medium)
        descriptionLabel.font = UIFont.systemFont(ofSize: isIpad ? 18 : 12, weight: .regular)

        let container = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, imageView, descriptionLabel])
        container.axis = .vertical
        container.alignment = .center
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        page.addSubview(container)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: page.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: page.centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: page.leadingAnchor, constant: isIpad ? 130 : 20),
            container.trailingAnchor.constraint(lessThanOrEqualTo: page.trailingAnchor, constant: isIpad ? -130 : -20),
            imageView.widthAnchor.constraint(equalToConstant: 240),
            imageView.heightAnchor.constraint(equalToConstant: 240)
        ])
    }

    private func setupPageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .accent

        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -4),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = currentPage
        pageControl.currentPage = page

        // 마지막 페이지 한 번이라도 도달하면 계속 true
        if page == pages.count - 1 {
            didReachLastPage = true
        }

        // 버튼 활성화는 마지막 페이지 도달 경험 기준
        continueButton.isEnabled = didReachLastPage
        continueButton.backgroundColor = didReachLastPage ? .accent : .buttonBackground

        lastViewedPage = page
    }

    private func setupContinueButton() {
        applyBackgroundGradient(.midnightBlack)
        
        var config = UIButton.Configuration.filled()
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .headline)
            return out
        }
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .systemBackground
        var container = AttributeContainer()
        container.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = AttributedString("다음", attributes: container)
        
        continueButton.configurationUpdateHandler = { [weak self] button in
            self?.continueButton.alpha = (button.state == .highlighted) ? 0.75 : 1.0
        }
        
        continueButton.configuration = config
        continueButton.backgroundColor = .buttonBackground
        continueButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        continueButton.applyCornerStyle(.medium)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let isIpad = traitCollection.userInterfaceIdiom == .pad
        if isIpad {
            continueButtonLeading?.isActive = false
            continueButtonTrailing?.isActive = false

            if iPadWidthConstraint == nil {
                iPadWidthConstraint = continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
                iPadCenterXConstraint = continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                iPadWidthConstraint?.isActive = true
                iPadCenterXConstraint?.isActive = true
            }
        } else {
            iPadWidthConstraint?.isActive = false
            iPadCenterXConstraint?.isActive = false

            continueButtonLeading?.isActive = true
            continueButtonTrailing?.isActive = true
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let page = currentPage

        coordinator.animate(alongsideTransition: { _ in
            self.scrollView.layoutIfNeeded()
            let newOffset = CGFloat(page) * self.scrollView.bounds.width
            self.scrollView.setContentOffset(CGPoint(x: newOffset, y: 0), animated: false)
        }, completion: nil)

        super.viewWillTransition(to: size, with: coordinator)
    }

    @IBAction func buttonAction(_ sender: Any) {
        performSegue(withIdentifier: "goToHealthLink", sender: self)
    }
}

