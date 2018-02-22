//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 2/1/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//

import Foundation


func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
