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
    
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let pageControl = UIPageControl()
    private var pages: [UIView] = []
    
    // 페이지 뷰 참조
    private let firstPageView = UIView()   // 1번째 페이지
    private let secondPageView = UIView()  // 2번째 페이지
    private let thirdPageView = UIView()   // 3번째 페이지
    private let fourthPageView = UIView()  // 4번째 페이지
    
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
        
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        pageControl.currentPage = 0
    }
    
    //ScrollView + StackView
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
        stack.spacing = 0
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
    
    //Pages
    private func setupPages() {
        pages = [firstPageView, secondPageView, thirdPageView, fourthPageView]
        
        pages.forEach { page in
            page.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(page)
            page.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
        }
        
        // 모든 페이지 중앙 정렬 구성
        configureCentralPage(firstPageView, imageName: "star.fill", title: "환영합니다!", description: "Apple 건강앱과 연동해 맞춤형 건강 관리 가능")
        configureCentralPage(secondPageView, imageName: "heart.fill", title: "건강 정보 확인", description: "건강 앱과 연동하여 일일 걸음 수, 심박수 등을 확인할 수 있어요.")
        configureCentralPage(thirdPageView, imageName: "star.fill", title: "맞춤형 코스 추천", description: "이미지를 중앙에 두고 텍스트도 중앙 정렬")
        configureCentralPage(fourthPageView, imageName: "figure.walk", title: "목표 달성", description: "이미지를 중앙에 두고 텍스트도 중앙 정렬")
    }
    
    private func configureCentralPage(_ page: UIView, imageName: String, title: String, description: String) {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemPink
        imageView.image = UIImage(systemName: imageName)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = description
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        
        page.addSubview(imageView)
        page.addSubview(titleLabel)
        page.addSubview(descriptionLabel)
        
        // iPad/iPhone에 따라 폰트 크기 조절
        let titleFont: UIFont
        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            titleFont = UIFont.boldSystemFont(ofSize: 50)
        } else {
            titleFont = UIFont.boldSystemFont(ofSize: 16)
        }
        titleLabel.font = titleFont
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: page.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: page.centerYAnchor, constant: -60),
            imageView.widthAnchor.constraint(equalToConstant: 240),
            imageView.heightAnchor.constraint(equalToConstant: 240),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: page.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: page.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: page.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: page.trailingAnchor, constant: -20)
        ])
    }
    
    //Page Control
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
    
    //ScrollView Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = currentPage
        pageControl.currentPage = page
        
        // 버튼 활성화/비활성 색상 처리
        if page == pages.count - 1 {
            continueButton.isEnabled = true
            continueButton.backgroundColor = .accent
        } else {
            continueButton.isEnabled = false
            continueButton.backgroundColor = .buttonBackground
        }
    }
    
    //Continue Button
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
            switch button.state {
            case .highlighted:
                self?.continueButton.alpha = 0.75
            default:
                self?.continueButton.alpha = 1.0
            }
        }
        
        continueButton.configuration = config
        continueButton.isEnabled = false
        continueButton.backgroundColor = .buttonBackground
        continueButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        continueButton.applyCornerStyle(.medium)
    }
    
    //Layout
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let isIpad = traitCollection.horizontalSizeClass == .regular &&
        traitCollection.verticalSizeClass == .regular
        
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
            let offsetX = CGFloat(page) * size.width
            self.scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        performSegue(withIdentifier: "goToHealthLink", sender: self)
    }
}
