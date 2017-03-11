//
//  Utility.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/11/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import UIKit

struct Utility
{
    func createAlert(withTitle title:String, message:String, sender: UIViewController)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        sender.present(alert, animated: true, completion: nil)
    }
}
