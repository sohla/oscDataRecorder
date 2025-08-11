
/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Player view controller
*/

import UIKit
import AVFoundation
import CoreMedia
import ImageIO
import SceneKit
import SwiftyJSON
import OSCKit

class PlayerViewController: UIViewController, AVPlayerItemMetadataOutputPushDelegate {
	
    let client = OSCClient(localPort: 57220)
    var deviceData: any DeviceDataProtocol = ASDeviceData()
    
    private var player: AVPlayer?
    private var seekToZeroBeforePlay = false
    private var playerAsset: AVAsset?
    private var playerLayer: AVPlayerLayer?
    private var defaultVideoTransform = CGAffineTransform.identity
    
    var delegate: DeviceViewControllerDelegate?
    private let itemMetadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
    private var honorTimedMetadataTracksDuringPlayback = true
    private var periodicObserver: Any?
    
    
    //------------------------------------------------------------------
    
    @IBOutlet private weak var honorTimedMetadataTracksSwitch: UISwitch!
    @IBOutlet private weak var playerView: UIView!
    @IBOutlet private weak var locationOverlayLabel: UILabel!
    @IBOutlet private weak var playButton: UIBarButtonItem!

    @IBOutlet weak var progressView: UIProgressView!
    
    
    //------------------------------------------------------------------
	// MARK: View Controller Life Cycle
    //------------------------------------------------------------------

	override func viewDidLoad() {
		
        super.viewDidLoad()
		
        playerView.layer.backgroundColor = UIColor.darkGray.cgColor
		
		let metadataQueue = DispatchQueue(label: "com.example.metadataqueue", attributes: [])
		itemMetadataOutput.setDelegate(self, queue: metadataQueue)
        
	}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "devicePlayerSegue" {
            let c = segue.destination as! DeviceViewController
            delegate = c

//            delegate?.sendOSCConnect()
        }
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		// Pause the player and start from the beginning if the view reappears.
		player?.pause()
		if playerAsset != nil {
			seekToZeroBeforePlay = false
            player?.seek(to: CMTime.zero)
		}
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		/*
			If device is rotated manually while playing back, and before the next orientation track is received,
			then playerLayer's frame should be changed to match with the playerView bounds.
		*/
		coordinator.animate(alongsideTransition: { _ in
				self.playerLayer?.frame = self.playerView.layer.bounds
			},
			completion: nil)
	}
	
    //------------------------------------------------------------------
	// MARK: Segue
    //------------------------------------------------------------------

	@IBAction func unwindBackToPlayer(segue: UIStoryboardSegue) {
		// Pull any data from the view controller which initiated the unwind segue.
		let assetGridViewController = segue.source as! AssetGridViewController
		if let selectedAsset = assetGridViewController.selectedAsset {
			if selectedAsset != playerAsset {
				setUpPlayback(for: selectedAsset)
				playerAsset = selectedAsset
			}
		}
	}
	
    //------------------------------------------------------------------
	// MARK: Player
    //------------------------------------------------------------------

	private func setUpPlayback(for asset: AVAsset) {
		DispatchQueue.main.async {
			if let currentItem = self.player?.currentItem {
				currentItem.remove(self.itemMetadataOutput)
			}
			self.setUpPlayer(for: asset)
//            self.removeAllSublayers(from: self.facesLayer)
		}
	}
	
    private func setUpPlayer(for asset: AVAsset) {
        let mutableComposition = AVMutableComposition()
        
        // Create a mutableComposition for all the tracks present in the asset.
        guard let sourceVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            print("Could not get video track from asset")
            return
        }
        defaultVideoTransform = sourceVideoTrack.preferredTransform
        
        let sourceAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
        let mutableCompositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mutableCompositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do {
            try mutableCompositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceVideoTrack, at: CMTime.zero)
            if let sourceAudioTrack = sourceAudioTrack {
                try mutableCompositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceAudioTrack, at: CMTime.zero)
            }
        }
        catch {
            print("Could not insert time range into video/audio mutable composition: \(error)")
        }
        
        for metadataTrack in asset.tracks(withMediaType: AVMediaType.metadata) {
            if track(metadataTrack, hasMetadataIdentifier:AVMetadataIdentifier.quickTimeMetadataDetectedFace.rawValue) ||
                track(metadataTrack, hasMetadataIdentifier:AVMetadataIdentifier.quickTimeMetadataVideoOrientation.rawValue) ||
                track(metadataTrack, hasMetadataIdentifier:AVMetadataIdentifier.quickTimeMetadataLocationISO6709.rawValue) {
                
                let mutableCompositionMetadataTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.metadata, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try mutableCompositionMetadataTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: metadataTrack, at: CMTime.zero)
                }
                catch let error as NSError {
                    print("Could not insert time range into metadata mutable composition: \(error)")
                }
            }
        }
        
        // Get an instance of AVPlayerItem for the generated mutableComposition.
        // let playerItem = AVPlayerItem(asset: asset) // This doesn't support video orientation hence we use a mutable composition.
        let playerItem = AVPlayerItem(asset: mutableComposition)
        playerItem.add(itemMetadataOutput)
        
        if let player = player {
            player.replaceCurrentItem(with: playerItem)
        }
        else {
            // Create AVPlayer with the generated instance of playerItem. Also add the facesLayer as subLayer to this playLayer.
            player = AVPlayer(playerItem: playerItem)
            player?.actionAtItemEnd = .none
            player?.volume = 0.0
            
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.backgroundColor = UIColor.darkGray.cgColor
            playerView.layer.addSublayer(playerLayer)
            self.playerLayer = playerLayer

            
            let totalTime: Double = CMTimeGetSeconds((player?.currentItem?.duration)!)
            periodicObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 60, timescale: CMTimeScale(exactly: 1000)!) , queue: DispatchQueue.main ) { [weak self] (time) in
                    let current: Double = CMTimeGetSeconds(time)
                    var progress: Double = current / totalTime

                    if progress.isNaN {progress = 0}
                    self?.progressView.progress = Float(progress)//BUG!
                    self?.progressView.setNeedsDisplay()
            }
        }
        
        // Update the player layer to match the video's default transform. Disable animation so the transform applies immediately.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.transform = CATransform3DMakeAffineTransform(defaultVideoTransform)
        playerLayer?.frame = playerView.layer.bounds
        CATransaction.commit()
        
        // When the player item has played to its end time we'll toggle the movie controller Pause button to be the Play button.
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        seekToZeroBeforePlay = false
    }
	
	/// Called when the player item has played to its end time.
    @objc func playerItemDidReachEnd(_ notification: Notification) {
		// After the movie has played to its end time, seek back to time zero to play it again.
		seekToZeroBeforePlay = true
        player?.seek(to: CMTime.zero)
        player?.play()
	}
	

    @IBAction func onForwardButtonTapped(_ sender: Any) {
        let current = player?.currentTime()
        let jump = CMTimeMakeWithSeconds(10.0, preferredTimescale: (player?.currentTime().timescale)!)
        let newTime = CMTimeAdd(current!, jump)
        player?.seek(to: newTime)
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
    
        let current = player?.currentTime()
        let jump = CMTimeMakeWithSeconds(10.0, preferredTimescale: (player?.currentTime().timescale)!)
        let newTime = CMTimeSubtract(current!, jump)
        player?.seek(to: newTime)
        
    }
	
	@IBAction private func playButtonTapped(_ sender: AnyObject) {
        if(playerLayer?.player?.timeControlStatus == .playing) {
            player?.pause()
            playButton.image = UIImage(systemName:"play.fill")
        }else{
            player?.play()
            playButton.image = UIImage(systemName:"pause.fill")
        }
        
//		if seekToZeroBeforePlay {
//			seekToZeroBeforePlay = false
//            player?.seek(to: CMTime.zero)
//			
//			// Update the player layer to match the video's default transform.
//			playerLayer?.transform = CATransform3DMakeAffineTransform(defaultVideoTransform)
//			playerLayer?.frame = playerView.layer.bounds
//		}
//		
//		player?.play()
//        
//		playButton.isEnabled = false
//		pauseButton.isEnabled = true
	}
	
	
    //------------------------------------------------------------------
	// MARK: Timed Metadata
    //------------------------------------------------------------------

	
	@IBAction private func toggleHonorTimedMetadataTracksDuringPlayback(_ sender: AnyObject) {
		if honorTimedMetadataTracksSwitch.isOn {
			honorTimedMetadataTracksDuringPlayback = true
		}
		else {
			honorTimedMetadataTracksDuringPlayback = false
			locationOverlayLabel.text = ""
		}
	}
	
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {

        for metadataGroup in groups {
			
			DispatchQueue.main.async {
				
				// Sometimes the face/location track wouldn't contain any items because of scene change, we should remove previously drawn faceRects/locationOverlay in that case.
				if metadataGroup.items.count == 0 {
                    if self.track(track!.assetTrack!, hasMetadataIdentifier: AVMetadataIdentifier.quickTimeMetadataVideoOrientation.rawValue) {
						self.locationOverlayLabel.text = ""
					}
				}
				else {
					if self.honorTimedMetadataTracksDuringPlayback {
						
						for metdataItem in metadataGroup.items {
							guard let itemIdentifier = metdataItem.identifier, let itemDataType = metdataItem.dataType else {
								continue
							}
							
							switch itemIdentifier {
									
                                case AVMetadataIdentifier.quickTimeMetadataVideoOrientation:
									if itemDataType == String(kCMMetadataBaseDataType_SInt16) {
										if let videoOrientationValue = metdataItem.value as? NSNumber {
                                            let sourceVideoTrack = self.playerAsset!.tracks(withMediaType: AVMediaType.video)[0]
											let videoDimensions = CMVideoFormatDescriptionGetDimensions(sourceVideoTrack.formatDescriptions[0] as! CMVideoFormatDescription)
											if let videoOrientation = CGImagePropertyOrientation(rawValue: videoOrientationValue.uint32Value) {
												let orientationTransform = self.affineTransform(for:videoOrientation, with:videoDimensions)
												let rotationTransform = CATransform3DMakeAffineTransform(orientationTransform)
												
												// Remove faceBoxes before applying transform and then re-draw them as we get new face coordinates.
												//self.removeAllSublayers(from: self.facesLayer)
												self.playerLayer?.transform = rotationTransform
												self.playerLayer?.frame = self.playerView.layer.bounds
											}
										}
									}
									
                                case AVMetadataIdentifier.quickTimeMetadataLocationISO6709:
									if itemDataType == String(kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709) {
										if let itemValue = metdataItem.value as? String {
                                            self.deviceData.fromString(itemValue)
                                            self.delegate?.updateScene(data: self.deviceData)
                                            self.locationOverlayLabel.text = "has data"
                                            if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
                                                let port = UserDefaults.standard.integer(forKey: "portAddress")
                                                try? self.client.send(self.deviceData.asOSC(),to: ip,port: UInt16(port))
                                            }
										}
									}
									
								default:
									print("Timed metadata: unrecognized metadata identifier \(itemIdentifier)")
							}
						}
					}
				}
			}
		}
	}
	
    //------------------------------------------------------------------

	private func track(_ track: AVAssetTrack, hasMetadataIdentifier metadataIdentifier: String) -> Bool {
		let formatDescription = track.formatDescriptions[0] as! CMFormatDescription
		if let metadataIdentifiers = CMMetadataFormatDescriptionGetIdentifiers(formatDescription) as NSArray? {
			if metadataIdentifiers.contains(metadataIdentifier) {
				return true
			}
		}
		
		return false
	}
	
    //------------------------------------------------------------------

	private func affineTransform(for videoOrientation: CGImagePropertyOrientation, with videoDimensions: CMVideoDimensions) -> CGAffineTransform {
		var transform = CGAffineTransform.identity
		
		// Determine rotation and mirroring from tag value.
		var rotationDegrees = 0
		var mirror = false
		
		switch videoOrientation {
			case .up:				rotationDegrees = 0;	mirror = false
			case .upMirrored:		rotationDegrees = 0;	mirror = true
			case .down:				rotationDegrees = 180;	mirror = false
			case .downMirrored:		rotationDegrees = 180;	mirror = true
			case .left:				rotationDegrees = 270;	mirror = false
			case .leftMirrored:		rotationDegrees = 90;	mirror = true
			case .right:			rotationDegrees = 90;	mirror = false
			case .rightMirrored:	rotationDegrees = 270;	mirror = true
		}
		
		// Build the affine transform.
		var angle: CGFloat = 0.0 // in radians
		var tx: CGFloat = 0.0
		var ty: CGFloat = 0.0
		
		switch rotationDegrees {
			case 90:
				angle = CGFloat(Double.pi / 2.0)
				tx = CGFloat(videoDimensions.height)
				ty = 0.0
				
			case 180:
				angle = CGFloat(Double.pi)
				tx = CGFloat(videoDimensions.width)
				ty = CGFloat(videoDimensions.height)
				
			case 270:
				angle = CGFloat(Double.pi / -2.0)
				tx = 0.0
				ty = CGFloat(videoDimensions.width)
				
			default:
				break
		}
		
		// Rotate first, then translate to bring 0,0 to top left.
		if angle == 0.0 {	// and in this case, tx and ty will be 0.0
			transform = CGAffineTransform.identity
		}
		else {
			transform = CGAffineTransform(rotationAngle: angle)
			transform = transform.concatenating(CGAffineTransform(translationX: tx, y: ty))
		}
		
		// If mirroring, flip along the proper axis.
		if mirror {
			transform = transform.concatenating(CGAffineTransform(scaleX: -1.0, y: 1.0))
			transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(videoDimensions.height), y: 0.0))
		}
		
		return transform
	}
}
