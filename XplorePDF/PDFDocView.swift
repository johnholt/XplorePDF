//
//  PDFDocView.swift
//  XplorePDF
//
//  Created by John Holt on 8/16/23.
//

import SwiftUI
import PDFKit

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
typealias ViewRepContext = NSViewRepresentableContext
#else
typealias ViewRepresentable = UIViewRepresentable
typealias ViewRepContext = UIViewRepresentableContext
#endif


struct PDFDocView: View {
   @Binding var doc: MyDocument
   @State var workTitle = ""
   @State var workAuthors = ""
   @State var workAuthorKeywords = ""
   @State var workAbstract = ""
   @StateObject var tracker = Tracker()
   
   var body: some View {
      NavigationStack {
         VStack(alignment: .leading) {
            HStack {
               Text(doc.documentPathLast)
               Spacer()
               Button("Update extract", action: updateExtract)
            }
            TextField("Title", text: $workTitle)
            TextField("Authors", text: $workAuthors)
            TextField("Author Keywords", text: $workAuthorKeywords)
            Text("Abstract:")
            TextEditor(text: $workAbstract)
               .padding(2)
               .border(Color.cyan, width: 2)
            PDFViewRepresentable(doc: doc.doc, tracker: tracker)
         }
      }.onAppear(perform: {getExtract()})
   }
   
   //Helpers
   func getExtract() {
      workTitle = doc.docTitle
      workAuthors = doc.docAuthors
      workAuthorKeywords = doc.docAuthorKeywords
      workAbstract = doc.docAbstract
   }
   func updateExtract() -> Void {
      doc.docTitle = workTitle
      doc.docAuthors = workAuthors
      doc.docAuthorKeywords = workAuthorKeywords
      doc.docAbstract = workAbstract
   }
}

// Wrapper for the PDFKit PDFView
struct PDFViewRepresentable: ViewRepresentable {
   let doc: PDFDocument
   var tracker : Tracker

   // Platform specific interface shim
#if os(macOS)
   func makeNSView(context: ViewRepContext<PDFViewRepresentable>) -> PDFView {
      return makeView(ctx: context)
   }
   func updateNSView(_ v: PDFView, context: ViewRepContext<PDFViewRepresentable>) {
      updateView(v, ctx: context)
   }
#else
   func makeUIView(context: ViewRepContext<PDFViewRepresentable>) -> PDFView {
      return makeView(ctx: context)
   }
   func updateUIView(_ v: PDFView, context: ViewRepContext<PDFViewRepresentable>) {
      updateView(v, ctx: context)
   }
#endif
   
   // Generic helpers for UIkit or AppKit Views for SwiftUI compatibility
   func makeView(ctx: ViewRepContext<PDFViewRepresentable>) -> PDFView {
      let pdfView = PDFView()
      pdfView.document = self.doc
      return pdfView
   }
   
   func updateView(_ view: PDFView,
                   ctx: ViewRepContext<PDFViewRepresentable>) {
      // things to do for updates?
      tracker.update()
   }
}

// Inspection class for learning how ViewRepresentatable works with SwiftUI
class Tracker : ObservableObject {
   var updated = 0
   
   func update() -> Void {
      self.updated += 1
   }
}

// Gettiing data into Preview the old way
struct PDFDocView_Previews: PreviewProvider {
   static var previews: some View {
      PDFDocView(doc: boundDoc)
   }

   static let url = Bundle.main.url(forResource: "DATAK_2005",
                                    withExtension: "pdf")
   static let urls = [url!]
   static let work = getDocuments(urlList: urls, prevCount: 0)
   static var workDoc = work.docs.isEmpty ? MyDocument() : work.docs[0]
   static let boundDoc = Binding<MyDocument>(get: {return workDoc},
                                             set: {d in workDoc = d})
}
