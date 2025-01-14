/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information	
	
	Abstract:
	View controller for camera interface.
*/

import UIKit
import AVFoundation
import CoreLocation
import Photos
import SceneKit
import OSCKit

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, CLLocationManagerDelegate {
 

	
    let server = OSCServer(port: 3333)
    
//    var deviceData: any DeviceDataProtocol = MOSCDeviceData()
    var deviceData: any DeviceDataProtocol = ASDeviceData()

    
    var delegate: DeviceViewControllerDelegate?
    

    private let session = AVCaptureSession()	
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.
    private var setupResult: SessionSetupResult = .success
    private var videoDeviceInput: AVCaptureDeviceInput!

    private let movieFileOutput = AVCaptureMovieFileOutput()
    private var backgroundRecordingID: UIBackgroundTaskIdentifier? = nil

    private var sessionRunningObserveContext = 0
    
    private var locationMetadataInput: AVCaptureMetadataInput?

    //------------------------------------------------------------------

    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet private weak var cameraButton: UIButton!
    @IBOutlet private weak var cameraUnavailableLabel: UILabel!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var resumeButton: UIButton!
    @IBOutlet private weak var playerButton: UIBarButtonItem!

    
//    sohla7
//    !ZXzxzxzx72!
//    
    //------------------------------------------------------------------
	// MARK: View Controller Life Cycle
    //------------------------------------------------------------------

	override func viewDidLoad() {
		super.viewDidLoad()

        
        server.setHandler({ message, timeTag in

            
            self.deviceData.fromOSC(message)
            
//            print(self.deviceData.asOSC().description)
            
            self.delegate?.updateScene(data: self.deviceData)

//            let date = Date()
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSSS a"
//            let result = formatter.string(from: date)
//            print("time: \(result) msg: \(message)")  

            // if we want to send data thru this app
            //self.delegate?.sendOSCMessage()

            if self.movieFileOutput.isRecording {

                if let valString = self.deviceData.toString() {
                    let metadataItem = AVMutableMetadataItem()
                    metadataItem.identifier = AVMetadataIdentifier.quickTimeMetadataLocationISO6709
                    metadataItem.dataType = kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709 as String
                    metadataItem.value = valString as NSString
                    
                    let metadataItemGroup = AVTimedMetadataGroup(items: [metadataItem], timeRange: CMTimeRangeMake(start: CMClockGetTime(CMClockGetHostTimeClock()), duration: CMTime.invalid))
                    do {
                        try self.locationMetadataInput?.append(metadataItemGroup)
                    }
                    catch {
                        print("Could not add timed metadata group: \(error)")
                    }
                }
            }

        })

        
		// Disable UI. The UI is enabled if and only if the session starts running.
		cameraButton.isEnabled = false
		recordButton.isEnabled = false
		
		// Set up the video preview view.
		previewView.session = session
		
		/*
			Check video authorization status. Video access is required and audio
			access is optional. If audio access is denied, audio is not recorded
			during movie recording.
		*/
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
			case .authorized:
				// The user has previously granted access to the camera.
				break
				
			case .notDetermined:
				/*
					The user has not yet been presented with the option to grant
					video access. We suspend the session queue to delay session
					setup until the access request has completed.
				
					Note that audio access will be implicitly requested when we
					create an AVCaptureDeviceInput for audio during session setup.
				*/
				sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) in
					if !granted {
						self.setupResult = .notAuthorized
					}
					self.sessionQueue.resume()
				})
				break
				
			default:
				// The user has previously denied access.
				setupResult = .notAuthorized
				break
		}
		
		/*
			Set up the capture session.
			In general it is not safe to mutate an AVCaptureSession or any of its
			inputs, outputs, or connections from multiple threads at the same time.
		
			Why not do all of this on the main queue?
			Because AVCaptureSession.startRunning() is a blocking call which can
			take a long time. We dispatch session setup to the sessionQueue so
			that the main queue isn't blocked, which keeps the UI responsive.
		*/
		sessionQueue.async {
			self.configureSession()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		sessionQueue.async {
			
			switch self.setupResult {
				case .success:
					// Only set up observers and start running the session if setup succeeded.
					self.addObservers()
                    if(self.session.canSetSessionPreset(.high)) {
                        self.session.sessionPreset = .high
                    }
					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning
                    do {
                        try self.server.start()
                        print("server started")
                    } catch {
                        print(error.localizedDescription)
                    }
				case .notAuthorized:
					DispatchQueue.main.async {
						let message = NSLocalizedString("AVMetadataRecordPlay doesn’t have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
						let alertController = UIAlertController(title: "AVMetadataRecordPlay", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
						alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { _ in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
						}))
						self.present(alertController, animated: true, completion: nil)
					}
					
				case .configurationFailed:
					DispatchQueue.main.async {
						let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
						let alertController = UIAlertController(title: "AVMetadataRecordPlay", message: message, preferredStyle: .alert)
						let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
						alertController.addAction(cancelAction)
						self.present(alertController, animated: true, completion: nil)
					}
			}
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		sessionQueue.async {
			if self.setupResult == .success {
                self.server.stop()
                print("server stopped")
				self.session.stopRunning()
				self.removeObservers()
			}
		}
		
		super.viewDidDisappear(animated)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
			coordinator.animate(alongsideTransition: { _ in
				let interfaceOrientation = UIApplication.shared.statusBarOrientation
				if let videoOrientation = interfaceOrientation.videoOrientation {
					videoPreviewLayerConnection.videoOrientation = videoOrientation
				}
			}, completion: nil)
		}
	}
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "deviceRecorderSegue" {
            let c = segue.destination as! DeviceViewController
            delegate = c
        }
    }

    //------------------------------------------------------------------
	// MARK: Session Management
    //------------------------------------------------------------------

	private enum SessionSetupResult {
		case success
		case notAuthorized
		case configurationFailed
	}

	
	// Call this on the session queue.
	private func configureSession() {
		if setupResult != .success {
			return
		}
		
		session.beginConfiguration()
        
		
		// Add video input.
		do {
			var defaultVideoDevice: AVCaptureDevice?
			
			// Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
				defaultVideoDevice = dualCameraDevice
			}
            else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
				// If the back dual camera is not available, default to the back wide angle camera.
				defaultVideoDevice = backCameraDevice
			}
            else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
				// In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
				defaultVideoDevice = frontCameraDevice
			}
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
			
			if session.canAddInput(videoDeviceInput) {
				session.addInput(videoDeviceInput)
				self.videoDeviceInput = videoDeviceInput
				
				DispatchQueue.main.async {
					/*
						Why are we dispatching this to the main queue?
						Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
						can only be manipulated on the main thread.
						Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
						on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
					
						Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
						handled by CameraViewController.viewWillTransition(to:with:).
					*/
					let statusBarOrientation = UIApplication.shared.statusBarOrientation
					var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
					if statusBarOrientation != .unknown {
						if let videoOrientation = statusBarOrientation.videoOrientation {
							initialVideoOrientation = videoOrientation
						}
					}
					
                    self.previewView.videoPreviewLayer.connection!.videoOrientation = initialVideoOrientation
				}
			}
			else {
				print("Could not add video device input to the session")
				setupResult = .configurationFailed
				session.commitConfiguration()
				return
			}
		}
		catch {
			print("Could not create video device input: \(error)")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}
		
		// Add audio input.
		do {
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
			
			if session.canAddInput(audioDeviceInput) {
				session.addInput(audioDeviceInput)
			}
			else {
				print("Could not add audio device input to the session")
			}
		}
		catch {
			print("Could not create audio device input: \(error)")
		}
		
		// Add movie file output.
		if session.canAddOutput(movieFileOutput) {
			session.addOutput(movieFileOutput)
			
            if let movieFileOutputVideoConnection = movieFileOutput.connection(with: AVMediaType.video) {
				// Enable video video stabilization.
				if movieFileOutputVideoConnection.isVideoStabilizationSupported {
					movieFileOutputVideoConnection.preferredVideoStabilizationMode = .auto
				}
				
				// Enable video orientation timed metadata.
                movieFileOutput.setRecordsVideoOrientationAndMirroringChangesAsMetadataTrack(true, for: movieFileOutputVideoConnection)
			}
		}
		else {
			print("Could not add movie file output to the session")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}
		
		// Make connections between all metadataInputPorts and the session.
		self.connectMetadataPorts()
		
		self.session.commitConfiguration()
	}
	
	@IBAction func resumeInterruptedSession(_ resumeButton: UIButton) {
		sessionQueue.async {
			/*
				The session might fail to start running, e.g., if a phone or FaceTime call is still
				using audio or video. A failure to start the session running will be communicated via
				a session runtime error notification. To avoid repeatedly failing to start the session
				running, we only try to restart the session running in the session runtime error handler
				if we aren't trying to resume the session running.
			*/
			self.session.startRunning()
			self.isSessionRunning = self.session.isRunning
			if !self.session.isRunning {
				DispatchQueue.main.async {
					let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
					let alertController = UIAlertController(title: "AVMetadataRecordPlay", message: message, preferredStyle: .alert)
					let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
					alertController.addAction(cancelAction)
					self.present(alertController, animated: true, completion: nil)
				}
			}
			else {
				DispatchQueue.main.async {
					self.resumeButton.isHidden = true
				}
			}
		}
	}
	
    //------------------------------------------------------------------
	// MARK: Device Configuration
    //------------------------------------------------------------------

    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .unspecified)
	
	@IBAction func changeCamera(_ cameraButton: UIButton) {
		cameraButton.isEnabled = false
		recordButton.isEnabled = false
		
		sessionQueue.async {
			let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
			
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
			
			switch currentPosition {
				case .unspecified, .front:
					preferredPosition = .back
					preferredDeviceType = .builtInDualCamera
					
				case .back:
					preferredPosition = .front
					preferredDeviceType = .builtInWideAngleCamera
			}
			
            let devices = self.videoDeviceDiscoverySession.devices
			var newVideoDevice: AVCaptureDevice? = nil
			
			// First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
			if let device = devices.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
				newVideoDevice = device
			}
			else if let device = devices.filter({ $0.position == preferredPosition }).first {
				newVideoDevice = device
			}
			
			if let videoDevice = newVideoDevice {
				do {
					let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
					self.session.beginConfiguration()
					
					// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
					self.session.removeInput(self.videoDeviceInput)
					
					if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
						
						NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: Notification.Name.AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
						
						self.session.addInput(videoDeviceInput)
						self.videoDeviceInput = videoDeviceInput
					}
					else {
						self.session.addInput(self.videoDeviceInput);
					}
					
					// Rewire connections for metadata tracks because we swapped out videoDeviceInput for a new one.
					self.connectMetadataPorts()
					
                    if let movieFileOutputVideoConnection = self.movieFileOutput.connection(with: AVMediaType.video) {
						// Enable video video stabilization.
						if movieFileOutputVideoConnection.isVideoStabilizationSupported {
							movieFileOutputVideoConnection.preferredVideoStabilizationMode = .auto
						}
						
						// Enable video orientation timed metadata.
                        self.movieFileOutput.setRecordsVideoOrientationAndMirroringChangesAsMetadataTrack(true, for: movieFileOutputVideoConnection)
					}
					
					self.session.commitConfiguration()
				}
				catch {
					print("Error occurred while creating video device input: \(error)")
				}
			}
			
			DispatchQueue.main.async {
				self.recordButton.isEnabled = true
				self.cameraButton.isEnabled = true
			}
		}
	}
	
	@IBAction private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = self.previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
		focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
	}
	
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
		sessionQueue.async { [unowned self] in
			if let device = self.videoDeviceInput?.device {
				do {
					try device.lockForConfiguration()
					
					/*
						Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
						Call set(Focus/Exposure)Mode() to apply the new point of interest.
					*/
					if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
						device.focusPointOfInterest = devicePoint
						device.focusMode = focusMode
					}
					
					if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
						device.exposurePointOfInterest = devicePoint
						device.exposureMode = exposureMode
					}
					
					device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
					device.unlockForConfiguration()
				}
				catch {
					print("Could not lock device for configuration: \(error)")
				}
			}
		}
	}
	
    //------------------------------------------------------------------
	// MARK: Recording Movies
    //------------------------------------------------------------------
 
	
	@IBAction private func toggleMovieRecording(_ recordButton: UIButton) {
		/*
			Disable the Camera button until recording finishes, and disable
			the Record and Player buttons until recording starts or finishes.
			
			See the AVCaptureFileOutputRecordingDelegate methods.
		*/
		cameraButton.isEnabled = false
		recordButton.isEnabled = false
		playerButton.isEnabled = false
		
		/*
			Retrieve the video preview layer's video orientation on the main queue
			before entering the session queue. We do this to ensure UI elements are
			accessed on the main thread and session configuration is done on the session queue.
		*/
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
		
		sessionQueue.async { [unowned self] in
			if !self.movieFileOutput.isRecording {
				// Begin location updates.
				//self.locationManager.startUpdatingLocation()
				
				if UIDevice.current.isMultitaskingSupported {
					/*
						Set up background task.
						This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
						callback is not received until AVCam returns to the foreground unless you request background execution time.
						This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
						To conclude this background execution, endBackgroundTask(_:) is called in
						`capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)` after the recorded file has been saved.
					*/
					self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
				}
				
				// Update the orientation on the movie file output video connection before starting recording.
                let movieFileOutputConnection = self.movieFileOutput.connection(with: AVMediaType.video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
				
				// Start recording to a temporary file.
				let outputFileName = NSUUID().uuidString
				let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                self.movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
			}
			else {
				self.movieFileOutput.stopRecording()
				//self.locationManager.stopUpdatingLocation()
			}
		}
	}
	
    @IBAction func onOSCButton(_ sender: Any) {
    
        // tell the delegate
//        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OSCViewControllerID")
//        let popup = PopupDialog(viewController: vc)
//
//        self.present(popup, animated: true) {
//            
//        }
    }
    
    @IBAction func onResetButton(_ sender: Any) {
    

//        if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
//            if let port = UserDefaults.standard.string(forKey: "portAddress"){
                
//                let address = "udp://"+ip+":"+port
                
//                let msg: OSCMessage = OSCMessage(address: "/bounce", arguments: ["motionReset"])
//                //•• SET ADDRESS and PORT of the touch device you want to reset NOT TESTED
//                CameraViewController.client.send(msg, to: address)

//            }
//        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
//    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
		// Enable the Record button to let the user stop the recording.
		DispatchQueue.main.async {
			self.recordButton.isEnabled = true;
			self.recordButton.setTitle(NSLocalizedString("Stop", comment: "Recording button stop title"), for: [])
		}
	}
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?){
//    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
		/*
			Note that currentBackgroundRecordingID is used to end the background task
			associated with this recording. This allows a new recording to be started,
			associated with a new UIBackgroundTaskIdentifier, once the movie file output's
			`isRecording` property is back to false — which happens sometime after this method
			returns.
			
			Note: Since we use a unique file path for each recording, a new recording will
			not overwrite a recording currently being saved.
		*/
		func cleanUp() {
			let path = outputFileURL.path
			if FileManager.default.fileExists(atPath: path) {
				do {
					try FileManager.default.removeItem(atPath: path)
				}
				catch {
                    print("Could not remove file at url: \(String(describing: outputFileURL))")
				}
			}
			
			if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
				
                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
					UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
				}
			}
		}
		
		var success = true
		
		if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
		}
		
		if success {
			// Check authorization status.
			PHPhotoLibrary.requestAuthorization { status in
				if status == .authorized {
					// Save the movie file to the photo library and clean up.
					PHPhotoLibrary.shared().performChanges({
							// In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
							// This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
							let creationOptions = PHAssetResourceCreationOptions()
							creationOptions.shouldMoveFile = true
						
							let creationRequest = PHAssetCreationRequest.forAsset()
							creationRequest.addResource(with: .video, fileURL: outputFileURL, options: creationOptions)
						}, completionHandler: { success, error in
							if !success {
								print("Could not save movie to photo library: \(String(describing: error))")
							}
							cleanUp()
						}
					)
				}
				else {
					cleanUp()
				}
			}
		}
		else {
			cleanUp()
		}
		
		// Enable the Camera and Record buttons to let the user switch camera and start another recording.
		DispatchQueue.main.async {
			// Only enable the ability to change camera if there are cameras in more than one position, i.e., front and back.
			self.cameraButton.isEnabled = self.videoDeviceDiscoverySession.uniqueDevicePositionsCount() > 1
			self.recordButton.isEnabled = true
			self.playerButton.isEnabled = true
			self.recordButton.setTitle(NSLocalizedString("Record", comment: "Recording button record title"), for: [])
		}
	}
	
    //------------------------------------------------------------------
	// MARK: Metadata Support
    //------------------------------------------------------------------

	
	private func connectMetadataPorts() {
		// Location metadata
        if !isConnectionActiveWithInputPort(AVMetadataIdentifier.quickTimeMetadataLocationISO6709.rawValue) {
			// Create a format description for the location metadata.
            let specs = [kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String: AVMetadataIdentifier.quickTimeMetadataLocationISO6709,
                         kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String: kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709 as String] as [String : Any] as [String : Any]
			
			var locationMetadataDesc: CMFormatDescription?
            CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [specs] as CFArray, formatDescriptionOut: &locationMetadataDesc)
			
			// Create the metadata input and add it to the session.
            let newLocationMetadataInput = AVCaptureMetadataInput(formatDescription: locationMetadataDesc!, clock: CMClockGetHostTimeClock())
			session.addInputWithNoConnections(newLocationMetadataInput)
			
			// Connect the location metadata input to the movie file output.
			let inputPort = newLocationMetadataInput.ports[0]
            session.addConnection(AVCaptureConnection(inputPorts: [inputPort], output: movieFileOutput))
			print("location input added to movieFileOutput")
			locationMetadataInput = newLocationMetadataInput
		}
		
	}

	
	/**
		Iterates through all the movieFileOutput’s connections and returns true if the
		input port for one of the connections matches portType.
	*/
	private func isConnectionActiveWithInputPort(_ portType: String) -> Bool {
		
        for connection in movieFileOutput.connections {
            for inputPort in connection.inputPorts {
				if let formatDescription = inputPort.formatDescription, CMFormatDescriptionGetMediaType(formatDescription) == kCMMediaType_Metadata {
                    if let metadataIdentifiers = CMMetadataFormatDescriptionGetIdentifiers(inputPort.formatDescription!) as NSArray? {
						print(metadataIdentifiers)
						if metadataIdentifiers.contains(portType) {
							return connection.isActive
						}
					}
				}
			}
		}
		
		return false
	}
	
    //------------------------------------------------------------------
	// MARK: KVO and Notifications
    //------------------------------------------------------------------

	private func addObservers() {
		session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
		
		NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange),name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput?.device)
		NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError),name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
		
		/*
			A session can only run when the app is full screen. It will be interrupted
			in a multi-app layout, introduced in iOS 9, see also the documentation of
			AVCaptureSessionInterruptionReason. Add observers to handle these session
			interruptions and show a preview is paused message. See the documentation
			of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
		*/
		NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
		NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
		
		// Listen for device orientation changes so keep the video orientation metadata capture connection's orientation up-to-date
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
	}
	
	private func removeObservers() {
		NotificationCenter.default.removeObserver(self)
		
		session.removeObserver(self, forKeyPath: "running", context: &sessionRunningObserveContext)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		if context == &sessionRunningObserveContext {
			guard let isSessionRunning = change?[.newKey] as? Bool else { return }
			
			DispatchQueue.main.async {
				// Only enable the ability to change camera if there are cameras in more than one position, i.e., front and back.
				self.cameraButton.isEnabled = isSessionRunning && self.videoDeviceDiscoverySession.uniqueDevicePositionsCount() > 1
				self.recordButton.isEnabled = isSessionRunning
			}
			
		}
		else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
    @objc func subjectAreaDidChange(_ notification: Notification) {
		let devicePoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
		focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
	}
	
    @objc func sessionRuntimeError(notification: NSNotification) {
		guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
			return
		}
		
		let error = AVError(_nsError: errorValue)
		print("Capture session runtime error: \(error)")
		
		/*
			Automatically try to restart the session running if media services were
			reset and the last start running succeeded. Otherwise, enable the user
			to try to resume the session running.
		*/
		if error.code == .mediaServicesWereReset {
			sessionQueue.async { [unowned self] in
				if self.isSessionRunning {
					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning
				}
				else {
					DispatchQueue.main.async { [unowned self] in
						self.resumeButton.isHidden = false
					}
				}
			}
		}
		else {
			resumeButton.isHidden = false
		}
	}
	
    @objc func sessionWasInterrupted(notification: NSNotification) {
		/*
			In some scenarios we want to enable the user to resume the session running.
			For example, if music playback is initiated via control center while
			using AVMetadataRecordPlay, then the user can let AVMetadataRecordPlay resume
			the session running, which will stop music playback. Note that stopping
			music playback in control center will not automatically resume the session
			running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
		*/
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
			print("Capture session was interrupted with reason \(reason)")
			
            if reason == AVCaptureSession.InterruptionReason.audioDeviceInUseByAnotherClient || reason == AVCaptureSession.InterruptionReason.videoDeviceInUseByAnotherClient {
				// Simply fade-in a button to enable the user to try to resume the session running.
				resumeButton.alpha = 0
				resumeButton.isHidden = false
				UIView.animate(withDuration: 0.25) { [unowned self] in
					self.resumeButton.alpha = 1
				}
			}
            else if reason == AVCaptureSession.InterruptionReason.videoDeviceNotAvailableWithMultipleForegroundApps {
				// Simply fade-in a label to inform the user that the camera is unavailable.
				cameraUnavailableLabel.alpha = 0
				cameraUnavailableLabel.isHidden = false
				UIView.animate(withDuration: 0.25) { [unowned self] in
					self.cameraUnavailableLabel.alpha = 1
				}
			}
		}
	}
	
    @objc func sessionInterruptionEnded(notification: NSNotification) {
		print("Capture session interruption ended")
		
		if !resumeButton.isHidden {
			UIView.animate(withDuration: 0.25,
				animations: { [unowned self] in
					self.resumeButton.alpha = 0
				}, completion: { [unowned self] finished in
					self.resumeButton.isHidden = true
				}
			)
		}
		if !cameraUnavailableLabel.isHidden {
			UIView.animate(withDuration: 0.25,
				animations: { [unowned self] in
					self.cameraUnavailableLabel.alpha = 0
				}, completion: { [unowned self] finished in
					self.cameraUnavailableLabel.isHidden = true
				}
			)
		}
	}
	
    @objc func deviceOrientationDidChange() {
		// Update capture orientation based on device orientation (if device orientation is one that
		// should affect capture, i.e. not face up, face down, or unknown)
		let deviceOrientation = UIDevice.current.orientation
		if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
			if let videoOrientation = deviceOrientation.videoOrientation {
                movieFileOutput.connection(with: AVMediaType.video)!.videoOrientation = videoOrientation
			}
		}
	}
}

extension UIDeviceOrientation {
	var videoOrientation: AVCaptureVideoOrientation? {
		switch self {
			case .portrait: return .portrait
			case .portraitUpsideDown: return .portraitUpsideDown
			case .landscapeLeft: return .landscapeRight
			case .landscapeRight: return .landscapeLeft
			default: return nil
		}
	}
}

extension UIInterfaceOrientation {
	var videoOrientation: AVCaptureVideoOrientation? {
		switch self {
			case .portrait: return .portrait
			case .portraitUpsideDown: return .portraitUpsideDown
			case .landscapeLeft: return .landscapeLeft
			case .landscapeRight: return .landscapeRight
			default: return nil
		}
	}
}

extension AVCaptureDevice.DiscoverySession {
	func uniqueDevicePositionsCount() -> Int {
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
		
		for device in devices {
			if !uniqueDevicePositions.contains(device.position) {
				uniqueDevicePositions.append(device.position)
			}
		}
		
		return uniqueDevicePositions.count
	}
}


