//
//  realTimeDetector.swift
//  caffe2-ios
//
//  Created by Kaiwen Yuan on 2017-04-29.
//  Copyright © 2017 Kaiwen Yuan. All rights reserved.
//


import UIKit
import AVFoundation

class realTimeDetectorVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var avg_fps = 0.0
    var total_fps = 0.0
    let iters_fps = 10.0
    var fps = ""
    
    var currentRow: NSInteger = 0;
    var itemsDataSource = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14"]
//    var resImg = UIImage()
    
    let foundNilErrorMsg = "[Error] Thrown \n"
    let processingErrorMsg = "[Error] Processing Error \n"
    var result = ""
    var memUsage = 0 as Float
    var elapse = ""
    var showMask: Bool = false
    var showContour: Bool = false
    var showDetails: Bool = false
    
    let semaphore = DispatchSemaphore(value: 1)

    var H = 241
    var W = 181
    
    @IBOutlet weak var resultDisplayer: UITextView!
    @IBOutlet weak var memUsageDisplayer: UITextView!
    @IBOutlet weak var resultImage: UIImageView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var settings: UIView!
    @IBOutlet weak var arrawBtn: UIButton!
    @IBOutlet weak var filterMarginBottom: NSLayoutConstraint!
    @IBOutlet weak var inputSizeLabel: UILabel!
    @IBOutlet weak var speedSlider: UISlider!
    
    @IBAction func onSliderValueChanged(_ sender: UISlider) {
//        inputSizeLabel.text = String(Int(sender.value))
//        semaphore.wait()
        self.H = Int((sender.value + 2) / 4) * 4 + 1
        inputSizeLabel.text = String(self.H)
        self.W = self.H
//        semaphore.signal()
    }
    
    @IBAction func onSliderTouchUpInside(_ sender: UISlider) {
        semaphore.wait()
        self.H = Int(sender.value)
        inputSizeLabel.text = String(self.H)
        self.W = self.H
        semaphore.signal()
    }

    @IBAction func onSliderTouchUpOutside(_ sender: UISlider) {
        semaphore.wait()
        self.H = Int(sender.value)
        inputSizeLabel.text = String(self.H)
        self.W = self.H
        semaphore.signal()
    }
    
    @IBAction func onDrawContour(_ sender: UIButton) {
        self.showContour = !self.showContour
    }

    @IBAction func clickShowMaskBtn(_ sender: UIButton) {
        self.showMask = !self.showMask;
    }

    
    enum CommonError: Error{
        case FoundNil(String)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCameraSession()
        
        self.view.addSubview(self.settings);
        self.view.bringSubview(toFront:self.settings)
        self.settings.isHidden = true
        self.settings.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(realTimeDetectorVC.settingViewClick)))
        
        self.filterMarginBottom.constant = -self.collectionView.frame.size.height
      
        print("Initializing ...")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraSession.startRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraSession.stopRunning()
    }
    
    func getMemory()
    {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info))/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info)
        {
            
            task_info(mach_task_self_,
                      task_flavor_t(MACH_TASK_BASIC_INFO),
                      $0.withMemoryRebound(to: Int32.self, capacity: 1) { zeroPtr in
                        task_info_t(zeroPtr)
                },
                      &count)
            
        }
        
        if kerr == KERN_SUCCESS {
            print("Memory in use (in bytes): \(info.resident_size)")
            self.memUsage = Float(info.resident_size)/(1024 * 1024)
        }
        else {
            print("Error with task_info(): " +
                (String.init(validatingUTF8: mach_error_string(kerr)) ?? "unknown error"))
        }
    }
    
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetHigh
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        preview?.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        preview?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        preview?.videoGravity = AVLayerVideoGravityResize
        return preview!
    }()
    
    func setupCameraSession() {
        let frontCamera = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)

        do {
            let deviceInput = try AVCaptureDeviceInput(device: frontCamera)
            
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(deviceInput) == true) {
                cameraSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
//            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]

            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession.canAddOutput(dataOutput) == true) {
                cameraSession.addOutput(dataOutput)
            }
            
            cameraSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.invasivecode.videoQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }
        catch let error as NSError {
            print("\(error), \(error.localizedDescription)")
        }
    }
    
    
    func segmentation(img: UIImage, height: Int, width: Int) -> UIImage {


        var resImg = img
        
        let bgra = CVWrapper.preprocessImage(img, flip: true, height: height, width: width)
        
        if let predictedResult = caffe.prediction(regarding: bgra){
            
            let background: UIImage = UIImage(named: itemsDataSource[currentRow])!
            
            let start = CACurrentMediaTime() //CFAbsoluteTimeGetCurrent()

            
            resImg = CVWrapper.postprocessImage(predictedResult, image: img, background: background, flip: true, showMask: self.showMask, showContour: self.showContour, height: height, width: width)
            
            let end = CACurrentMediaTime()
            let fps = 1.0/(end-start)
            total_fps += fps
            avg_fps = total_fps / iters_fps
            total_fps -= avg_fps;
            
            self.fps = "\(end-start) s (\(avg_fps) FPS )"

            self.getMemory()
        }
        

        return resImg
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer
        sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//        semaphore.wait()
        let img = sampleBuffer.image()
        var resImg = img
        
        resImg = self.segmentation(img: img!, height: self.H, width: self.W)
//        semaphore.signal()

        // Force UI work to be done in main thread
        DispatchQueue.main.async(execute: {
        if self.showDetails {
            self.memUsageDisplayer.text = "Memory usage: \(self.memUsage) MB \nSpeed: \(self.fps)"
            
        } else {
            self.memUsageDisplayer.text = ""
        }

        self.resultImage.image = resImg


        })
        

    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Here you can count how many frames are dopped
    }
  
   
}

//MARK:-事件处理
extension realTimeDetectorVC {
    
    @objc func settingViewClick() {
        self.settings.isHidden = true
    }
    
    @IBAction func moreBtnClick(_ sender: AnyObject) {
        self.settings.isHidden = false
    }
    
    @IBAction func arrawBtnClick(_sender: UIButton) {
        toggleFilter()
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        swapCamera()
    }
    
    @IBAction func maskSwitchValueDidChange(sender:UISwitch!) {
       self.showMask = sender.isOn
    }
    
    @IBAction func contourSwitchValueDidChange(sender:UISwitch!) {
        self.showContour = sender.isOn
    }
    
    @IBAction func detailsSwitchValueDidChange(sender:UISwitch!) {
        self.showDetails = sender.isOn
    }
    
    @IBAction func speedSliderValueDidChange(sender:UISlider!) {
          NSLog("\(sender.value)"  , "")
    }
    
}

extension realTimeDetectorVC {
    
   fileprivate func toggleFilter(){
        if self.filterMarginBottom.constant == 0 {
            
            UIView.animate(withDuration: 0.25, animations: {
            self.filterMarginBottom.constant = -self.collectionView.frame.size.height
            self.view.layoutIfNeeded()
            }, completion: { (Bool) in
                self.arrawBtn.setImage(UIImage(named:"arrow_top"), for: .normal)
            })
            
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.filterMarginBottom.constant = 0
                self.view.layoutIfNeeded()
            }, completion: { (Bool) in
                self.arrawBtn.setImage(UIImage(named:"arrow_down"), for: .normal)
            })
            
        }
       
    }

}

extension realTimeDetectorVC {
    /// Swap camera and reconfigures camera session with new input
    fileprivate func swapCamera() {
        
        // Get current input
        guard let input = cameraSession.inputs[0] as? AVCaptureDeviceInput else { return }
        
        // Begin new session configuration and defer commit
        cameraSession.beginConfiguration()
        defer { cameraSession.commitConfiguration() }
        
        // Create new capture device
        var newDevice: AVCaptureDevice?
        if input.device.position == .back {
            newDevice = captureDevice(with: .front)
        } else {
            newDevice = captureDevice(with: .back)
        }
        
        // Create new capture input
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: newDevice)
        } catch let error {
            print(error.localizedDescription)
            return
        }
        
        // Swap capture device inputs
        cameraSession.removeInput(input)
        cameraSession.addInput(deviceInput)
    }
    
    /// Create new capture device with requested position
    fileprivate func captureDevice(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [ .builtInWideAngleCamera, .builtInMicrophone, .builtInDualCamera, .builtInTelephotoCamera ], mediaType: AVMediaTypeVideo, position: .unspecified).devices
        
        if let devices = devices {
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        }
        
        return nil
    }
    
}

extension realTimeDetectorVC: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.itemsDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sceneCell", for: indexPath) as! sceneCell
        
        cell.iconView.image = UIImage(named: itemsDataSource[indexPath.row])
        
        if currentRow == indexPath.row {
            
        } else {
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentRow = indexPath.row
//        collectionView.reloadData()
    }

}

extension CMSampleBuffer {
    func image(orientation: UIImageOrientation = .up, scale: CGFloat = 1.0) -> UIImage! {
        guard let buffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        let image = UIImage(ciImage: ciImage, scale: scale, orientation: orientation)
        
        let resizedImg = resizeBufferImage(image: image, widthRatio: CGFloat(500 / image.size.width), heightRatio: CGFloat(1))
        
        return resizedImg
    }
    
    func resizeBufferImage(image: UIImage, widthRatio: CGFloat, heightRatio: CGFloat) -> UIImage {
        let size = image.size
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

