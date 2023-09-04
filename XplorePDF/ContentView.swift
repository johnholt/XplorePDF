//
//  ContentView.swift
//  XplorePDF
//
//  Created by John Holt on 7/30/23.
//

import SwiftUI
import PDFKit

struct ContentView: View {
   @State var showFileImport = false
   @StateObject var docList: MyDocList = MyDocList()
   @State var currentStatus : String = "No Docs"
   
   var body: some View {
      NavigationStack {
         ScrollView {
            VStack {
               HStack {
                  Text(currentStatus)
                  Button("Clear list", action: clearDocs)
                  Button("Import", action: {showFileImport=true})
               }
               Spacer()
               ForEach(docList.docs, id: \.id) { doc in
                  VStack {
                     HStack {
                        Text(doc.documentPathLast)
                        NavigationLink {
                           AttributeListView(attributes: doc.fileAttributes)
                        } label: {
                           Label("\(doc.fileAttributes.count) file attributes",
                                 systemImage: "doc.text")
                        }
                        NavigationLink {
                           AttributeListView(attributes: doc.pdfAttributes)
                        } label: {
                           Label("\(doc.pdfAttributes.count) PDF attributes:",
                                 systemImage: "doc.text")
                        }
                     }
                     HStack {
                        Text(doc.docTitle)
                        Spacer()
                        NavigationLink {
                           PDFDocView(doc: doc)
                        } label: {
                           Label("PDF Content", systemImage: "doc.text")
                        }
                     }
                     Spacer()
                  }
               }
            }
         }
      }
      .fileImporter(isPresented: $showFileImport,
                    allowedContentTypes: [.pdf],
                    allowsMultipleSelection: true,
                    onCompletion: getDocs)
   }
   
   func getDocs(rslt : Result<[URL], Error>) -> Void {
      var firstURL = true
      currentStatus = ""
      switch rslt {
         case .success(let urls):
            let newList = getDocuments(urlList: urls)
            for url in newList.failed {
               currentStatus += firstURL
               ? "Failed to read: "
               : ", "
               let str = url.absoluteString
               currentStatus += str
               firstURL = false
            }
            docList.append(docs:  newList.docs)
         case .failure(let err):
            currentStatus = err.localizedDescription
      }
   }
   
   func clearDocs() -> Void {
      docList.clear()
      currentStatus = "No docs"
   }
}

// Attribute Content View
struct AttributeListView: View {
   let attributes : [DisplayableAttribute]
   
   var body: some View {
      ScrollView {
         LazyVStack {
            ForEach(attributes, id: \.id) { attr in
               let work = attr.name + "=" + attr.value
               Text(work)
            }
         }
      }
   }
}


// Data retrieval functions
func getDocuments(urlList: [URL]) -> (docs: [MyDocument], failed: [URL]) {
   var resultDocs : [MyDocument] = []
   var failures: [URL] = []
   for url in urlList {
      var fileAttributes : [DisplayableAttribute] = []
      var pdfAttributes : [DisplayableAttribute] = []
      let path = url.path
      if let fileAttrs = try? FileManager.default
         .attributesOfItem(atPath: path) {
         for (attrName, attrValue) in fileAttrs {
            let work = String(reflecting: attrValue)
            let id = UInt16(fileAttributes.count + 1)
            let pair = DisplayableAttribute(id: id,
                                            name: attrName.rawValue,
                                            value: work)
            fileAttributes.append(pair)
         }
      } else {
         failures.append(url)
         continue
      }
      if let doc = PDFDocument(url: url) {
         if let workAttrs = doc.documentAttributes {
            for (attrName, attrValue) in workAttrs {
               let name = String(describing: attrName)
               let value = String(reflecting: attrValue)
               let id = UInt16(pdfAttributes.count + 1)
               pdfAttributes.append(DisplayableAttribute(id: id,
                                                         name: name,
                                                         value: value))
            }
         }
         let id : UInt32 = UInt32(resultDocs.count) + 1
         let path = doc.documentURL?.path ?? "No URL"
         let pathLast = doc.documentURL?.lastPathComponent ?? ""
         let pathExt = doc.documentURL?.pathExtension ?? ""
         let work = MyDocument(id: id,
                               documentPath: path,
                               documentPathLast: pathLast,
                               documentPathExt: pathExt,
                               fileAttributes: fileAttributes,
                               pdfAttributes: pdfAttributes,
                               doc: doc)
         resultDocs.append(work)
      } else {
         failures.append(url)
      }
   }
   return (resultDocs, failures)
}


// Data model structures
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
class MyDocument : Identifiable, ObservableObject {
   let id : UInt32
   var documentPath : String
   var documentPathLast : String
   var documentPathExt : String
   var fileAttributes : [DisplayableAttribute]
   var pdfAttributes : [DisplayableAttribute]
   var doc: PDFDocument
   //@Published var extract : DocExtract = DocExtract()
   @Published var docTitle : String = ""
   @Published var docAuthors : String = ""
   @Published var docAbstract: String = ""
   @Published var docAuthorKeywords : String = ""

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
}
class MyDocList: ObservableObject {
   @Published var docs : [MyDocument]
   
   init(docs: [MyDocument]) {
      self.docs = docs
   }
   init() {
      docs = []
   }
   
   func append(docs: [MyDocument]) {
      self.docs += docs
   }
   func clear() {
      self.docs = []
   }
}

// Previews
struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      ContentView(docList: MyDocList(docs: work.docs))
   }
   
   static let urls = Bundle.main.urls(
      forResourcesWithExtension: "pdf", subdirectory: "") ?? []
   
   static let work = getDocuments(urlList: urls)
}
