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

import CoreMotion


struct DeviceData {
    
    var gyro: SCNVector3 = SCNVector3()
    var quat: SCNQuaternion = SCNQuaternion()
    var rrate: SCNVector3 = SCNVector3()
    var accel: SCNVector3 = SCNVector3()
    var amp: Float = 0
    
    func asJSON () -> JSON {
        
        let json: JSON = JSON([
            "gyro": [gyro.x, gyro.y, gyro.z],
            "quat": [quat.x, quat.y, quat.z, quat.w],
            "rrate": [rrate.x, rrate.y, rrate.z],
            "accel": [accel.x, accel.y, accel.z],
            "amp": amp

        ])
        return json
    }
}

protocol DeviceViewControllerDelegate {
    
    func updateDevice()
    func handleOSCMessage(_ msg:OSCMessage)
    func handleJSONString(_ jsonString:String)
    func getJSONString() -> String?
    
    func sendOSCConnect()
    func sendOSCMessage()
}

class DeviceViewController: UIViewController,DeviceViewControllerDelegate {

    @IBOutlet weak var skView: SCNView!
    
    var deviceData = DeviceData()
    
    static let client:OSCClient = OSCClient()

    override func viewDidLoad() {
        super.viewDidLoad()

        skView.scene?.background.contents = UIColor.clear
        skView.backgroundColor = UIColor.clear
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleOSCMessage(_ message:OSCMessage){

        
        // convert to useful values
        //let values = message.arguments!.map{ Float($0 as! String)!}
        let values: Array<Float> = message.arguments!.map({ $0 as! Float })
        
        
        
/*
         https://stackoverflow.com/questions/23503151/how-to-update-quaternion-based-on-3d-gyro-data

*/
        
        
        switch (message.address as NSString).lastPathComponent {
            case "gyro":
                deviceData.gyro = SCNVector3(x: values[0], y: values[1], z: values[2])

                //•• HACK for bee's
                let w = cos(deviceData.gyro.x/2) * cos(deviceData.gyro.y/2) * cos(deviceData.gyro.z/2) + sin(deviceData.gyro.x/2) * sin(deviceData.gyro.y/2) * sin(deviceData.gyro.z/2)
                let x = sin(deviceData.gyro.x/2) * cos(deviceData.gyro.y/2) * cos(deviceData.gyro.z/2) - cos(deviceData.gyro.x/2) * sin(deviceData.gyro.y/2) * sin(deviceData.gyro.z/2)
                let y = cos(deviceData.gyro.x/2) * sin(deviceData.gyro.y/2) * cos(deviceData.gyro.z/2) + sin(deviceData.gyro.x/2) * cos(deviceData.gyro.y/2) * sin(deviceData.gyro.z/2)
                let z = cos(deviceData.gyro.x/2) * cos(deviceData.gyro.y/2) * sin(deviceData.gyro.z/2) - sin(deviceData.gyro.x/2) * sin(deviceData.gyro.y/2) * cos(deviceData.gyro.z/2)

                deviceData.quat = SCNQuaternion(x: x, y: y, z: z, w: w)
                // •• END HACK
        
        
//            case "quat":
//                // needed to swap order for orientation to work  on node
//                deviceData.quat = SCNQuaternion(x: values[2] , y: values[3], z: values[1], w: values[0])

        case "rrate":
                deviceData.rrate = SCNVector3(x: values[0], y: values[1], z: values[2])
            case "accel":
                deviceData.accel = SCNVector3(x: values[0], y: values[1], z: values[2])

            case "amp":
                deviceData.amp = values[0]

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

            deviceData.amp = json["amp"].floatValue

        }
    }

    
    func updateDevice(){

        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
        
        boxNode?.orientation = deviceData.quat
    }

    func getJSONString() -> String? {
        return deviceData.asJSON()[].rawString()
    }
    
    func sendOSCMessage() {
                
        if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
            if let port = UserDefaults.standard.string(forKey: "portAddress"){

                let address = "udp://"+ip+":"+port

                //• should we bundle this up?
                var msg: OSCMessage = OSCMessage(address: "/gyrosc/gyro", arguments: [deviceData.gyro.x, deviceData.gyro.y, deviceData.gyro.z])
                DeviceViewController.client.send(msg, to: address)
                
                msg = OSCMessage(address: "/gyrosc/rrate", arguments: [deviceData.rrate.x, deviceData.rrate.y, deviceData.rrate.z])
                DeviceViewController.client.send(msg, to: address)
                
                msg = OSCMessage(address: "/gyrosc/accel", arguments: [deviceData.accel.x, deviceData.accel.y, deviceData.accel.z])
                DeviceViewController.client.send(msg, to: address)
                
                msg = OSCMessage(address: "/gyrosc/quat", arguments: [deviceData.quat.w, deviceData.quat.z, deviceData.quat.x, deviceData.quat.y])
                DeviceViewController.client.send(msg, to: address)

                msg = OSCMessage(address: "/gyrosc/amp", arguments: [deviceData.amp])
                DeviceViewController.client.send(msg, to: address)

            }

        }
    }
    
    func sendOSCConnect() {
    
        //•• SET ADDRESS AND PORT of receiver (laptop)
//        let address = "udp://10.224.15.22:57120"
//        let address = "udp://10.1.1.4:57120"
//        let address = "udp://169.254.50.189:57120"
//        let address = "udp://169.254.251.179:57120"
//        let address = "udp://169.254.77.15:57121"
//        let address = "udp://192.168.10.2:57121"

        if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
            if let port = UserDefaults.standard.string(forKey: "portAddress"){

                let address = "udp://"+ip+":"+port
                
                let msg: OSCMessage = OSCMessage(address: "/gyrosc/button", arguments: [1.0])
                DeviceViewController.client.send(msg, to: address)

            }
        }
    }

}
