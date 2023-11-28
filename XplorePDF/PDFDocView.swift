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
   @State var workTitle = ""
   @State var workAuthors = ""
   @State var workAuthorKeywords = ""
   @State var workAbstract = ""
   @StateObject var viewTracker = Tracker("updateView")
   @StateObject var notifyTracker = Tracker("Notify")
   @StateObject var wrappedSelection: SelectionWrapper = SelectionWrapper()

   var body: some View {
      NavigationStack {
         VStack(alignment: .leading) {
            HStack {
               Text(doc.documentPathLast)
               Spacer()
               Button("Update extract", action: updateExtract)
            }
            Spacer()
            TextField("Title", text: $workTitle)
               .dropDestination(for: String.self) { strings, dest in
                  let temp = joinStrings(strings)
                  guard temp != "" else {return false}
                  workTitle += temp
                  return true
               }
            TextField("Authors", text: $workAuthors)
               .dropDestination(for: String.self) { strings, dest in
                  let temp = joinStrings(strings)
                  guard temp != "" else {return false}
                  workAuthors += temp
                  return true
               }
            TextField("Author Keywords", text: $workAuthorKeywords)
               .dropDestination(for: String.self) { strings, dest in
                  let temp = joinStrings(strings)
                  guard temp != "" else {return false}
                  workAuthorKeywords += temp
                  return true
               }
            Text("Abstract:")
            TextEditor(text: $workAbstract)
               .padding(2)
               .border(Color.cyan, width: 2)
               .dropDestination(for: String.self) { strings, dest in
                  let temp = joinStrings(strings)
                  guard temp != "" else {return false}
                  workAbstract += temp
                  return true
               }
            PDFViewRepresentable(doc: doc.doc, viewTracker: viewTracker,
                                 notifyTracker: notifyTracker,
                                 wrappedSelection: wrappedSelection)
            .draggable(getSelected4Drop()) {
               Text(getSelected4Preview())
            }
#if os(macOS)
            .copyable(copySelected2Array())
#endif
         }
      }.onAppear(perform: {getExtracted()})
   }
   
   //Helpers
   func getExtracted() {
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
   func copySelected2Array() -> [String] {
      Array(arrayLiteral: wrappedSelection.selection?.string ?? "")
   }
   func getSelected4Drop() -> String {
      wrappedSelection.selection?.string ?? ""
   }
   func getSelected4Preview() -> String {
      wrappedSelection.selection?.string ?? "No Selection"
   }
   func joinStrings(_ strings: [String]) -> String {
      guard !strings.isEmpty else {return ""}
      var target = ""
      for str in strings {
         target += str
      }
      return target
   }
}

// Wrapper for the PDFKit PDFView
struct PDFViewRepresentable: ViewRepresentable {
   let doc: PDFDocument
   @ObservedObject var viewTracker : Tracker
   @ObservedObject var notifyTracker: Tracker
   @ObservedObject var wrappedSelection: SelectionWrapper
   
   // Class to coordinate for ViewRepresentable and the wrapped NSView or UIView
   // This would become the view delegate if we needed one
   class Coordinator : NSObject {
      var wrappedSelection : SelectionWrapper
      var view: PDFView? = nil
      var protoObject : NSObjectProtocol? = nil
      var notifyTracker: Tracker
      init(_ ws: SelectionWrapper, tracker nt: Tracker) {
         wrappedSelection = ws
         notifyTracker = nt
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
            notifyTracker.log(view.currentSelection?.string ?? "No text")
            if wrappedSelection.selection != view.currentSelection {
               wrappedSelection.selection = view.currentSelection
            }
         } else {
            notifyTracker.log("Not from PDFView")
         }
      }
   }

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
   func makeCoordinator() -> Coordinator {
      return Coordinator(wrappedSelection, tracker: notifyTracker)
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
      // things to do for updates?
      viewTracker.log("updateView called")
   }
   
}


// Inspection class for learning how ViewRepresentatable works with SwiftUI
class Tracker : ObservableObject {
   var name: String
   var called = 0
   var trace: [String] = []
   
   init(_ n: String) {
      name = n
   }
   func log(_ activity: String) -> Void {
      self.called += 1
      self.trace.append("\(called) " + activity)
   }
}
      
// ObservableObject wrapper for the PDFSelection
class SelectionWrapper : NSObject, ObservableObject {
   @Published var selection : PDFSelection? = nil
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
