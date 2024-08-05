//
//  PDFExtractFields.swift
//  XplorePDF
//
//  Created by John Holt on 7/25/24.
//

import SwiftUI

struct PDFExtractFields: View {
   @Binding var doc: MyDocument
   @Binding var extracted: String
   @State private var workTitle = ""
   @State private var workAuthors = ""
   @State private var workAuthorKeywords = ""
   @State private var workAbstract = ""
   @State private var extractChanged = false
   
    var body: some View {
       VStack(alignment: .leading) {
          HStack {
             Text(doc.documentPathLast)
             Spacer()
             Button("Revert changes", action: getExtracted)
                .disabled(!extractChanged)
          }
          Spacer()
          TextField("Title", text: $workTitle)
             .dropDestination(for: String.self) { strings, dest in
                return storeWork(strings, target: &workTitle)
             }
             .onChange(of: workTitle) {extractChanged=true}
          TextField("Authors", text: $workAuthors)
             .dropDestination(for: String.self) { strings, dest in
                return storeWork(strings, target: &workAuthors)
             }
             .onChange(of: workAuthors) {extractChanged=true}
          TextField("Author Keywords", text: $workAuthorKeywords)
             .dropDestination(for: String.self) { strings, dest in
                return storeWork(strings, target: &workAuthorKeywords)
             }
             .onChange(of: workAuthorKeywords) {extractChanged=true}
          Text("Abstract:")
          TextEditor(text: $workAbstract)
             .padding(2)
             .border(Color.cyan, width: 2)
             .dropDestination(for: String.self) { strings, dest in
                return storeWork(strings, target: &workAbstract)
             }
             .onChange(of: workAbstract) {extractChanged=true}
       }.onAppear(perform: {getExtracted() } )
        .onDisappear(perform: {updateExtracted() } )
    }
   //Helpers
   func storeWork(_ strings: [String], target: inout String) -> Bool {
      let temp = joinStrings(strings)
      guard temp != "" else {return false}
      let curr : String = target
      target = curr + temp
      return true
   }
   func getExtracted() {
      workTitle = doc.docTitle
      workAuthors = doc.docAuthors
      workAuthorKeywords = doc.docAuthorKeywords
      workAbstract = doc.docAbstract
      extractChanged = false
   }
   func updateExtracted() -> Void {
      if workTitle != "" && workTitle != doc.docTitle {
         doc.docTitle = workTitle
      }
      if workAuthors != "" && workAuthors != doc.docAuthors {
         doc.docAuthors = workAuthors
      }
      if workAuthorKeywords != "" && workAuthorKeywords != doc.docAuthorKeywords {
         doc.docAuthorKeywords = workAuthorKeywords
      }
      if workAbstract != "" && workAbstract != doc.docAbstract {
         doc.docAbstract = workAbstract
      }
      extractChanged = false
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

#Preview {
   let url = Bundle.main.url(forResource: "DATAK_2005",
                             withExtension: "pdf")
   let urls = [url!]
   let workList = getDocuments(urlList: urls, prevCount: 0)
   var workDoc = workList.docs.isEmpty ? MyDocument() : workList.docs[0]
   var workSel: String = ""
   let boundSel = Binding<String>(get: {return workSel},
                                  set: {s in workSel = s})
   let boundDoc = Binding<MyDocument>(get: {return workDoc},
                                      set: {d in workDoc = d})
   return PDFExtractFields(doc: boundDoc, extracted: boundSel
   )
}
