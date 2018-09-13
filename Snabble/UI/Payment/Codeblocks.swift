//
//  Codeblocks.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

class Codeblocks {

    private(set) var config: EncodedCodes

    init(_ config: EncodedCodes) {
        self.config = config
    }

    func generateBlocks(_ regularCodes: [String], _ restrictedCodes: [String]) -> [[String]] {
        let leaveRoom = self.config.nextCode != nil || self.config.nextCodeWithCheck != nil || self.config.finalCode != nil
        let maxCodes = self.config.maxCodes - (leaveRoom ? 1 : 0)

        var regularBlocks = self.blocksFor(regularCodes, maxCodes)
        var restrictedBlocks = self.blocksFor(restrictedCodes, maxCodes)

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
        if let nextCode = self.config.nextCode {
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

        if let nextCodeCheck = self.config.nextCodeWithCheck, restrictedCodes.count > 0 {
            let lastBlock = regularBlocks.count - 1
            if lastBlock >= 0 {
                // if we added a "nextCode" above, undo that for the last block
                if self.config.nextCode != nil {
                    let lastBlockSize = regularBlocks[lastBlock].count
                    regularBlocks[lastBlock].remove(at: lastBlockSize - 1)
                }
                // add the "nextCodeWithCheck" code
                regularBlocks[lastBlock].append(nextCodeCheck)
            } else {
                // there were no regular products, create a new regular block with just the `nextCodeCheck` code
                regularBlocks = [[nextCodeCheck]]
            }
        }

        var codeblocks = regularBlocks
        codeblocks.append(contentsOf: restrictedBlocks)

        for (index, block) in codeblocks.enumerated() {
            print("block \(index): \(block.count) elements, first=\(block[0]), last=\(block[block.count-1])")
        }

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

    
}
