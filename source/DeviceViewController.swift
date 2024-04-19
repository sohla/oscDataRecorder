//
//  DeviceViewController.swift
//  oscDataRecorder
//
//  Created by Stephen OHara on 6/7/18.
//  Copyright © 2018 Stephen OHara. All rights reserved.
//

import UIKit
import SceneKit


protocol DeviceViewControllerDelegate {

    var deviceData: DeviceDataProtocol { get set }

    func updateScene()
    
}

class DeviceViewController: UIViewController, DeviceViewControllerDelegate {

    @IBOutlet weak var skView: SCNView!

    var deviceData: any DeviceDataProtocol = MOSCDeviceData()
//    var deviceData: any DeviceDataProtocol = ASDeviceData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.client.delegate = self
        
        skView.scene?.background.contents = UIColor.clear
        skView.backgroundColor = UIColor.clear
        
//        if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
//            let port = UserDefaults.standard.integer(forKey: "portAddress")
//            self.client.host = ip
//            self.client.port = UInt16(port)
//        }
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateScene(){
        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
        boxNode?.orientation = deviceData.quat
        
//        messageLabel.text = deviceData.addressString + "\n"
        let bar1 = skView.scene?.rootNode.childNode(withName: "bar1", recursively: true)
        bar1?.scale = SCNVector3(1 + deviceData.quat.x, 1 + deviceData.quat.y, 0)
        let bar2 = skView.scene?.rootNode.childNode(withName: "bar2", recursively: true)
        bar2?.scale = SCNVector3(1 + deviceData.quat.z, 1 + deviceData.quat.w, 0)

    }
    
}

