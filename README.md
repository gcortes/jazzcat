# Jazz Cat
This is an Mac OS application for maintaining and listening to jazz music residing in iTunes. It maintain a separate database thas is a 
super set of the data stored in iTunes. It also replicates iTunes play and queue function so that is can be used in place of iTunes.

At this point, it's just a single developer's personal project.

## Synopsis

This application has two major dependencies: Swift Automation and Cat Box.

Swift Automation is an Apple Event Bridge. It allows you to control scriptable macOS applications. It is used as the interface to iTunes.
 The application can be found [here](https://bitbucket.org/hhas/swiftae).

Cat Box is the Rails API server that serves the music data. The music itself still resides in iTunes as well as the album art. The code 
for this application with be added to this repository shortly.

## Motivation

My initial motivation for writing the application is to learn a new programming language or platfrom. It was first created using 
Microsoft Access in the 1990's. The database was ported ot MySQL and the code was PHP and the symfony frame. That was followed by a 
complete rewrite into ruby with the Rails framework. Next came a dart front end to a Rails APi. When that proved to be too slow, I 
created a Mac OS client written in Swift.

## Installation

No instructions at this point

## Tests

Sadly, there are no automated tests.

## Contributors

Only the repository's owner at this point.

## License

Apache license 2.0