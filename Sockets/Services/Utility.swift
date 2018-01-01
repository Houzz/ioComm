//
//  Utility.swift
//  Sockets
//
//  Created by Maxim on 01/01/2018.
//  Copyright © 2018 Maxim. All rights reserved.
//

import Foundation

internal func strongMainAsync<Type : AnyObject>(weak obj: Type, _ closure: @escaping (Type)->()) {
    DispatchQueue.main.async(execute: strongify(weak: obj, closure))
}

internal func strongify<Type : AnyObject>(weak obj: Type, _ closure: @escaping (Type)->()) -> (()->()) {
    return { [weak obj] in
        if let strong = obj {
            closure(strong)
        }
    }
}
