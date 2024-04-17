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
    func getJSONString() -> String?
    
}

class DeviceViewController: UIViewController, DeviceViewControllerDelegate {

    @IBOutlet weak var skView: SCNView!
    
//    var deviceData: any DeviceDataProtocol = MOSCDeviceData()
    var deviceData: any DeviceDataProtocol = ASDeviceData()
    
//        var deviceData = MOSCDeviceData() //DeviceData()
//    let boxNode  = SCNScene(named: "SceneKit Scene.scn")?.rootNode.childNode(withName: "box", recursively: true)
//    let client = OSCUdpClient(host: "127.0.0.1", port: 57120)
    
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
        // Dispose of any resources that can be recreated.
    }
    
    func updateScene(){
        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
        boxNode?.orientation = deviceData.quat
    }
    
    func getJSONString() -> String? {
        return deviceData.asJSON()[].rawString()
    }
}

