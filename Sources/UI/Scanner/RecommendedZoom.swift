//
//  RecommendedZoomFactor.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import AVFoundation

/*
Code adapted from Apple's "AvCamBarcode" example project, found at
https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcambarcode_detecting_barcodes_and_faces

Copyright © 2021 Apple Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

@available(iOS 15, *)
public enum RecommendedZoom {
    public static var defaultBarcodeWidth: Int { 50 }

    public static func factor(for videoInput: AVCaptureDeviceInput, codeWidth: Int?) -> Float {
        let deviceMinimumFocusDistance = Float(videoInput.device.minimumFocusDistance)
        guard deviceMinimumFocusDistance != -1 else {
            return 1
        }

        let deviceFieldOfView = videoInput.device.activeFormat.videoFieldOfView
        let minimumSubjectDistanceForCode = minimumSubjectDistanceForCode(fieldOfView: deviceFieldOfView, width: codeWidth ?? defaultBarcodeWidth)
        if minimumSubjectDistanceForCode < deviceMinimumFocusDistance {
            let zoomFactor = deviceMinimumFocusDistance / minimumSubjectDistanceForCode
            return min(zoomFactor, Float(videoInput.device.maxAvailableVideoZoomFactor))
        }
        return 1
    }

    private static func minimumSubjectDistanceForCode(fieldOfView: Float, width: Int) -> Float {
        /*
         Given the camera horizontal field of view, compute the distance (mm) to make a code
         of `minimumCodeSize` (mm) fill the screen width
         */
        let radians = degreesToRadians(fieldOfView / 2)
        return Float(width) / tan(radians)
    }

    private static func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * .pi / 180
    }
}
