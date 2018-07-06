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
    
    var quat: SCNQuaternion
    var rrat: SCNVector3
    
    func description() -> String {
        
        var s = ""
        s += "quat{"
        s += String(quat.x) + "," + String(quat.y) + "," + String(quat.z) + "," + String(quat.w) + "}, "
        s += "rrat{"
        s += String(rrat.x) + "," + String(rrat.y) + "," + String(rrat.z) + "}"
        
        return s
        
    }
}

protocol DeviceViewControllerDelegate {
    
    func updateWithData() -> DeviceData
}

class DeviceViewController: UIViewController {

    @IBOutlet weak var skView: SCNView!
    
    var delegate: DeviceViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        skView.scene?.background.contents = UIColor.clear
        skView.backgroundColor = UIColor.clear
        
        let dd = delegate?.updateWithData()
        
        print(dd?.description())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
