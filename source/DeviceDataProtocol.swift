//
//  DeviceDataProtocol.swift
//  oscDataRecorder
//
//  Created by soh_la on 14/4/2024.
//  Copyright © 2024 Stephen OHara. All rights reserved.
//

import Foundation
import SceneKit
import OSCKit
import SwiftyJSON


protocol DeviceDataProtocol {
    
    var gyro: SCNVector3 { get set }
    var quat: SCNQuaternion { get set }
    var rrate: SCNVector3 { get set }
    var accel: SCNVector3 { get set }
    var amp: Float { get set }

    var addressString: String { get }
    var deviceID: String { get }
    
    func asJSON () -> JSON
    func fromString(_ jsonString:String)
    func toString() -> String?
    func fromOSC(_ message:OSCMessage)
    func asOSC() -> OSCMessage
    
    /*
        buffer of OSC messages
        addMsg : add a single OSC message to the buffer
        convert buffer messages to JSON
        save JSON string file

     
        sync issues :
            OSC coming in 10ms / 100 fps
            * not guarenteed
     
        video
            16.6ms / 60 fps
     */
}

class MOSCDeviceData : DeviceDataProtocol {
    
    var gyro: SCNVector3 = SCNVector3()
    var quat: SCNQuaternion = SCNQuaternion()
    var rrate: SCNVector3 = SCNVector3()
    var accel: SCNVector3 = SCNVector3()
    var amp: Float = 0
    var addressString: String = ""
    var deviceID: String = ""
    
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
    
    func toString() -> String? {
        return asJSON().rawString()
    }

    func fromString(_ jsonString:String) {
        
        if let dataFromString = jsonString.data(using: .utf8, allowLossyConversion: false) {
            
            let json = try! JSON(data: dataFromString)
            
            quat.x = json["quat"][0].floatValue
            quat.y = json["quat"][1].floatValue
            quat.z = json["quat"][2].floatValue
            quat.w = json["quat"][3].floatValue
            
            gyro.x = json["gyro"][0].floatValue
            gyro.y = json["gyro"][1].floatValue
            gyro.z = json["gyro"][2].floatValue
            
            rrate.x = json["rrate"][0].floatValue
            rrate.y = json["rrate"][1].floatValue
            rrate.z = json["rrate"][2].floatValue
            
            accel.x = json["accel"][0].floatValue
            accel.y = json["accel"][1].floatValue
            accel.z = json["accel"][2].floatValue
            
            amp = json["amp"].floatValue
            
        }
    }
    
    func fromOSC(_ message:OSCMessage){
        
        addressString = message.addressPattern.stringValue
                
        // encode message.values to deviceData
        switch (message.addressPattern.pathComponents.last) {
            case "gyro":
                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
                gyro = SCNVector3(x: v0, y: v1, z: v2)

            case "quat":
                // needed to swap order for orientation to work  on node
                guard let (v0,v1,v2,v3) = try? message.values.masked(Double.self, Double.self, Double.self, Double.self) else { return }
                quat = SCNQuaternion(x: Float(v2) , y: Float(v3), z: Float(v1), w: Float(v0))

            case "rrate":
                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
                rrate = SCNVector3(x: v0, y: v1, z: v2)

            case "accel":
                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
                accel = SCNVector3(x: v0, y: v1, z: v2)

            case "amp":
                guard let (v0) = try? message.values.masked(Float.self) else { return }
                amp = v0

            default:
                print("unable to store osc data")
        }
    }
    
    func asOSC() -> OSCKitCore.OSCMessage {
        let msg: OSCMessage = OSCMessage("/TO/DO", values: [0,0,0])
        return msg
    }

}


class ASDeviceData : DeviceDataProtocol {
    
    var gyro: SCNVector3 = SCNVector3()
    var quat: SCNQuaternion = SCNQuaternion()
    var rrate: SCNVector3 = SCNVector3()
    var accel: SCNVector3 = SCNVector3()
    var amp: Float = 0
    var addressString: String = ""
    
    var deviceID: String = ""

    func asJSON () -> JSON {
        let json: JSON = JSON([
            "deviceID": deviceID,
            "gyro": [gyro.x, gyro.y, gyro.z],
            "quat": [quat.x, quat.y, quat.z, quat.w],
            "rrate": [rrate.x, rrate.y, rrate.z],
            "accel": [accel.x, accel.y, accel.z],
            "amp": amp
            
        ])
        return json
    }
    func toString() -> String? {
        return asJSON().rawString()
    }


    func fromString(_ jsonString:String) {
        
        if let dataFromString = jsonString.data(using: .utf8, allowLossyConversion: false) {
            
            let json = try! JSON(data: dataFromString)
            
            deviceID = json["deviceID"].stringValue
            
            quat.x = json["quat"][0].floatValue
            quat.y = json["quat"][1].floatValue
            quat.z = json["quat"][2].floatValue
            quat.w = json["quat"][3].floatValue
            
            gyro.x = json["gyro"][0].floatValue
            gyro.y = json["gyro"][1].floatValue
            gyro.z = json["gyro"][2].floatValue
            
            rrate.x = json["rrate"][0].floatValue
            rrate.y = json["rrate"][1].floatValue
            rrate.z = json["rrate"][2].floatValue
            
            accel.x = json["accel"][0].floatValue
            accel.y = json["accel"][1].floatValue
            accel.z = json["accel"][2].floatValue
            
            amp = json["amp"].floatValue
            
        }
    }
    //v2 v1 v3 v0
    func fromOSC(_ message:OSCMessage){
        // encode message.values to deviceData
        switch (message.addressPattern.pathComponents.last) {
//            case "qX":
//                guard let v0 = try? message.values.masked(Float.self) else { return }
//                quat.x = v0
//
//            case "qY":
//                guard let v0 = try? message.values.masked(Float.self) else { return }
//                quat.y = v0
//    
//            case "qZ":
//                guard let v0 = try? message.values.masked(Float.self) else { return }
//                quat.z = v0
//
//            case "qW":
//                guard let v0 = try? message.values.masked(Float.self) else { return }
//                quat.w = v0

            case "IMUFusedData":
                guard let (v0, v1, v2, v3, v4, v5, v6) = try? message.values.masked(Float.self, Float.self, Float.self, Float.self, Float.self, Float.self, Float.self) else { return }
                accel = SCNVector3(x: v0, y: v1, z: v2)
                quat = SCNQuaternion(x: v3 , y: v4, z: v5, w: v6)
                if let id = message.addressPattern.pathComponents.first {
                    deviceID = String(id)
                }
            
//            case "rrate":
//                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
//                rrate = SCNVector3(x: v0, y: v1, z: v2)
//
//            case "accel":
//                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
//                accel = SCNVector3(x: v0, y: v1, z: v2)
//
//            case "amp":
//                guard let (v0) = try? message.values.masked(Float.self) else { return }
//                amp = v0
            
            case "rollCorrection":
                let _ = 0
            
            case "yawCorrection":
                let _ = 0


            default:
                print("unable to store osc data")
        }
    }
    
    func asOSC() -> OSCKitCore.OSCMessage {
        // not sending id!!
        
        let id = deviceID
        let msg: OSCMessage = OSCMessage("/\(id)/IMUFusedData", values: [
            accel.x,
            accel.y,
            accel.z,
            quat.w,
            quat.z,
            quat.x,
            quat.y
            ])
        
        
        return msg
    }

}

/*
 
 try? self.client.send(.message("/gyrosc/quat", values: [deviceData.quat.w, deviceData.quat.z, deviceData.quat.x, deviceData.quat.y]),
//                              to: "192.168.1.11",
                       to: "127.0.0.1",
                      port: 3333) // need user to set
*/

//    func sendOSCMessage() {
    
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
//    }

//    func sendOSCConnect() {
//        let msg = try! OSCMessage(with: "/gyrosc/button", arguments: [1.0])
//        try? self.client.send(msg)
//    }


//    func handleOSCMessage(_ message:OSCMessage){
//
//        // encode message.values to deviceData
//        switch (message.addressPattern.pathComponents.last) {
//            case "gyro":
//                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
//                deviceData.gyro = SCNVector3(x: v0, y: v1, z: v2)
//
//            case "quat":
//                // needed to swap order for orientation to work  on node
//                // print(message.values[0].oscValueToken)
//                guard let (v0,v1,v2,v3) = try? message.values.masked(Double.self, Double.self, Double.self, Double.self) else { return }
//                deviceData.quat = SCNQuaternion(x: Float(v2) , y: Float(v3), z: Float(v1), w: Float(v0))
//
//            case "rrate":
//                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
//                deviceData.rrate = SCNVector3(x: v0, y: v1, z: v2)
//
//            case "accel":
//                guard let (v0,v1,v2) = try? message.values.masked(Float.self, Float.self, Float.self) else { return }
//                deviceData.accel = SCNVector3(x: v0, y: v1, z: v2)
//
//            case "amp":
//                guard let (v0) = try? message.values.masked(Float.self) else { return }
//                deviceData.amp = v0
//
//            default:
//                print("unable to store osc data")
//        }
//    }
//
//    func handleJSONString(_ jsonString:String) {
//
//        if let dataFromString = jsonString.data(using: .utf8, allowLossyConversion: false) {
//
//            let json = try! JSON(data: dataFromString)
//
//            deviceData.quat.x = json["quat"][0].floatValue
//            deviceData.quat.y = json["quat"][1].floatValue
//            deviceData.quat.z = json["quat"][2].floatValue
//            deviceData.quat.w = json["quat"][3].floatValue
//
//            deviceData.gyro.x = json["gyro"][0].floatValue
//            deviceData.gyro.y = json["gyro"][1].floatValue
//            deviceData.gyro.z = json["gyro"][2].floatValue
//
//            deviceData.rrate.x = json["rrate"][0].floatValue
//            deviceData.rrate.y = json["rrate"][1].floatValue
//            deviceData.rrate.z = json["rrate"][2].floatValue
//
//            deviceData.accel.x = json["accel"][0].floatValue
//            deviceData.accel.y = json["accel"][1].floatValue
//            deviceData.accel.z = json["accel"][2].floatValue
//
//            deviceData.amp = json["amp"].floatValue
//
//        }
//    }
