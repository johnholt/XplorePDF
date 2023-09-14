Learning to extract information from PDF files.
---
# Overview
This project uses SwiftUI to demonstrate how to extract information
from PDF files.  The generated application runs on MacOS and iOS platforms.

The user selects files or drops files to be processed.  
The application automatically extracts the metadata and provides a UI 
for the user to identify the title, authors, author supplied keywords, 
and abstract.

The application maintains a copy of the extracted information for each
documents.  The captured information is not persisted, though it would be
a minor enhancement to extend this application into a document centered
application where the extracted information is persisted or a Core Data
application where the extraction is persisted.

# Metadata display
The application extracts and displays the file metadata and the PDF 
metadata on separate panels.  

# PDF display and user directed extract
The application shows the PDF contents in the `PDFView` view 
using either AppKit or UIKit.  The four (4) extract targets are
shown.

## Current functionality
The user may manually select from the PDF and copy text to the clipboard. 
The user then manually pastes the information into the appropriate 
extraction target.

## Future functionality
The user will be able to manually select the text, and then drag the text to
the appropriate target.

The user will be able to manually select the text, and then use a button to
assign the selection to the appropriate target.

Each completed extraction will be reflected in the PDF document and an 
annotated selection in the PDF document.

# PDF text processing
The application will use the Natural Language framework to process the 
text of the PDF document and with the assistance of the user will mark
the lexical tokens as target content.

## Current functionality
The text on the first page is shown with the resulting tokens in a 
side-by-side manner.  The user can select the token unit (word, sentence,
paragraph) and the scheme.

## Future functionality
The user will be able to assign the tokens to the appropriate extraction
target and perform the extraction.

# Automated extraction identification (future)
The application will use the Natural Language framework along with user 
adjustable heuristic parameters to programatically select and annotate 
text content for extractiopn.

