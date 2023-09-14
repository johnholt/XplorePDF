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
   @State var pageCount = 0
   @State var pageNum = 0
   @State var tokenUnit : NLTokenUnit = .word
   @State var language = NLLanguage.english
   @State var pageText = ""
   @State var tagScheme = NLTagScheme.tokenType
   @State var schemes : Array<NLTagScheme> = []
   @State var tokens : [MyToken] = []

   var body: some View {
      NavigationStack {
         VStack {
            HStack {
               Text("There are \(pageCount) pages,")
               Text("and the current page is \(pageNum)")
               Spacer()
               Text("Primary language is: \(language.rawValue)")
               Spacer()
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
               Text(pageText)
               Spacer()
               ScrollView {
                  VStack {
                     ForEach(tokens) { token in
                        HStack {
                           Text(token.text)
                           Spacer()
                           Text(token.type)
                        }
                     }
                  }
               }
            }
         }
      }
      .onAppear(perform: {viewInit()})
   }
   
   func viewInit() {
      pageCount = doc.doc.pageCount
      if let page = doc.doc.page(at: 0) {
         pageNum = 1
         pageText = page.string ?? ""
      }
      language = NLLanguageRecognizer.dominantLanguage(for: pageText)
                  ?? NLLanguage.english
      let availSchemes = Set(NLTagger.availableTagSchemes(for: tokenUnit,
                                                 language: language))
      let interestingSchemes : Set<NLTagScheme> = [NLTagScheme.tokenType,
                                                   NLTagScheme.lexicalClass,
                                                   NLTagScheme.nameType,
                                                   NLTagScheme.nameTypeOrLexicalClass]
      let schemeSet = availSchemes.intersection(interestingSchemes)
      schemes = Array<NLTagScheme>(schemeSet)
      tokenize()
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
         let tok = MyToken(id: ndx, text: theText,
                           type: theTag)
         tokens.append(tok)
         ndx += 1
         return true})
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

