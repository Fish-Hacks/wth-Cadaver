//
//  HandServiceDelegate.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 4/4/23.
//

import Foundation

protocol HandServiceDelegate {
    func didReceiveHand(_ handState: HandState)
}
