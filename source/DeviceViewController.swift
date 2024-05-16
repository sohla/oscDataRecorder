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
//    var deviceData: DeviceDataProtocol { get set }
    func updateScene(data: DeviceDataProtocol)
}

class DeviceViewController: UIViewController, DeviceViewControllerDelegate {

    @IBOutlet weak var skView: SCNView!
    @IBOutlet weak var label: UILabel!
    //    var deviceData: any DeviceDataProtocol = MOSCDeviceData()
//    var deviceData: any DeviceDataProtocol = ASDeviceData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView.scene?.background.contents = UIColor.clear
        skView.backgroundColor = UIColor.clear
        
//        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)?.clone()
//        boxNode?.name = "box2"
//        skView.scene?.rootNode.addChildNode(boxNode!)
        
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
    
    func updateScene(data: DeviceDataProtocol){
        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
        boxNode?.orientation = data.quat
        label.text = "\(data.quat)"
    }
}

