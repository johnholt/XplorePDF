Learning to extract information from PDF files.
---
# Overview
This project uses SwiftUI to demonstrate how to extract information
from PDF files.  The application runs on MacOS and iOS platforms.

The user selects files to be processed.  
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

The user selects a file or files from the standard file selection sheet. This
can be done one or more times.  The user may clear the list of files.

The user may manually select from the PDF and copy text to the clipboard.
 
The user then manually pastes the information into the appropriate 
extraction target.

The user may manually select the text, and then drag the text to
the appropriate target.  A preview is shown during drag.


# PDF text processing
The application uses the Natural Language framework to process the 
text of the PDF document and with the assistance of the user will mark
the lexical tokens as target content.

The text on the displayed page is shown with the resulting tokens in a 
side-by-side manner.  The user can select the token unit (word, sentence,
paragraph) and the scheme.

The user can use a button to page forward and backward through the document.

# Other
The entitlement settings enable MacOS Sandbox.  You will need to disable
this setting to enable the XCode preview feature for a MacOS build.  There are
two PDF documents in the Preview Resources folder which cannot be read when
sandboxing is enabled.
