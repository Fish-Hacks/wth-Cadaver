//
//  CameraPreview.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 26/8/23.
//

import Foundation
import Vision
import AVFoundation
import UIKit
import CoreBluetooth
import OSLog

enum GTSState {
    /// Read off sentence
    case normal
    
    /// Detected context items
    case contextExpanded
    
    /// Using hand to point and read
    case pointer
}

final class CameraPreview: UIView {

    var shutDownVision = false
    
    var gtsState = GTSState.normal {
        didSet {
            print("GTS: \(gtsState)")
        }
    }
    var latestCVResponse: CVResponse?
    
    /// Set up `AVCaptureSession`
    private let captureSession = AVCaptureSession()
    
    /// Set up video output
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var photoOutput = AVCapturePhotoOutput()
    
    var communicationService = CommunicationService()
    
    var speechService = SpeechService()
    
    var handClassifier = HandService()
    var textService = TextService()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCaptureSession()
        setUpCentral()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCaptureSession()
    }

    /// Get camera size
    var size: CGSize!
    
    /// Set up AVCaptureSession
    ///
    /// - Create capture device
    /// - Set up with inputs
    /// - Set up camera preview layer
    private func setupCaptureSession() {
        captureSession.beginConfiguration()

        guard let captureDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
              let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
              captureSession.canAddInput(captureDeviceInput) else { fatalError() }
        
        size = CGSize(width: CGFloat(captureDevice.activeFormat.supportedMaxPhotoDimensions.first!.width),
                      height: CGFloat(captureDevice.activeFormat.supportedMaxPhotoDimensions.first!.height))

        captureSession.addInput(captureDeviceInput)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        captureSession.addOutput(photoOutput)

        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .utility).async {
            self.captureSession.startRunning()
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            self.takePhoto()
        }
        
        handClassifier.delegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let previewLayer = layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = bounds
        }
    }
    
    func takePhoto() {
        
        print("Attempt take photo")
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var transferCharacteristic: CBCharacteristic?
}

extension CameraPreview: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
            retrievePeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch central.authorization {
                case .denied:
                    os_log("You are not authorized to use Bluetooth")
                case .restricted:
                    os_log("Bluetooth is restricted")
                default:
                    os_log("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown central manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        os_log("Discovered %s at %d", String(describing: peripheral.name), RSSI.intValue)
        
        // Device is in range - have we already seen it?
        if discoveredPeripheral != peripheral {
            
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it.
            discoveredPeripheral = peripheral
            
            // And finally, connect to the peripheral.
            os_log("Connecting to perhiperal %@", peripheral)
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("Peripheral Connected")
        
        // Stop scanning
        centralManager.stopScan()
        os_log("Scanning stopped")
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([TransferService.serviceUUID])
    }
    
    func setUpCentral() {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    private func retrievePeripheral() {
        
        let connectedPeripherals: [CBPeripheral] = (centralManager.retrieveConnectedPeripherals(withServices: [TransferService.serviceUUID]))
        
        os_log("Found connected Peripherals with transfer service: %@", connectedPeripherals)
        
        if let connectedPeripheral = connectedPeripherals.last {
            os_log("Connecting to peripheral %@", connectedPeripheral)
            self.discoveredPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
        } else {
            // We were not connected to our counterpart, so start scanning
            centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
}

extension CameraPreview: CBPeripheralDelegate {
    // implementations of the CBPeripheralDelegate methods
    
    /*
     *  The peripheral letting us know when services have been invalidated.
     */
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for service in invalidatedServices where service.uuid == TransferService.serviceUUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([TransferService.serviceUUID])
        }
    }
    
    /*
     *  The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error discovering services: %s", error.localizedDescription)
            return
        }
        
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }
    }
    
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any).
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            return
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            // If it is, subscribe to it
            transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
        
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            return
        }
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        let splitData = stringFromData.split(separator: ":")
        
        let id = Int(splitData[0])!
        
        let receivedData = DataToReceive(rawValue: id, string: String(splitData[1]))
        
        switch receivedData {
        case .shutDownVision:
            shutDownVision = true
        case .enableVision:
            shutDownVision = false
        case .simulatePointRead(let string):
            gtsState = .pointer
            speechService.dictatedText(text: "Text: \(string)")
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [self] _ in
                gtsState = .normal
                
                // allow classifier to redetect after 1 second
                handClassifier.previousDetection = .neither
            }
        case .simulateTap(let string):
            gtsState = .contextExpanded
            
            // within the frame, find all text
            speechService.dictatedText(text: "Text: \(string)")
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [self] _ in
                gtsState = .normal
                
                // allow classifier to redetect after 1 second
                handClassifier.previousDetection = .neither
            }
        case .resetToNormal:
            guard let latestCVResponse else { return }
            gtsState = .normal
            speechService.dictatedText(text: latestCVResponse.sceneDescription)
        case .none:
            break
        }
        
        os_log("Received %d bytes: %s", characteristicData.count, stringFromData)
    }
    
    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == TransferService.characteristicUUID else { return }
        
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic)
        }
        
    }
    
    /*
     *  This is called when peripheral is ready to accept more data when using write without response
     */
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        os_log("Peripheral is ready, send data")
    }
    
}

extension CameraPreview: HandServiceDelegate {
    func didReceiveHand(_ handState: HandState) {
        guard !shutDownVision else { return }
        
        switch handState {
        case .pointing(let point):
            gtsState = .pointer
            print("POINTING")
            for result in textService.results {
                print(result.topCandidates(1).first!.string)
                print(CGPoint(x: result.boundingBox.midX, y: result.boundingBox.midY).distance(from: point))
            }
            
            let candidateObservations = textService.results.filter { observation in
                observation.boundingBox.contains(point) || CGPoint(x: observation.boundingBox.midX, y: observation.boundingBox.midY).distance(from: point) < 0.3
            }
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [self] _ in
                gtsState = .normal
                
                // allow classifier to redetect after 1 second
                handClassifier.previousDetection = .neither
            }
            
            if candidateObservations.isEmpty {
                speechService.dictatedText(text: "Nothing to read.")
            } else {
                for observation in candidateObservations {
                    guard let text = observation.topCandidates(1).first?.string else { continue }
                    
                    speechService.dictatedText(text: "Text: \(text)")
                }
            }
        case .tapping:
            guard let latestCVResponse, gtsState == .normal,
                  let contextCoordinate = latestCVResponse.contextCoordinate else { return }
            
            gtsState = .contextExpanded
                
            // within the frame, find all text
            let candidateObservations = textService.results.filter { observation in
                contextCoordinate.intersects(observation.boundingBox)
            }
            
            if candidateObservations.isEmpty {
                speechService.dictatedText(text: "Nothing to expand into.")
            } else {
                for observation in candidateObservations {
                    guard let text = observation.topCandidates(1).first?.string else { continue }
                    
                    speechService.dictatedText(text: "Text: \(text)")
                }
            }
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [self] _ in
                gtsState = .normal
                
                // allow classifier to redetect after 1 second
                handClassifier.previousDetection = .neither
            }
        case .neither: break
        }
    }
}

extension CameraPreview: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        print("OUT")
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else if let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData)?.fixOrientation() {
            Task {
                let cvResponse = await communicationService.sendImageForProcessing(imageData: image.jpegData(compressionQuality: 0.8)!)
                
                await MainActor.run { [self] in
                    
                    print("HELLP")
                    
                    if gtsState == .normal {
                        print("attempt to server")
                        speechService.dictatedText(text: cvResponse.sceneDescription)
                        latestCVResponse = cvResponse
                    }
                }
            }
        }
    }
}
