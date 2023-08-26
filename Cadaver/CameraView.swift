//
//  CameraView.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 26/8/23.
//

import Foundation
import UIKit
import SwiftUI
import Vision

struct CameraView: UIViewRepresentable {
    var randomPhotoCallback: ((UIImage) -> Void)?

    func makeUIView(context: Context) -> CameraPreview {
        CameraPreview()
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {}
}
