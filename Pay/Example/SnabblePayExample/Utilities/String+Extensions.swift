//
//  String+Extensions.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 05.04.23.
//

import Foundation

public extension String {
    private static let htmlHeader = """
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />
        <style type="text/css">
            pre { font-family: -apple-system, sans-serif; font-size: 15px; white-space: pre-wrap; }
            body { padding: 8px 8px }
            * { font-family: -apple-system, sans-serif; font-size: 15px; word-wrap: break-word }
            *, a { color: #000 }
            h1 { font-size: 22px }
            h2 { font-size: 17px }
            h4 { font-weight: normal; color: #3c3c43; opacity: 0.6 }
            @media (prefers-color-scheme: dark) {
                a, h4, * { color: #fff }
            }
        </style>
    </head>
    <body>
"""
    private static let htmlFooter = """
    </body>
</html>
"""
    
    func htmlString(heading: String? = nil, trailing: String? = nil) -> String {
        let header = heading ?? Self.htmlHeader
        let trailer = trailing ?? Self.htmlFooter
        
        return header + self + trailer
    }
}
