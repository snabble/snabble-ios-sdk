//
//  QRCodeView.swift
//  SnabblePayExample
//
//  Created by Andreas Osberghaus on 2023-01-26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let code: String

    private var qrCodeImage: UIImage {
        guard let image = code.qrCodeImage else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }
        return image
    }

    var body: some View {
        Image(uiImage: qrCodeImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .background(Color.white)
            .cornerRadius(4.0)
    }
}

private extension String {
    var qrCodeImage: UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(self.utf8)

        if let outputImage = filter.outputImage {
            let maskFilter = CIFilter.blendWithMask()
            maskFilter.maskImage = outputImage.applyingFilter("CIColorInvert")

            maskFilter.inputImage = CIImage(color: .black)
            let blackCIImage = maskFilter.outputImage!

            let blackImage = context.createCGImage(blackCIImage, from: blackCIImage.extent).map(UIImage.init)!

            return blackImage
        }
        return nil
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(code: "Hello, World!")
    }
}
