//
//  vedioSegmentationVC.swift
//  caffe2-ios
//
//  Created by Cloudream on 23/06/2017.
//
//

import UIKit
import AVFoundation

class videoSegmentationVC: UIViewController {

    var avg_fps = 0.0
    var total_fps = 0.0
    let iters_fps = 10.0
    var fps = ""
    
    let foundNilErrorMsg = "[Error] Thrown \n"
    let processingErrorMsg = "[Error] Processing Error \n"
    var result = ""
    var memUsage = 0 as Float
    var elapse = ""
    var generator: AVAssetImageGenerator?
    var showMask: Bool = false
    
    @IBOutlet weak var resultDisplayer: UITextView!
    @IBOutlet weak var memUsageDisplayer: UITextView!
    @IBOutlet weak var resultImage: UIImageView!
    
    @IBAction func clickShowMaskBtn(_ sender: UIButton) {
        self.showMask = !self.showMask;
        captureFrame(timeInSeconds: Float64(15))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //view.layer.addSublayer(previewLayer)
        self.view.addSubview(self.resultDisplayer)
        self.view.addSubview(self.memUsageDisplayer)
        
        self.view.addSubview(self.resultImage)
        
        self.view.bringSubview(toFront: self.resultDisplayer)
        self.view.bringSubview(toFront: self.memUsageDisplayer)
        // implementation
        
        let path = Bundle.main.path(forResource: "WIN_20170417_10_19_42_Pro", ofType: "mp4")
        let url = URL(fileURLWithPath: path!) as NSURL
        let asset = AVAsset(url: url as URL)
        self.generator = AVAssetImageGenerator(asset: asset)
        self.generator?.appliesPreferredTrackTransform = true
        self.generator?.requestedTimeToleranceAfter = kCMTimeZero
        self.generator?.requestedTimeToleranceBefore = kCMTimeZero
        
        let mutableVideoDuration = Int(CMTimeGetSeconds(asset.duration))
//        for t in 0..<mutableVideoDuration {
            captureFrame(timeInSeconds: Float64(15))
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    
    func segmentation(img: UIImage) -> UIImage {
        //        let tmp = img.cgImage
        //        let W = tmp?.width
        //        let H = tmp?.height
        
        let bgra = CVWrapper.preprocessImage(img, flip: false)
        var resImg = img
        
        let start = CACurrentMediaTime() //CFAbsoluteTimeGetCurrent()
        if let predictedResult = caffe.prediction(regarding: bgra){
            let end = CACurrentMediaTime()
            let fps = 1.0/(end-start)
            total_fps += fps
            avg_fps = total_fps / iters_fps
            total_fps -= avg_fps;
            
            self.fps = "\(end-start) s (\(avg_fps) FPS )"
            
            switch modelPicked {
            case "originalNet":
                let background: UIImage = UIImage(named: "timg")!
                resImg = CVWrapper.postprocessImage(predictedResult, image: img, background: background, flip: false, showMask: self.showMask)
            case "tinyYolo":
                resImg = CVWrapper.drawBBox(predictedResult, image: img)
            default:
                print("Result is \n\(predictedResult)")
                self.result = "\(predictedResult)"
            }
            self.getMemory()
        }
        
        
        return resImg
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
    
    func finshedCapture(im: CGImage?) {
        if let cgimg = im {
            print("OK")
            let img = UIImage(cgImage: cgimg)
            let resImg = self.segmentation(img: img)
            DispatchQueue.main.async(execute:{
                self.memUsageDisplayer.text = "Memory usage: \(self.memUsage) MB \nFPS: \(self.fps) \nModel: \(modelPicked)"
                self.resultImage.image = resImg
            })
        }else{
            print("Fail")
        }

    }
    

    // MARK: THANKS TO: http://stackoverflow.com/questions/4001755/trying-to-understand-cmtime-and-cmtimemake
    func captureFrame(url:NSURL, timeInSeconds time:Float64) {
        let generator = AVAssetImageGenerator(asset: AVAsset(url: url as URL))
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = kCMTimeZero;
        generator.requestedTimeToleranceBefore = kCMTimeZero;
        //        let tVal = NSValue(time: CMTimeMake(time, 1))
        let tVal = CMTimeMakeWithSeconds(time, 600)
        generator.generateCGImagesAsynchronously(forTimes: [tVal as NSValue], completionHandler: {(_, im:CGImage?, _, _, _) in self.finshedCapture(im: im)})
    }
    
    // MARK: THANKS TO: http://stackoverflow.com/questions/4001755/trying-to-understand-cmtime-and-cmtimemake
    func captureFrame(timeInSeconds time:Float64) {
//        let tVal = NSValue(time: CMTimeMake(time, 1))
        let tVal = CMTimeMakeWithSeconds(time, 600)
        if let generator = self.generator{
            do {
                let img: CGImage = try generator.copyCGImage(at: tVal, actualTime: nil)
                self.finshedCapture(im: img)
            } catch{
                print("fail to grab frame.")
            }
//            generator.generateCGImagesAsynchronously(forTimes: [tVal as NSValue], completionHandler: {(_, im:CGImage?, _, _, _) in self.finshedCapture(im: im)})
        } else {
            print("generator is nil")
        }
    }
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
