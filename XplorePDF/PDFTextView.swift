//
//  PDFTextView.swift
//  XplorePDF
//
//  Created by John Holt on 9/23/23.
//

import SwiftUI
import NaturalLanguage



struct PDFTextView: View {
   @Binding var doc: MyDocument
   @State private var pageCount = 0
   @State private var pageNum = 1
   @State private var tokenUnit : NLTokenUnit = .word
   @State private var language = NLLanguage.english
   @State private var pageText = ""
   @State private var tagScheme = NLTagScheme.tokenType
   @State private var schemes : Array<NLTagScheme> = []
   @State private var tokens : [MyToken] = []
   @State private var selToks = Set<UInt32>()
   @State private var tokText : String = ""

   var body: some View {
      NavigationStack {
         VStack {
            PDFExtractFields(doc: $doc, extracted: $tokText)
            HStack {
               Text("Extracted string:")
               Button("Get Selected", action: {tokText = makeString()})
            }
            TextEditor(text: $tokText)
            HStack {
               Text("There are \(pageCount) pages,")
               Text("and the current page is \(pageNum)")
               Spacer()
               Button("Previous Page", systemImage: "arrow.left"){
                  if pageNum > 1 {
                     pageNum -= 1
                     getPageText()
                     tokenize()
                  }
               }
               .labelStyle(.iconOnly)
               .disabled(pageNum < 2)
               Button("Next Page", systemImage: "arrow.right") {
                  if pageNum < pageCount-1 {
                     pageNum += 1
                     getPageText()
                     tokenize()
                  }
               }
               .labelStyle(.iconOnly)
               .disabled(pageNum >= pageCount - 1)
               Spacer()
               Text("Primary language is: \(language.rawValue)")
               Spacer()
               Text("Selected: \(selToks.count)")
            }
            HStack {
               Picker("Token Unit", selection: $tokenUnit) {
                  Text("Word").tag(NLTokenUnit.word)
                  Text("Sentence").tag(NLTokenUnit.sentence)
                  Text("Paragraph").tag(NLTokenUnit.paragraph)
               }
               .onChange(of: tokenUnit, {tokenize()})
               Spacer()
               Picker("Scheme", selection: $tagScheme) {
                  ForEach(schemes, id: \.rawValue) { scheme in
                     Text(scheme.rawValue).tag(scheme)
                  }
               }
               .onChange(of:tagScheme, {tokenize()} )
            }
            HStack {
               ScrollView {
                  Text(pageText)
               }
               Spacer()
               Table(tokens, selection: $selToks) {
                  TableColumn("Text", value: \.text)
                  TableColumn("Type", value: \.type)
               }
//               ScrollView {
//                  VStack {
//                     ForEach(tokens) { token in
//                        HStack {
//                           Text(token.text)
//                           Spacer()
//                           Text(token.type)
//                        }
//                     }
//                  }
//               }
            }
         }
      }
      .onAppear(perform: {viewInit()})
   }
   
   func viewInit() {
      pageCount = doc.doc.pageCount
      getPageText()
      getSchemes()
      tokenize()
   }
   
   func getPageText() {
      let pageNdx = pageNum - 1
      if let page = doc.doc.page(at: pageNdx) {
         pageText = page.string ?? ""
      } else {
         pageText = ""
      }
      language = NLLanguageRecognizer.dominantLanguage(for: pageText)
                        ?? NLLanguage.english
      getSchemes()
   }
   
   func getSchemes() {
      let availSchemes = Set(NLTagger.availableTagSchemes(for: tokenUnit,
                                                          language: language))
      let interestingSchemes : Set<NLTagScheme> = [NLTagScheme.tokenType,
                                                   NLTagScheme.lexicalClass,
                                                   NLTagScheme.nameType,
                                                   NLTagScheme.nameTypeOrLexicalClass]
      let schemeSet = availSchemes.intersection(interestingSchemes)
      schemes = Array<NLTagScheme>(schemeSet)
   }
   
   func tokenize() {
      tokens.removeAll()
      var ndx : UInt32 = 0
      let tagger = NLTagger(tagSchemes: schemes)
      tagger.string = pageText
      tagger.enumerateTags(in: pageText.startIndex..<pageText.endIndex,
                           unit: tokenUnit, scheme: tagScheme,
                           options: [NLTagger.Options.omitWhitespace],
                           using: {tag, textRange in
         let theText = String(tagger.string![textRange])
         let theTag = tag?.rawValue  ?? "no type"
         let tok = MyToken(id: ndx, text: theText, type: theTag)
         tokens.append(tok)
         ndx += 1
         return true})
   }
   
   func makeString() -> String {
      var rslt : String = ""
      for ndx in selToks.sorted() {
         rslt.append(tokens[Int(ndx)].text)
         rslt.append(" ")
      }
      rslt.removeLast()
      selToks.removeAll()
      return rslt
   }
}

struct MyToken : Identifiable {
   var id : UInt32
   var text : String
   var type : String
}

#Preview {
   let url = Bundle.main.url(forResource: "DATAK_2005",
                             withExtension: "pdf")
   let urls = [url!]
   let workList = getDocuments(urlList: urls, prevCount: 0)
   var workDoc = workList.docs.isEmpty ? MyDocument() : workList.docs[0]
   let boundDoc = Binding<MyDocument>(get: {return workDoc},
                                      set: {d in workDoc = d})
   return PDFTextView(doc: boundDoc)
}

