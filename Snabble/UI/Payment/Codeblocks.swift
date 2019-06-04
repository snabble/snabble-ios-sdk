//
//  Codeblocks.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

final class Codeblocks {

    private(set) var config: QRCodeConfig

    init(_ config: QRCodeConfig) {
        self.config = config
    }

    func generateBlocks(_ regularCodes: [String], _ restrictedCodes: [String]) -> [[String]] {
        let leaveRoom = self.config.nextCode != nil || self.config.nextCodeWithCheck != nil || self.config.finalCode != nil
        let maxCodes = self.config.maxCodes - (leaveRoom ? 1 : 0)

        var regularBlocks = self.blocksFor(regularCodes, maxCodes)
        var restrictedBlocks = self.blocksFor(restrictedCodes, maxCodes)

        var nextCode = self.config.nextCode ?? ""
        if let nextCheck = self.config.nextCodeWithCheck, restrictedCodes.count > 0 {
            nextCode = nextCheck
        }

        // if possible, merge the last regular and the last restricted block
        if regularBlocks.count > 1 && restrictedBlocks.count > 0 {
            let lastRegularBlock = regularBlocks.count - 1
            let lastRestrictedBlock = restrictedBlocks.count - 1
            if regularBlocks[lastRegularBlock].count + restrictedBlocks[lastRestrictedBlock].count <= maxCodes {
                restrictedBlocks[lastRestrictedBlock].append(contentsOf: regularBlocks[lastRegularBlock])
                regularBlocks.remove(at: lastRegularBlock)
            }
        }

        // append "nextCode" to all blocks but the last
        if nextCode.count > 0 {
            if regularBlocks.count > 0 {
                let upper = restrictedBlocks.count > 0 ? regularBlocks.count : regularBlocks.count - 1
                for i in 0 ..< upper {
                    regularBlocks[i].append(nextCode)
                }
            }

            if restrictedBlocks.count > 1 {
                for i in 0 ..< restrictedBlocks.count - 1 {
                    restrictedBlocks[i].append(nextCode)
                }
            }
        }

        // append "finalCode" to the last block
        if let final = self.config.finalCode {
            if restrictedBlocks.count > 0 {
                restrictedBlocks[restrictedBlocks.count - 1].append(final)
            } else {
                regularBlocks[regularBlocks.count - 1].append(final)
            }
        }

        if restrictedCodes.count > 0 && regularBlocks.count == 0 && nextCode.count > 0 {
            // there were no regular products, create a new regular block with just the `nextCodeCheck` code
            regularBlocks = [[nextCode]]
        }

        var codeblocks = regularBlocks
        codeblocks.append(contentsOf: restrictedBlocks)

//        for (index, block) in codeblocks.enumerated() {
//            Log.debug("block \(index): \(block.count) elements, first=\(block[0]), last=\(block[block.count-1])")
//        }

        return codeblocks
    }

    func generateQrCodes(_ regularCodes: [String], _ restrictedCodes: [String]) -> [String] {
        let codeblocks = self.generateBlocks(regularCodes, restrictedCodes)
        return codeblocks.map { self.qrCodeContent($0) }
    }

    private func qrCodeContent(_ codes: [String]) -> String {
        return self.config.prefix + codes.joined(separator: self.config.separator) + self.config.suffix
    }

    private func blocksFor(_ codes: [String], _ blockSize: Int) -> [[String]] {
        return stride(from: 0, to: codes.count, by: blockSize).map {
            Array(codes[$0 ..< min($0 + blockSize, codes.count)])
        }
    }

    func generateQrCodes(_ regularCodes: [String], _ restrictedCodes: [String], maxCodeSize: Int) -> [String] {
        let availableSize = maxCodeSize - self.config.suffix.count - (self.config.finalCode?.count ?? 0) - self.config.separator.count

        var nextCode = self.config.nextCode ?? ""
        if let nextCheck = self.config.nextCodeWithCheck, restrictedCodes.count > 0 {
            nextCode = nextCheck
        }

        var codes = [String]()

        var currentCode = self.config.prefix
        var sep = ""

        if regularCodes.count == 0 {
            let code = self.config.prefix + nextCode + self.config.suffix
            codes.append(code)
        }
        for code in regularCodes {
            let addition = sep + code
            sep = self.config.separator

            if currentCode.count + addition.count > availableSize {
                currentCode += sep + nextCode + self.config.suffix
                codes.append(currentCode)
                currentCode = self.config.prefix + code
            } else {
                currentCode += addition
            }
        }

        if restrictedCodes.count > 0 && currentCode.count > self.config.prefix.count {
            currentCode += self.config.separator + nextCode
            currentCode += self.config.suffix
            codes.append(currentCode)
            currentCode = self.config.prefix
            sep = ""
        }

        for code in restrictedCodes {
            let addition = sep + code
            sep = self.config.separator

            if currentCode.count + addition.count > availableSize {
                currentCode += sep + nextCode + self.config.suffix
                codes.append(currentCode)
                currentCode = self.config.prefix + code
            } else {
                currentCode += addition
            }
        }

        if currentCode.count > self.config.prefix.count {
            if let final = self.config.finalCode {
                currentCode += self.config.separator + final
            }
            currentCode += self.config.suffix
            codes.append(currentCode)
        }

        return codes
    }
    
}
