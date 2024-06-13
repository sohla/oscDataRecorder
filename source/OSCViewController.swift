//
//  OSCViewController.swift
//  oscDataRecorder
//
//  Created by Stephen OHara on 9/7/18.
//  Copyright © 2018 Stephen OHara. All rights reserved.
//

import UIKit

class OSCViewController: UIViewController {

    @IBOutlet weak var ipAddressTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    
    let ipAddressDelegate = ipAddressTextFieldDelegate()
    let portDelegate = portTextFieldDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()

        ipAddressTextField.delegate = ipAddressDelegate
        portTextField.delegate = portDelegate
        
        ipAddressTextField.keyboardType = .decimalPad
        portTextField.keyboardType = .decimalPad

        ipAddressTextField.text = "no port address"
        ipAddressTextField.text = "no ip address"

        if let ip = UserDefaults.standard.string(forKey: "ipAddress"){
            if let port = UserDefaults.standard.string(forKey: "portAddress"){
                ipAddressTextField.text = ip
                portTextField.text = port
            }
        }
        
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


class ipAddressTextFieldDelegate : NSObject, UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if(isValidIP(s: textField.text!)){
            textField.resignFirstResponder()
            return true
            
        }
        return false
        
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if(isValidIP(s: textField.text!)){
            print("saving"+textField.text!)
            UserDefaults.standard.set(textField.text!, forKey: "ipAddress")
        }
    }
    func isValidIP(s: String) -> Bool {
        let parts = s.components(separatedBy: ".")
        let nums = parts.compactMap { Int($0) }
        return parts.count == 4 && nums.count == 4 && nums.filter { $0 >= 0 && $0 < 256}.count == 4
    }
    
    
}


class portTextFieldDelegate : NSObject, UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if(isValidPort(s: textField.text!)){
            textField.resignFirstResponder()
            return true
            
        }
        return false
        
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if(isValidPort(s: textField.text!)){
            UserDefaults.standard.set(textField.text!, forKey: "portAddress")
        }
    }
    func isValidPort(s: String) -> Bool {
        if let _ = UInt16(s) { return true }
        return false
    }
    
}

