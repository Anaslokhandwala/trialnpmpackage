import Foundation
import UIKit
import AccuraOCR

struct lvfm {
    static var face1: UIImage? = nil
    static var face2: UIImage? = nil
    static var face1Detect: NSFaceRegion? = nil
    static var face2Detect: NSFaceRegion? = nil
    static var faceImage: UIImage? = nil
    static var No = 0
}

@objc(AccuraKyc)
class AccuraKyc: NSObject {
    
    var goNativeCallBack: RCTResponseSenderBlock? = nil
    var accuraCameraWrapper: AccuraCameraWrapper? = nil
    var arrCountryList = NSMutableArray()
    var goNativeArgs: NSArray = []
    var accuraconfigs:NSDictionary = [:]
    var accuraTitleMsg:NSDictionary = [:]
    var viewController: UIViewController? = nil;
    var viewControllerWindow: UIWindow? = nil;
    
    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        resolve(a*b)
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    static func getImageFromUri(path: String) -> UIImage? {
        print(path)
        if let img = UIImage.init(contentsOfFile: path.replacingOccurrences(of: "file://", with: "")) {
            return img;
        }
        return nil
    }
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    static func getImageUri(img: UIImage, name: String?) -> String? {
        var file = randomString(length: 6)
        if let filename = name {
            file = filename
        }
        if let data = img.jpegData(compressionQuality: 1.0) {
            let filename = getDocumentsDirectory().appendingPathComponent("\(file).jpg")
            try? data.write(to: filename)
            print(filename.absoluteString)
            return filename.absoluteString
        }
        
        return nil
    }
    
    
    @objc(getMetaData:)
    func getMetaData(_ callback: @escaping RCTResponseSenderBlock) {
        self.goNativeCallBack = callback
        var results:[String: Any] = [:]
        results["isValid"] = false
        accuraCameraWrapper = AccuraCameraWrapper.init()
        //        DispatchQueue.main.async {
        //            self.accuraCameraWrapper?.setDefaultDialogs(true)
        //            self.accuraCameraWrapper?.showLogFile(true) // Set true to print log from KYC SDK
        //        }
        
        //        DispatchQueue.main.async {
        DispatchQueue.main.async {
        self.viewController = RCTPresentedViewController()!
        self.viewControllerWindow = RCTKeyWindow()!
            let sdkModel = self.accuraCameraWrapper!.loadEngine(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String)
            if sdkModel!.i > 0 {
                var countries:[Any] = []
                results["sdk_version"] = ""
                results["isValid"] = true
                results["isOCR"] = sdkModel!.isOCREnable
                results["isOCREnable"] = sdkModel!.isOCREnable
                results["isBarcode"] = sdkModel!.isBarcodeEnable
                results["isBankCard"] = sdkModel!.isBankCardEnable
                results["isMRZ"] = sdkModel!.isMRZEnable
                
                let countryListStr = self.accuraCameraWrapper!.getOCRList();
                for item in countryListStr ?? [] {
                    let cntry = item as! NSDictionary
                    var country:[String: Any] = [:]
                    
                    country["name"] = cntry.value(forKey: "country_name")
                    country["id"] = cntry.value(forKey: "country_id")
                    var cards:[[String: Any]] = []
                    for cd in cntry.value(forKey: "cards") as! NSArray {
                        let cardF = cd as! NSDictionary
                        var card:[String: Any] = [:]
                        card["name"] = cardF.value(forKey:"card_name")
                        card["id"] = cardF.value(forKey:"card_id")
                        card["type"] = cardF.value(forKey:"card_type")
                        cards.append(card)
                    }
                    country["cards"] = cards
                    countries.append(country)
                }
                results["countries"] = countries
                if  sdkModel!.isBarcodeEnable {
                    var barcodes:[[String: String]] = []
                    barcodes.append(["name": "ALL FORMATS","type": "ALL FORMATS"])
                    barcodes.append(["name": "EAN-8", "type": "EAN-8"])
                    barcodes.append(["name": "EAN-13", "type": "EAN-13"])
                    barcodes.append(["name": "PDF417", "type": "PDF417"])
                    barcodes.append(["name": "AZTEC", "type": "AZTEC"])
                    barcodes.append(["name": "CODE 128", "type": "CODE 128"])
                    barcodes.append(["name": "CODE 39", "type": "CODE 39"])
                    barcodes.append(["name": "CODE 93", "type": "CODE 93"])
                    barcodes.append(["name": "DATA MATRIX", "type": "DATA MATRIX"])
                    barcodes.append(["name": "QR CODE", "type": "QR CODE"])
                    barcodes.append(["name": "UPC-E", "type": "UPC-E"])
                    barcodes.append(["name": "UPC-A", "type": "UPC-A"])
                    barcodes.append(["name": "CODABAR", "type": "CODABAR"])
                    results["barcodes"] = barcodes
                }
            }
            self.goNativeCallBack!([NSNull(), AccuraKyc.convertJSONString(results: results)])
            //        }
        }
    }
    
    @objc(startOcrWithCard:callback:)
    func startOcrWithCard(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock){
        lvfm.faceImage = nil
        DispatchQueue.main.async {
            self.goNativeCallBack = callback;
            self.goNativeArgs = argsNew;
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
            viewController.countryid = self.goNativeArgs[0] as? Int
            viewController.cardid = self.goNativeArgs[1] as? Int
            viewController.isCheckScanOCR = true
            if self.goNativeArgs[3] as! Int == 1 {
                viewController.isBarCode = true
                viewController.isBarcodeEnabled = false
            }
            viewController.cardType = self.goNativeArgs[3] as? Int
            viewController.docName = self.goNativeArgs[2] as! String
            viewController.callBack = self.goNativeCallBack
            viewController.accuraTitleMsg = self.accuraTitleMsg
            viewController.accuraErrorCode = self.accuraconfigs
            viewController.modalPresentationStyle = .fullScreen
            viewController.modalTransitionStyle = .coverVertical
            self.getTopMostViewController()?.present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc(setupAccuraConfig:callback:)
    func setupAccuraConfig(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock){
        self.goNativeCallBack = callback
        self.goNativeArgs = argsNew;
        print("\(self.goNativeArgs)")
        let configs = goNativeArgs[0] as? NSDictionary
        accuraTitleMsg = goNativeArgs[2] as! NSDictionary
        accuraconfigs = goNativeArgs[1] as! NSDictionary
        var results:[String: Any] = [:]
        
        
        if configs?["setFaceBlurPercentage"] != nil {
            let val = (configs?["setFaceBlurPercentage"] as? Int32)!
            self.accuraCameraWrapper?.setFaceBlurPercentage(val)
        }else{
            self.accuraCameraWrapper?.setFaceBlurPercentage(80)
        }
        if configs?["setHologramDetection"] != nil {
            let val = (configs?["setHologramDetection"] as? Bool)!
            self.accuraCameraWrapper?.setHologramDetection(val)
        }else{
            self.accuraCameraWrapper?.setHologramDetection(true)
        }
        if configs?["setLowLightTolerance"] != nil {
            let val = (configs?["setLowLightTolerance"] as? Int32)!
            self.accuraCameraWrapper?.setLowLightTolerance(val)
        }else{
            self.accuraCameraWrapper?.setLowLightTolerance(10)
        }
        if configs?["setMotionThreshold"] != nil {
            let val = (configs?["setMotionThreshold"] as? Int32)!
            self.accuraCameraWrapper?.setMotionThreshold(val)
        }else{
            self.accuraCameraWrapper?.setMotionThreshold(25)
        }
        if configs?["setMinGlarePercentage"] != nil && configs?["setMaxGlarePercentage"] != nil {
            let val1 = (configs?["setMinGlarePercentage"] as? Int32)!
            let val2 = (configs?["setMaxGlarePercentage"] as? Int32)!
            
            self.accuraCameraWrapper?.setGlarePercentage(val1, intMax: val2)
        }else{
            self.accuraCameraWrapper?.setGlarePercentage(6, intMax: 99)
        }
        if configs?["setBlurPercentage"] != nil {
            let val = (configs?["setBlurPercentage"] as? Int32)!
            self.accuraCameraWrapper?.setBlurPercentage(val)
        }else{
            self.accuraCameraWrapper?.setBlurPercentage(60)
        }
        if configs?["setCameraFacing"] != nil {
            if configs?["setCameraFacing"] as? Int == 0{
                self.accuraCameraWrapper?.setCameraFacing(.CAMERA_FACING_BACK)
            }else if configs?["setCameraFacing"] as? Int == 1{
                self.accuraCameraWrapper?.setCameraFacing(.CAMERA_FACING_FRONT)
            }
        }else{
            self.accuraCameraWrapper?.setCameraFacing(.CAMERA_FACING_BACK)
        }
                if accuraconfigs["enableLogs"] != nil {
                    if accuraconfigs["enableLogs"] as? Int == 1 {
                        accuraCameraWrapper?.showLogFile(true)
                    } else{
                        accuraCameraWrapper?.showLogFile(false)
                    }
                } else{
                    accuraCameraWrapper?.showLogFile(false)
                }
        //            accuraCameraWrapper?.setCheckPhotoCopy(((configs!["isCheckPhotoCopy"] as? Bool)!))
        //                self.accuraCameraWrapper?.setCheckPhotoCopy(false, stCheckPhotoMessage: "")
        //           }
        results["status"] = "configs setup sucessfully"
        self.goNativeCallBack!([NSNull(),AccuraKyc.convertJSONString(results:results)])
    }
    
    @objc(startBankCard:)
    func startBankCard(_ callback: @escaping RCTResponseSenderBlock){
        DispatchQueue.main.async {
            self.goNativeCallBack = callback
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
            viewController.isCheckScanOCR = true
            viewController.cardType = 3
            viewController.accuraTitleMsg = self.accuraTitleMsg
            viewController.accuraErrorCode = self.accuraconfigs
            viewController.callBack = self.goNativeCallBack
            viewController.modalPresentationStyle = .fullScreen
            viewController.modalTransitionStyle = .coverVertical
            self.getTopMostViewController()?.present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc(startBarcode:callback:)
    func startBarcode(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock){
        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        
        DispatchQueue.main.async {
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
            viewController.accuraTitleMsg = self.accuraTitleMsg
            viewController.accuraErrorCode = self.accuraconfigs
            viewController.callBack = self.goNativeCallBack
            viewController.isBarCode = true
            viewController.isBarcodeEnabled = true
            viewController.reactViewController = self.viewController
            viewController.selectedTypes = self.setSelectedTypes(types: self.goNativeArgs[0] as! String)
            viewController.modalPresentationStyle = .fullScreen
            viewController.modalTransitionStyle = .coverVertical
            self.getTopMostViewController()?.present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc(startMRZ:callback:)
    func startMRZ(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock){
        lvfm.faceImage = nil
        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        DispatchQueue.main.async {
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
            if self.goNativeArgs[0] as! String == "passport_mrz" {
                viewController.MRZDocType = 1
            }else if self.goNativeArgs[0] as! String == "visa_card" {
                viewController.MRZDocType = 3
            }else if self.goNativeArgs[0] as! String == "id_mrz" {
                viewController.MRZDocType = 2
            }else{
                viewController.MRZDocType = 0
            }
            viewController.callBack = self.goNativeCallBack
            viewController.isCheckScanOCR = false
            viewController.reactViewController = self.viewController
            viewController.accuraTitleMsg = self.accuraTitleMsg
            viewController.accuraErrorCode = self.accuraconfigs
            print(self.accuraconfigs)
            viewController.modalPresentationStyle = .fullScreen
            viewController.modalTransitionStyle = .coverVertical
            //        DispatchQueue.main.async {
            //            viewController.modalPresentationStyle = .fullScreen
            self.getTopMostViewController()?.present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc(startFaceMatch:callback:)
    func startFaceMatch(_ argsNew: NSArray,callback: @escaping RCTResponseSenderBlock){
        self.goNativeCallBack = callback
        self.goNativeArgs = argsNew;
        let face:NSDictionary
        face = goNativeArgs[0] as! NSDictionary
        EngineWrapper.faceEngineClose()
        let fmInit = EngineWrapper.isEngineInit()
        if !fmInit{
            DispatchQueue.main.async {
                EngineWrapper.faceEngineInit()
            }
        }
        let fmValue = EngineWrapper.getEngineInitValue() //get engineWrapper load status
        if fmValue == -20{
            self.goNativeCallBack!(["key ot found", NSNull()])
            //            sendError(msg: "key not found")
        }else if fmValue == -15{
            self.goNativeCallBack!(["License Invalid", NSNull()])
            
            //            sendError(msg: "License Invalid")
        }else{
            DispatchQueue.main.async {
                let FMController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "LVController") as! LVController
                FMController.faceArgs = self.goNativeArgs[1] as! NSDictionary
                FMController.isfacematch = true
                FMController.callBack = self.goNativeCallBack
                //                FMController.faceImage = lvfm.faceImage
                FMController.faceImage = AccuraKyc.getImageFromUri(path: face["face_uri"] as! String)
                FMController.reactViewController = self.viewController
                FMController.win = self.viewControllerWindow
                let nav = NavigationController(rootViewController: FMController)
                self.viewControllerWindow?.rootViewController = nav
            }
        }
    }
    
    @objc(startLiveness:callback:)
    func startLiveness(_ argsNew: NSArray,callback: @escaping RCTResponseSenderBlock){
        DispatchQueue.main.async {
            self.goNativeCallBack = callback
            self.goNativeArgs = argsNew;
            let face:NSDictionary
            face = self.goNativeArgs[0] as! NSDictionary
            EngineWrapper.faceEngineClose()
            let fmInit = EngineWrapper.isEngineInit()
            if !fmInit{
                EngineWrapper.faceEngineInit()
            }
            let fmValue = EngineWrapper.getEngineInitValue() //get engineWrapper load status
            if fmValue == -20{
                self.goNativeCallBack!(["key ot found", NSNull()])
                //            sendError(msg: "key not found")
            }else if fmValue == -15{
                self.goNativeCallBack!(["License Invalid", NSNull()])
                //            sendError(msg: "License Invalid")
            }else{
                let LVController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "LVController") as! LVController
                LVController.isLiveness = true
                LVController.livenessConfig = self.goNativeArgs[1] as! NSDictionary
                LVController.callBack = self.goNativeCallBack
                //                LVController.faceImage = gl.faceImage
                if let face = AccuraKyc.getImageFromUri(path: face["face_uri"] as! String) {
                    LVController.faceImage = face
                }
                LVController.reactViewController = self.viewController
                LVController.win = self.viewControllerWindow
                let nav = NavigationController(rootViewController: LVController)
                self.viewControllerWindow?.rootViewController = nav
            }
        }
    }
    
    @objc(startFaceMatch2:callback:)
    func startFaceMatch2(_ argsNew: NSArray,callback: @escaping RCTResponseSenderBlock){
        DispatchQueue.main.async {
        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        EngineWrapper.faceEngineClose()
        let fmInit = EngineWrapper.isEngineInit()
        if !fmInit{
            EngineWrapper.faceEngineInit()
        }
        let fmValue = EngineWrapper.getEngineInitValue() //get engineWrapper load status
        if fmValue == -20{
            self.sendError(msg: "Key not found")
            return
        }else if fmValue == -15{
            self.sendError(msg: "License Invalid")
            return
        }
        let accuraConfigs = self.goNativeArgs[0] as! [String:Any]
        let face1 = AccuraKyc.getImageFromUri(path:accuraConfigs["face1"] as! String)
        let face2 = AccuraKyc.getImageFromUri(path:accuraConfigs["face2"] as! String)
        lvfm.face1 = face1
        lvfm.face2 = face2
        lvfm.No = 2
            let FMController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "FMController") as! FMController
            FMController.callBack = self.goNativeCallBack
            FMController.facematch2 = true
            FMController.faceArgs = self.goNativeArgs[1] as! NSDictionary
            
            //            FMController.livenessConfigs = self.goNativeArgs[1] as! [String: Any]
            FMController.reactViewController = self.viewController
            //            FMController.win = self.viewControllerWindow
            
            self.getTopMostViewController()?.present(FMController, animated: true, completion: nil)
            
            //            DispatchQueue.main.async {
            //                let nav = UINavigationController(rootViewController: FMController)
            //                nav.isNavigationBarHidden = true
            //                nav.modalPresentationStyle = .fullScreen
            //                nav.modalTransitionStyle = .coverVertical
            //                self.getTopMostViewController()?.present(nav, animated: true, completion: {
            //
            //                })
            //            }
        }
    }
    
    @objc(openGallery2:callback:)
    func openGallery2(_ argsNew: NSArray,callback: @escaping RCTResponseSenderBlock){
        DispatchQueue.main.async {
        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        EngineWrapper.faceEngineClose()
        let fmInit = EngineWrapper.isEngineInit()
        if !fmInit{
            EngineWrapper.faceEngineInit()
        }
        let fmValue = EngineWrapper.getEngineInitValue() //get engineWrapper load status
        if fmValue == -20{
            self.sendError(msg: "Key not found")
            return
        }else if fmValue == -15{
            self.sendError(msg: "License Invalid")
            return
        }
        let accuraConfigs = self.goNativeArgs[0] as! [String:Any]
        let face1 = AccuraKyc.getImageFromUri(path: accuraConfigs["face1"] as! String)
        let face2 = AccuraKyc.getImageFromUri(path: accuraConfigs["face2"] as! String)
        lvfm.face1 = face1
        lvfm.face2 = face2
        lvfm.No = 2
            let FMController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "FMController") as! FMController
            FMController.callBack = self.goNativeCallBack
            FMController.gallery2 = true
            FMController.reactViewController = self.viewController
            //            FMController.win = self.viewControllerWindow
            self.getTopMostViewController()?.present(FMController, animated: true, completion: nil)
            
            //            DispatchQueue.main.async {
            //                let nav = UINavigationController(rootViewController: FMController)
            //                nav.isNavigationBarHidden = true
            //                nav.modalPresentationStyle = .fullScreen
            //                nav.modalTransitionStyle = .coverVertical
            //                self.getTopMostViewController()?.present(nav, animated: true, completion: {
            //
            //                })
            //            }
        }
    }
    
    @objc(openGallery1:callback:)
    func openGallery1(_ argsNew: NSArray,callback: @escaping RCTResponseSenderBlock){
        DispatchQueue.main.async {
        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        EngineWrapper.faceEngineClose()
        let fmInit = EngineWrapper.isEngineInit()
        if !fmInit{
            DispatchQueue.main.async {
                EngineWrapper.faceEngineInit()
            }
        }
        let fmValue = EngineWrapper.getEngineInitValue() //get engineWrapper load status
        if fmValue == -20{
            //            goNativeCallBack!(FlutterError.init(code: "101", message: "Key not found", details: nil))
            self.sendError(msg: "Key not found")
            return
        }else if fmValue == -15{
            //            goNativeCallBack!(FlutterError.init(code: "101", message: "License Invalid", details: nil))
            self.sendError(msg: "License Invalid")
            return
        }
        let accuraConfigs = self.goNativeArgs[0] as! [String:Any]
        let face1 = AccuraKyc.getImageFromUri(path:accuraConfigs["face1"] as! String)
        let face2 = AccuraKyc.getImageFromUri(path: accuraConfigs["face2"] as! String)
        lvfm.face1 = face1
        lvfm.face2 = face2
        lvfm.No = 1
            let FMController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "FMController") as! FMController
            FMController.callBack = self.goNativeCallBack
            FMController.gallery1 = true
            FMController.reactViewController = self.viewController
            //            FMController.win = self.viewControllerWindow
            self.getTopMostViewController()?.present(FMController, animated: true, completion: nil)
            
            //            DispatchQueue.main.async {
            //                let nav = UINavigationController(rootViewController: FMController)
            //                nav.isNavigationBarHidden = true
            //                nav.modalPresentationStyle = .fullScreen
            //                nav.modalTransitionStyle = .coverVertical
            //                self.getTopMostViewController()?.present(nav, animated: true, completion: {
            //
            //                })
            //            }
        }
    }
    @objc(startFaceMatch1:callback:)
    func startFaceMatch1(_ argsNew: NSArray,callback: @escaping RCTResponseSenderBlock){
        DispatchQueue.main.async {
        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        EngineWrapper.faceEngineClose()
        let fmInit = EngineWrapper.isEngineInit()
        if !fmInit{
            EngineWrapper.faceEngineInit()
        }
        let fmValue = EngineWrapper.getEngineInitValue() //get engineWrapper load status
        if fmValue == -20{
            self.sendError(msg: "Key not found")
            return
        }else if fmValue == -15{
            self.sendError(msg: "License Invalid")
            return
        }
        let accuraConfigs1 = self.goNativeArgs[0] as! [String:Any]
        print(accuraConfigs1)
        let face1 = AccuraKyc.getImageFromUri(path: accuraConfigs1["face1"] as! String)
        let face2 = AccuraKyc.getImageFromUri(path: accuraConfigs1["face2"] as! String)
        lvfm.face1 = face1
        lvfm.face2 = face2
        lvfm.No = 1
            let FMController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "FMController") as! FMController
            FMController.callBack = self.goNativeCallBack
            FMController.faceMatch1 = true
            FMController.faceArgs = self.goNativeArgs[1] as! NSDictionary
            
            //            FMController.livenessConfigs = self.goNativeArgs[1] as! [String: Any]
            FMController.reactViewController = self.viewController
            //            FMController.win = self.viewControllerWindow
            
            self.getTopMostViewController()?.present(FMController, animated: true, completion: nil)
            
            //            DispatchQueue.main.async {
            //                let nav = UINavigationController(rootViewController: FMController)
            //                nav.isNavigationBarHidden = true
            //                nav.modalPresentationStyle = .fullScreen
            //                nav.modalTransitionStyle = .coverVertical
            //                self.getTopMostViewController()?.present(nav, animated: true, completion: {
            //
            //                })
            //            }
        }
    }
    
    
    
    static func convertJSONString(results: [String: Any]) -> String {
        
        if let theJSONData = try?  JSONSerialization.data( withJSONObject: results, options: .prettyPrinted ),
           let theJSONText = String(data: theJSONData, encoding: String.Encoding.ascii) {
            print("JSON string = \n\(theJSONText)")
            return theJSONText.components(separatedBy: .newlines).joined();
        }
        return "{}"
    }
    
    func sendError(msg: String) {
        
        self.goNativeCallBack!([msg as Any, NSNull()])
    }
    
    func getTopMostViewController() -> UIViewController? {
        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController
        
        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }
        
        return topMostViewController
    }
    
    func setSelectedTypes(types: String) -> BarcodeType {
        switch types
        {
        case "ALL FORMATS":
            return .all
        case "EAN-8":
            return .ean8
        case "EAN-13":
            return .ean13
        case "PDF417":
            return .pdf417
        case "AZTEC":
            return .aztec
        case "CODE 128":
            return .code128
        case "CODE 39":
            return .code39
        case "CODE 93":
            return .code93
        case "DATA MATRIX":
            return .dataMatrix
        case "ITF":
            return .itf
        case "QR CODE":
            return .qrcode
        case "UPC-E":
            return .upce
        case "UPC-A":
            return .upca
        case "CODABAR":
            return .codabar
        default:
            return .all
        }
    }
    
}
class NavigationController: UINavigationController {
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return getCurrentOrientation(isMask: true) as! UIInterfaceOrientationMask
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return getCurrentOrientation(isMask: false) as! UIInterfaceOrientation
    }
    
    func getCurrentOrientation(isMask: Bool) -> Any {
        let orientation = "portrait"
        
        if(orientation.contains("portrait")) {
            if isMask {
                return UIInterfaceOrientationMask.portrait
            } else {
                return UIInterfaceOrientation.portrait
            }
        } else {
            if isMask {
                return UIInterfaceOrientationMask.landscape
            } else {
                return UIInterfaceOrientation.landscapeRight
            }
        }
    }
    
}

