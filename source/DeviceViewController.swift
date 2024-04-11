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
    
    func updateScene()
    func handleOSCMessage(_ msg:OSCMessage)
    func handleJSONString(_ jsonString:String)
    func getJSONString() -> String?
    
    func sendOSCConnect()
    func sendOSCMessage()
}

class DeviceViewController: UIViewController, DeviceViewControllerDelegate {
    
    @IBOutlet weak var skView: SCNView!
    
    var deviceData = DeviceData()
//    let boxNode  = SCNScene(named: "SceneKit Scene.scn")?.rootNode.childNode(withName: "box", recursively: true)
//    let client = OSCUdpClient(host: "127.0.0.1", port: 57120)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.client.delegate = self
        
        skView.scene?.background.contents = UIColor.clear
        skView.backgroundColor = UIColor.clear
        
        if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
            let port = UserDefaults.standard.integer(forKey: "portAddress")
//            self.client.host = ip
//            self.client.port = UInt16(port)
        }
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
    
    func sendOSCMessage() {
        
        //        if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
        //            if let port = UserDefaults.standard.string(forKey: "portAddress"){
        //
        //                let address = "udp://"+ip+":"+port
        //
        //                //• should we bundle this up?
        //                var msg: OSCMessage = OSCMessage(address: "/gyrosc/gyro", arguments: [deviceData.gyro.x, deviceData.gyro.y, deviceData.gyro.z])
        //                DeviceViewController.client.send(msg, to: address)
        //
        //                msg = OSCMessage(address: "/gyrosc/rrate", arguments: [deviceData.rrate.x, deviceData.rrate.y, deviceData.rrate.z])
        //                DeviceViewController.client.send(msg, to: address)
        //
        //                msg = OSCMessage(address: "/gyrosc/accel", arguments: [deviceData.accel.x, deviceData.accel.y, deviceData.accel.z])
        //                DeviceViewController.client.send(msg, to: address)
        //
        //                msg = OSCMessage(address: "/gyrosc/quat", arguments: [deviceData.quat.w, deviceData.quat.z, deviceData.quat.x, deviceData.quat.y])
        //                DeviceViewController.client.send(msg, to: address)
        //
        //                msg = OSCMessage(address: "/gyrosc/amp", arguments: [deviceData.amp])
        //                DeviceViewController.client.send(msg, to: address)
        //
        //            }
        //
        //        }
        
//        var msg = try! OSCMessage(with: "/gyrosc/gyro", arguments: [deviceData.gyro.x, deviceData.gyro.y, deviceData.gyro.z])
//        try? self.client.send(msg)
//        
//        msg = try! OSCMessage(with: "/gyrosc/rrate", arguments: [deviceData.rrate.x, deviceData.rrate.y, deviceData.rrate.z])
//        try? self.client.send(msg)
//        
//        msg = try! OSCMessage(with: "/gyrosc/accel", arguments: [deviceData.accel.x, deviceData.accel.y, deviceData.accel.z])
//        try? self.client.send(msg)
//        
//        msg = try! OSCMessage(with: "/gyrosc/quat", arguments: [deviceData.quat.w, deviceData.quat.z, deviceData.quat.x, deviceData.quat.y])
//        try? self.client.send(msg)
//        
//        msg = try! OSCMessage(with: "/gyrosc/amp", arguments: [deviceData.amp])
//        try? self.client.send(msg)
    }
    
    func sendOSCConnect() {
//        let msg = try! OSCMessage(with: "/gyrosc/button", arguments: [1.0])
//        try? self.client.send(msg)
    }
    
    
    func handleOSCMessage(_ message:OSCMessage){

        // encode message.values to deviceData
        switch (message.addressPattern.pathComponents.last) {
            case "gyro":
                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
                deviceData.gyro = SCNVector3(x: v0, y: v1, z: v2)

            case "quat":
                // needed to swap order for orientation to work  on node
                // print(message.values[0].oscValueToken)
                guard let (v0,v1,v2,v3) = try? message.values.masked(Float.self, Float.self, Float.self, Float.self) else { return }
                deviceData.quat = SCNQuaternion(x: v2 , y: v3, z: v1, w: v0)

            case "rrate":
                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
                deviceData.rrate = SCNVector3(x: v0, y: v1, z: v2)

            case "accel":
                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
                deviceData.accel = SCNVector3(x: v0, y: v1, z: v2)

            case "amp":
                guard let (v0) = try? message.values.masked(Float.self) else { return }
                deviceData.amp = v0

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

}

