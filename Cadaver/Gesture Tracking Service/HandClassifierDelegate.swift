//
//  HandClassifierDelegate.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 4/4/23.
//

import Foundation

protocol HandClassifierDelegate {
    func handClassificationDidUpdate(_ classification: HandClassifier.HandClassification, centerPoint: CGPoint)
}
