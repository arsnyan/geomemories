//
//  MediaCardView.swift
//  GeoMemories
//
//  Created by Арсен Саруханян on 02.09.2025.
//

import UIKit
import SnapKit
import Combine
import AVKit

final class MediaCardView: UICollectionViewCell {
    static let reuseIdentifier = "MediaCardViewCell"
    
    // MARK: - UI Elements
    
    private let imageView = UIImageView()
    private let playerView = UIView()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    // MARK: - Video Controls UI
    private let controlsContainer = UIView()
    private let playPauseContainer = UIVisualEffectView(
        effect: UIBlurEffect(
            style: .systemUltraThinMaterialDark
        )
    )
    private let playPauseButton: UIButton = {
        if #available(iOS 26.0, *) {
            return UIButton(configuration: .clearGlass())
        } else {
            return UIButton(type: .system)
        }
    }()
    private let progressSlider = UISlider()
    
    private var hideControlsTask: Task<Void, Never>?
    private var areControlsVisible = true {
        didSet {
            UIView.animate(withDuration: 0.2) { [unowned self] in
                let alpha: CGFloat = self.areControlsVisible ? 1.0 : 0.0
                self.playPauseContainer.alpha = alpha
                self.playPauseButton.alpha = alpha
                self.progressSlider.alpha = alpha
            }
            
            hideControlsTask?.cancel()
            
            if areControlsVisible {
                hideControlsTask = Task {
                    try? await Task.sleep(for: .seconds(visibilityTimeUntilGone))
                    guard !Task.isCancelled else { return }
                    
                    await MainActor.run {
                        areControlsVisible = false
                    }
                }
            }
        }
    }
    private let visibilityTimeUntilGone: Double = 5.0
    
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Model
    
    var viewModel: MediaCardViewModelProtocol? {
        didSet {
            configureCell()
        }
    }
    
    // MARK: - View Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hideControlsTask?.cancel()
        hideControlsTask = nil
        
        imageView.image = nil
        imageView.isHidden = true
        playerView.isHidden = true
        
        cleanUpPlayer()
        cancellables.removeAll()
        
        areControlsVisible = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }
}

// MARK: - UI Setup
private extension MediaCardView {
    func configureCell() {
        guard let viewModel = viewModel else { return }
        
        switch viewModel.mediaType {
        case .image:
            setupForImage(with: viewModel.mediaURL)
        case .video:
            setupForVideo(with: viewModel.mediaURL)
        }
    }
    
    func setupUI() {
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        setupImageView()
        setupPlayerView()
        setupControls()
    }
    
    func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    func setupPlayerView() {
        playerView.backgroundColor = .systemGray6
        contentView.addSubview(playerView)
        playerView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    func setupPlayPauseButton() {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        // Since Liquid Glass version doesn't support it, no need checking for version
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(
            self,
            action: #selector(playPauseButtonTapped),
            for: .touchUpInside
        )
        
        if #available(iOS 26.0, *) {
            playPauseContainer.isHidden = true
            controlsContainer.addSubview(playPauseButton)
            playPauseButton.snp.makeConstraints { make in
                make.size.equalTo(44)
                make.center.equalToSuperview()
            }
        } else {
            playPauseContainer.layer.cornerRadius = 22
            playPauseContainer.clipsToBounds = true
            
            playPauseContainer.contentView.addSubview(playPauseButton)
            controlsContainer.addSubview(playPauseContainer)
            
            playPauseContainer.snp.makeConstraints { make in
                make.size.equalTo(44)
                make.center.equalToSuperview()
            }
            playPauseButton.snp.makeConstraints { $0.size.equalToSuperview() }
        }
    }
    
    func setupControls() {
        controlsContainer.layer.cornerRadius = 16
        controlsContainer.clipsToBounds = true
        playerView.addSubview(controlsContainer)
        controlsContainer.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }
        
        setupPlayPauseButton()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapVideoContainer))
        controlsContainer.addGestureRecognizer(tapGesture)
        
        progressSlider.minimumValue = 0
        progressSlider.addTarget(
            self,
            action: #selector(sliderValueChanged),
            for: .valueChanged
        )
        progressSlider.addTarget(
            self,
            action: #selector(resetHideControlsTimer),
            for: .touchDown
        )
        
        controlsContainer.addSubview(progressSlider)
        progressSlider.snp.makeConstraints {
            $0.leading.bottom.trailing.equalToSuperview().inset(4)
        }
    }
    
    // MARK: - Media Setup
    func setupForImage(with url: URL?) {
        playerView.isHidden = true
        imageView.isHidden = false
        imageView.image = viewModel?.cachedImage
    }
    
    func setupForVideo(with url: URL?) {
        imageView.isHidden = true
        playerView.isHidden = false
        
        guard let url else { return }
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = contentView.bounds
        playerLayer?.videoGravity = .resizeAspect
        playerView.layer.insertSublayer(playerLayer!, at: 0)
        
        areControlsVisible = true
        
        addPlayerObservers()
    }
    
    func cleanUpPlayer() {
        player?.pause()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }
    
    func addPlayerObservers() {
        player?.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                let imageName = status == .playing ? "pause.fill" : "play.fill"
                self?.playPauseButton.setImage(
                    UIImage(systemName: imageName),
                    for: .normal
                )
                
                if status != .playing {
                    self?.areControlsVisible = true
                }
            }
            .store(in: &cancellables)
        
        let interval = CMTime(
            seconds: 0.5,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main,
            using: { [weak self] time in
                guard let self, let duration = self.player?.currentItem?.duration else {
                    return
                }
                
                let durationSeconds = CMTimeGetSeconds(duration)
                let currentTimeSeconds = CMTimeGetSeconds(time)
                if durationSeconds.isFinite, durationSeconds > 0 {
                    progressSlider.value = Float(currentTimeSeconds / durationSeconds)
                }
            }
        )
    }
}

// MARK: - Selector Functions
@objc private extension MediaCardView {
    func resetHideControlsTimer() {
        areControlsVisible = true
    }
    
    func didTapVideoContainer() {
        resetHideControlsTimer()
    }
    
    func playPauseButtonTapped() {
        guard let player else { return }
        resetHideControlsTimer()
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
    
    func sliderValueChanged() {
        guard let player, let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        if durationInSeconds.isFinite {
            let seekTime = CMTime(
                seconds: Double(progressSlider.value) * durationInSeconds,
                preferredTimescale: .max
            )
            player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
}
