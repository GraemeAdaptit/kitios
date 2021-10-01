# README #

### What is this repository for? ###

* Development of Key It as an iPhone app

### How do I get set up? ###

* Get Xcode 12 
* Get the URL for the repository from Graeme Costin
* Use Xcode's Source Control to clone the repo from Github, and open the Xcode project
* The SQLite database that is included in recent Mac OSX systems is used. The Xcode project
  includes settings to use the bridge from Swift to C for source code that calls the C API
  of SQLite.


### Contribution guidelines ###

* All interaction with SQLite is kept inside the file KITDAO.swift - the rest of the code is straight Swift code.

* Comments about the software design are contained in comments in the source code.

* There are two design documents that describe and give some details of the app design:

	KIT Design Document.odt
	
	KIT Design Document Popovers.ods

### Whom do I talk to? ###

* Owner of this Github repo is Graeme Costin - graeme_costin@wycliffe.org.au.

* This app will be released as an open source freeware app provided by Wycliffe Bible Translators.
