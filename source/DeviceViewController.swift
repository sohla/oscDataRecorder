//
//  DeviceViewController.swift
//  oscDataRecorder
//
//  Created by Stephen OHara on 6/7/18.
//  Copyright © 2018 Stephen OHara. All rights reserved.
//

import UIKit
import SceneKit



struct DeviceData {
    
    var gyro: SCNVector3 = SCNVector3()
    var quat: SCNQuaternion = SCNQuaternion()
    var rrate: SCNVector3 = SCNVector3()
    var accel: SCNVector3 = SCNVector3()
    
    func description() -> String {
        
        var s = ""
        s += "gyro{"
        s += String(gyro.x) + "," + String(gyro.y) + "," + String(gyro.z) + "}, "
        s += "quat{"
        s += String(quat.x) + "," + String(quat.y) + "," + String(quat.z) + "," + String(quat.w) + "}, "
        s += "rrate{"
        s += String(rrate.x) + "," + String(rrate.y) + "," + String(rrate.z) + "}, "
        s += "accel{"
        s += String(accel.x) + "," + String(accel.y) + "," + String(accel.z) + "}"

        return s
        
    }
}

protocol DeviceViewControllerDelegate {
    
    func updateWithData(_ dd:DeviceData)
}

class DeviceViewController: UIViewController,DeviceViewControllerDelegate {

    @IBOutlet weak var skView: SCNView!
    

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
    
    func updateWithData(_ dd:DeviceData){

        let boxNode = skView.scene?.rootNode.childNode(withName: "box", recursively: true)
//        var modelMatrix = SCNMatrix4Identity
//        let quatMatrix = SCNMatrix4MakeRotation(dd.quat.w * Float.pi, dd.quat.x, dd.quat.y, dd.quat.z)
//        modelMatrix = SCNMatrix4Mult(modelMatrix, quatMatrix)
//        boxNode?.setWorldTransform(modelMatrix)

        //boxNode?.eulerAngles = dd.gyro
        boxNode?.orientation = dd.quat
        print(dd.description())

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
