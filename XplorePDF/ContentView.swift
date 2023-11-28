//
//  ContentView.swift
//  XplorePDF
//
//  Created by John Holt on 7/30/23.
//

import SwiftUI
import PDFKit

struct ContentView: View {
   @State private var showFileImport = false
   @ObservedObject var docList: MyDocList
   @State private var currentStatus : String = "No Docs"
   
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
               ForEach($docList.docs, id: \.id) { $doc in
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
                           PDFDocView(doc:  $doc)
                        } label: {
                           Label("Extract from PDF View", systemImage: "doc.text")
                        }
                        Spacer()
                        NavigationLink {
                           PDFTextView(doc: $doc)
                        } label: {
                           Label("Extract frpm PDF text tokens", systemImage: "doc.text")
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
            let newList = getDocuments(urlList: urls,
                                       prevCount: UInt32(docList.docs.count))
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
func getDocuments(urlList: [URL], prevCount: UInt32)
-> (docs: [MyDocument], failed: [URL]) {
   var resultDocs : [MyDocument] = []
   var failures: [URL] = []
   var numDocs = UInt32(0)
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
      if !url.startAccessingSecurityScopedResource() {
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
         numDocs += 1
         let id = prevCount + numDocs
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
      url.stopAccessingSecurityScopedResource()
   }
   return (resultDocs, failures)
}




// Previews
struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      ContentView(docList: docList)
   }
   
   static let urls = Bundle.main.urls(
      forResourcesWithExtension: "pdf", subdirectory: "") ?? []
   
   static var work = getDocuments(urlList: urls, prevCount: 0)
   
   static var docList = MyDocList(docs: work.docs)
}
