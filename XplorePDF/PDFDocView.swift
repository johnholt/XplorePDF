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
typealias ViewRepresentableContext = NSViewRepresentableContext
#else
typealias ViewRepresentable = UIViewRepresentable
typealias ViewRepresentableContext = UIViewRepresentableContext
#endif


struct PDFDocView: View {
   @ObservedObject var doc: MyDocument
   @State var workTitle = ""
   @State var workAuthors = ""
   @State var workAuthorKeywords = ""
   @State var workAbstract = ""
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
            PDFViewRepresentable(doc: doc.doc)
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

#if os(macOS)
   func makeNSView(context: ViewRepresentableContext<PDFViewRepresentable>)
   -> PDFView {
      let pdfView = PDFView()
      pdfView.document = self.doc
      return pdfView
   }
#else
   func makeUIView(context: ViewRepresentableContext<PDFViewRepresentable>)
   -> PDFView {
      let pdfView = PDFView()
      pdfView.document = self.doc
      return pdfView
   }
#endif
   
#if os(macOS)
   func updateNSView(_ nsView: PDFView,
                     context: ViewRepresentableContext<PDFViewRepresentable>) {
      // things to do for updates?
   }
#else
   func updateUIView(_ uiView: PDFView,
                     context: ViewRepresentableContext<PDFViewRepresentable>) {
      // things to do for updates?
   }
#endif
}

struct PDFDocView_Previews: PreviewProvider {
   static var previews: some View {
      PDFDocView(doc: work.docs[0])
   }
   static let url = Bundle.main.url(forResource: "DATAK_2005",
                                    withExtension: "pdf")
   static let urls = [url!]
   static let work = getDocuments(urlList: urls)
}
