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
        
        let boxNode2 = skView.scene?.rootNode.childNode(withName: "box", recursively: true)?.clone()
        boxNode2?.name = "box2"
        skView.scene?.rootNode.addChildNode(boxNode2!)

        let boxNode3 = skView.scene?.rootNode.childNode(withName: "box", recursively: true)?.clone()
        boxNode3?.name = "box3"
        skView.scene?.rootNode.addChildNode(boxNode3!)

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
        
        switch (data.deviceID){
            
        case "1":
            let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
            boxNode?.orientation = data.quat
            boxNode?.position = SCNVector3(-2,0,-2)
            label.text = "\(data.deviceID)"
            break;
        case "2":
            let boxNode = skView.scene?.rootNode.childNode(withName: "box2", recursively: true)
            boxNode?.orientation = data.quat
            boxNode?.position = SCNVector3(0,0,-2)
            label.text = "\(data.deviceID)"
            break;
        case "3":
            let boxNode = skView.scene?.rootNode.childNode(withName: "box3", recursively: true)
            boxNode?.orientation = data.quat
            boxNode?.position = SCNVector3(2,0,-2)
            label.text = "\(data.deviceID)"
            break;

        default:
            print("no device")
        }
        
    }
}

