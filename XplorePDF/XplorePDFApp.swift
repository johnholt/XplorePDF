//
//  XplorePDFApp.swift
//  XplorePDF  An application used to explore how to programmatically
//extract information from PDF files with user guidance.  The information
//extract buiilt is only kept while the program is running.
//
//  Created by John Holt on 7/30/23.
// Copyright 2023 by John Holt.
//

import SwiftUI

var docList = MyDocList()

@main
struct XplorePDFApp: App {
    var body: some Scene {
        WindowGroup {
           ContentView(docList: docList)
        }
    }
}
