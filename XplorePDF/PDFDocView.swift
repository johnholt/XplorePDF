//
//  PDFDocView.swift
//  XplorePDF
//
//  Created by John Holt on 8/16/23.
//

import SwiftUI
import PDFKit
import Foundation

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
typealias ViewRepContext = NSViewRepresentableContext
#else
typealias ViewRepresentable = UIViewRepresentable
typealias ViewRepContext = UIViewRepresentableContext
#endif


struct PDFDocView: View {
   @Binding var doc: MyDocument
   @State private var selected: String = ""

   var body: some View {
      NavigationStack {
         VStack(alignment: .leading) {
            PDFExtractFields(doc: $doc, extracted: $selected)
            PDFViewRepresentable(doc: doc.doc, selected: $selected)
               .draggable(selected) {
                  Text(selected)
               }
#if os(macOS)
               .copyable(Array(arrayLiteral: selected))
#endif
         }
      }
   }
}

// Wrapper for the PDFKit PDFView
struct PDFViewRepresentable: ViewRepresentable {
   let doc: PDFDocument
   var selected : Binding<String>
   
   // Class to coordinate for ViewRepresentable and the wrapped NSView or UIView
   // This would become the view delegate if we needed one
   class Coordinator : NSObject {
      var selected: Binding<String>
      var view: PDFView? = nil
      var protoObject : NSObjectProtocol? = nil
      init(_ s : Binding<String>) {
         selected = s
      }
      // add a notification receiver
      func addNoteRecvr(_ view: PDFView) -> Void {
         let center = NotificationCenter.default
         protoObject = center.addObserver(
                           forName: Notification.Name.PDFViewSelectionChanged,
                           object: view, queue: nil,
                           using: process(_:))
      }
      // remove the notification receiver to stop notification
      func removeNoteRecvr() -> Void {
         let center = NotificationCenter.default
         center.removeObserver(protoObject as Any)
      }
      // Process the notification, which must be PDFViewSelectionChanged
      func process(_ note: Notification) -> Void {
         if let view = note.object as? PDFView {
            if selected.wrappedValue != view.currentSelection?.string {
               selected.wrappedValue = view.currentSelection?.string ?? ""
            }
         }
      }
   } // end of Coordinator class definition

   // Platform specific interface shim
#if os(macOS)
   func makeNSView(context: ViewRepContext<PDFViewRepresentable>) -> PDFView {
      return makeView(ctx: context)
   }
   func updateNSView(_ v: PDFView, context: ViewRepContext<PDFViewRepresentable>) {
      updateView(v, ctx: context)
   }
   static func dismantleNSView(_ nsView: PDFView, coordinator: Coordinator) {
      coordinator.removeNoteRecvr()
   }
#else
   func makeUIView(context: ViewRepContext<PDFViewRepresentable>) -> PDFView {
      return makeView(ctx: context)
   }
   func updateUIView(_ v: PDFView, context: ViewRepContext<PDFViewRepresentable>) {
      updateView(v, ctx: context)
   }
   static func dismantleUIView(_ view: PDFView, coordinator: Coordinator) {
      coordinator.removeNoteRecvr()
   }
#endif
   // functions
   func makeCoordinator() -> Coordinator {
      return Coordinator(selected)
   }
   
   // Generic helpers for UIkit or AppKit Views for SwiftUI compatibility
   func makeView(ctx: ViewRepContext<PDFViewRepresentable>) -> PDFView {
      let pdfView = PDFView()
      pdfView.document = self.doc
      ctx.coordinator.view = pdfView
      ctx.coordinator.addNoteRecvr(pdfView)
      return pdfView
   }
   func updateView(_ view: PDFView,
                   ctx: ViewRepContext<PDFViewRepresentable>) {
      // things to do for updates.  In this case, a PDFView does not have any
      // properties that would be controlled in other parts of the UI under
      // SwiftUI control
   }
   // End generic SwiftUI helpers for UIKit/AppKit views
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
