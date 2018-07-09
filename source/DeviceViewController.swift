//
//  DeviceViewController.swift
//  oscDataRecorder
//
//  Created by Stephen OHara on 6/7/18.
//  Copyright © 2018 Stephen OHara. All rights reserved.
//

import UIKit
import SceneKit
import OSCKit
import SwiftyJSON


struct DeviceData {
    
    var gyro: SCNVector3 = SCNVector3()
    var quat: SCNQuaternion = SCNQuaternion()
    var rrate: SCNVector3 = SCNVector3()
    var accel: SCNVector3 = SCNVector3()
    
    func asJSON () -> JSON {
        
        let json: JSON = JSON([
            "gyro": [gyro.x, gyro.y, gyro.z],
            "quat": [quat.x, quat.y, quat.z, quat.w],
            "rrate": [rrate.x, rrate.y, rrate.z],
            "accel": [accel.x, accel.y, accel.z]

        ])
        return json
    }
}

protocol DeviceViewControllerDelegate {
    
    func updateDevice()
    func handleOSCMessage(_ msg:OSCMessage)
    func handleJSONString(_ jsonString:String)
    func getJSONString() -> String?
}

class DeviceViewController: UIViewController,DeviceViewControllerDelegate {

    @IBOutlet weak var skView: SCNView!
    
    var deviceData = DeviceData()

    override func viewDidLoad() {
        super.viewDidLoad()

        skView.scene?.background.contents = UIColor.clear
        skView.backgroundColor = UIColor.clear
        
        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
        boxNode?.localTranslate(by: SCNVector3(x: 0.0, y: 0.0, z: -2.0))

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleOSCMessage(_ message:OSCMessage){

        // convert to useful values
        let values = message.arguments.map{ Float($0 as! String)!}
        
        switch (message.address as NSString).lastPathComponent {
        case "gyro":
            deviceData.gyro = SCNVector3(x: values[0], y: values[1], z: values[2])
        case "quat":
            // needed to swap order for orientation to work  on node
            deviceData.quat = SCNQuaternion(x: values[2] , y: values[3], z: values[1], w: values[0])
        case "rrate":
            deviceData.rrate = SCNVector3(x: values[0], y: values[1], z: values[2])
        case "accel":
            deviceData.accel = SCNVector3(x: values[0], y: values[1], z: values[2])
            
        default:
            print("unable to store osc data")
        }
    }
    
    func handleJSONString(_ jsonString:String) {
       
        if let dataFromString = jsonString.data(using: .utf8, allowLossyConversion: false) {
            
            let json = try! JSON(data: dataFromString)
            
            deviceData.quat.x = json["quat"][0].floatValue
            deviceData.quat.y = json["quat"][1].floatValue
            deviceData.quat.z = json["quat"][2].floatValue
            deviceData.quat.w = json["quat"][3].floatValue
            
            deviceData.gyro.x = json["gyro"][0].floatValue
            deviceData.gyro.y = json["gyro"][1].floatValue
            deviceData.gyro.z = json["gyro"][2].floatValue

            deviceData.rrate.x = json["rrate"][0].floatValue
            deviceData.rrate.y = json["rrate"][1].floatValue
            deviceData.rrate.z = json["rrate"][2].floatValue

            deviceData.accel.x = json["accel"][0].floatValue
            deviceData.accel.y = json["accel"][1].floatValue
            deviceData.accel.z = json["accel"][2].floatValue

        }
    }

    
    func updateDevice(){

        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
        boxNode?.orientation = deviceData.quat
    }

    func getJSONString() -> String? {
        return deviceData.asJSON()[].rawString()
    }

}
