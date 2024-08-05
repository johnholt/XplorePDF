//
//  DataModel.swift
//  XplorePDF
//
//  Created by John Holt on 10/31/23.
//

import Foundation
import CoreTransferable
import PDFKit
import UniformTypeIdentifiers


// Data model structures

// The type of document content of this extract
enum ExtractType : Codable {
   case title
   case authors
   case authorKeywords
   case abstract
   case unknown
   case custom(String)
}

struct ExtractSelection : Codable {
   var type : ExtractType = .unknown
   var pageIndex: Int = 0
   var begin : CGPoint
   var end : CGPoint
   var text : String 
}

extension ExtractSelection : Transferable {
   static var transferRepresentation: some TransferRepresentation {
      CodableRepresentation(for: ExtractSelection.self, contentType: .pdfSelection)
      ProxyRepresentation(exporting: \.text)
   }
}

extension UTType {
   static var pdfSelection: UTType { UTType(exportedAs: "com.jdholt77.typedpdfselection")}
}

struct DisplayableAttribute : Hashable {
   let id : UInt16
   var name : String
   var value : String
}
struct DocExtract {
   var docTitle : String = ""
   var docAuthors : String = ""
   var docAbstract: String = ""
   var docAuthorKeywords : String = ""
}
struct MyDocument : Identifiable {
   let id : UInt32
   var documentPath : String
   var documentPathLast : String
   var documentPathExt : String
   var fileAttributes : [DisplayableAttribute]
   var pdfAttributes : [DisplayableAttribute]
   var doc: PDFDocument
   var docTitle : String = ""
   var docAuthors : String = ""
   var docAbstract: String = ""
   var docAuthorKeywords : String = ""
   
   init(id: UInt32, documentPath: String, documentPathLast: String,
        documentPathExt: String, fileAttributes: [DisplayableAttribute],
        pdfAttributes: [DisplayableAttribute], doc: PDFDocument) {
      self.id = id
      self.documentPath = documentPath
      self.documentPathLast = documentPathLast
      self.documentPathExt = documentPathExt
      self.fileAttributes = fileAttributes
      self.pdfAttributes = pdfAttributes
      self.doc = doc
   }
   init() {
      self.id = 0
      self.documentPath = ""
      self.documentPathLast = ""
      self.documentPathExt = ""
      self.fileAttributes = []
      self.pdfAttributes = []
      self.doc = PDFDocument()
   }
}
class MyDocList: ObservableObject {
   @Published var docs : Array<MyDocument>
   
   init(docs: [MyDocument]) {
      self.docs = docs
   }
   init() {
      docs = Array()
   }
   
   func append(docs newDocs: [MyDocument]) {
      self.docs += newDocs
   }
   func clear() {
      self.docs.removeAll()
   }
}

