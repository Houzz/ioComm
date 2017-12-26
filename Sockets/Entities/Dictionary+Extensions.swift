//
//  Dictionary+Extensions.swift
//  Sockets
//
//  Created by Maxim on 26/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation

extension Dictionary {
    
    mutating func safe(set object: Value?, for key: Key) {
        if let object = object {
            self[key] = object
        }
    }

}
