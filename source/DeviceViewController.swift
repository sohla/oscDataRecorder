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
    func updateScene(data: DeviceDataProtocol)
}

class DeviceViewController: UIViewController, DeviceViewControllerDelegate {

    @IBOutlet weak var skView: SCNView!
    @IBOutlet weak var label: UILabel!
    
    let accelScale: Float = 0.05
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView.scene?.background.contents = UIColor.clear
        skView.backgroundColor = UIColor.clear
        
        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
        boxNode?.position = SCNVector3(-6,0,-6)
        
        let boxNode2 = skView.scene?.rootNode.childNode(withName: "box", recursively: true)?.clone()
        boxNode2?.name = "box2"
        skView.scene?.rootNode.addChildNode(boxNode2!)
        boxNode2?.position = SCNVector3(-2,0,-6)

        let boxNode3 = skView.scene?.rootNode.childNode(withName: "box", recursively: true)?.clone()
        boxNode3?.name = "box3"
        skView.scene?.rootNode.addChildNode(boxNode3!)
        boxNode3?.position = SCNVector3(2,0,-6)

        let boxNode4 = skView.scene?.rootNode.childNode(withName: "box", recursively: true)?.clone()
        boxNode4?.name = "box4"
        skView.scene?.rootNode.addChildNode(boxNode4!)
        boxNode4?.position = SCNVector3(6,0,-6)

        label.text = "no device detected"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateScene(data: DeviceDataProtocol){
        
        switch (data.deviceID){
            case "1":
                let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
                boxNode?.orientation = data.quat
                boxNode?.position = SCNVector3(-6,0,-6)
            label.text = "\(data.asOSC().description)"

                let x = boxNode?.childNode(withName: "x", recursively: true)
                x?.scale = SCNVector3(data.accel.x * accelScale,1,1)
                let y = boxNode?.childNode(withName: "y", recursively: true)
                y?.scale = SCNVector3(1,data.accel.y * accelScale,1)
                let z = boxNode?.childNode(withName: "z", recursively: true)
                z?.scale = SCNVector3(1,1,data.accel.z * accelScale)
            break;

            case "2":
                let boxNode = skView.scene?.rootNode.childNode(withName: "box2", recursively: true)
                boxNode?.orientation = data.quat
                boxNode?.position = SCNVector3(-2,0,-6)
            label.text = "\(data.asOSC().description)"

                let x = boxNode?.childNode(withName: "x", recursively: true)
                x?.scale = SCNVector3(data.accel.x * accelScale,1,1)
                let y = boxNode?.childNode(withName: "y", recursively: true)
                y?.scale = SCNVector3(1,data.accel.y * accelScale,1)
                let z = boxNode?.childNode(withName: "z", recursively: true)
                z?.scale = SCNVector3(1,1,data.accel.z * accelScale)
            break;

            case "3":
                let boxNode = skView.scene?.rootNode.childNode(withName: "box3", recursively: true)
                boxNode?.orientation = data.quat
                boxNode?.position = SCNVector3(2,0,-6)

                let x = boxNode?.childNode(withName: "x", recursively: true)
                x?.scale = SCNVector3(data.accel.x * accelScale,1,1)
                let y = boxNode?.childNode(withName: "y", recursively: true)
                y?.scale = SCNVector3(1,data.accel.y * accelScale,1)
                let z = boxNode?.childNode(withName: "z", recursively: true)
                z?.scale = SCNVector3(1,1,data.accel.z * accelScale)
            break;

            case "4":
                let boxNode = skView.scene?.rootNode.childNode(withName: "box4", recursively: true)
                boxNode?.orientation = data.quat
                boxNode?.position = SCNVector3(6,0,-6)

                let x = boxNode?.childNode(withName: "x", recursively: true)
                x?.scale = SCNVector3(data.accel.x * accelScale,1,1)
                let y = boxNode?.childNode(withName: "y", recursively: true)
                y?.scale = SCNVector3(1,data.accel.y * accelScale,1)
                let z = boxNode?.childNode(withName: "z", recursively: true)
                z?.scale = SCNVector3(1,1,data.accel.z * accelScale)
            break;

            default:
                label.text = "no device detected"
        }
        
    }
}

