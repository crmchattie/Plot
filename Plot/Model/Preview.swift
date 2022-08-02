//
//  Preview.swift
//  Plot
//
//  Created by Cory McHattie on 6/10/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import QuickLook

class Preview: NSObject, QLPreviewItem {
    let url: URL
    let displayName: String
    let fileName: String
    let fileExtension: String
    var thumbnail: UIImage?
    
    init(url: URL, displayName: String, fileName: String, fileExtension: String) {
        self.url = url
        self.displayName = displayName
        self.fileName = fileName
        self.fileExtension = fileExtension
        super.init()
    }
    
    var previewItemTitle: String? {
        return displayName
    }
    
    var formattedFileName: String {
        return "\(displayName).\(fileExtension)"
    }
    
    var previewItemURL: URL? {
        return url
    }
}
