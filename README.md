## Changelog Parser

### Description

A macOS command line app (in Swift) to parse Changelogs. It will take the top entry off a CHANGELOG and create build notes from it in Markdown format. 


#### Why?

I created this to use it in our CI Environment. It's output can be used with [JiraTools](https://github.com/lottadot/JiraTools) or to create build documentation before you upload a binary to [Hockey](https://rink.hockeyapp.net) or [TestFlight](https://developer.apple.com/testflight/).

##### How To use this?

```
 changelogparser help
Available commands:

   help      Display general or command-specific help
   parse     Parse a changelog and create a markdown representation of it's latest entry
   version   Display the current version of JiraUpdater
```

ex I want to process a changelog:

```
$ changelogparser help parse
Parse a Changelog

[--file (string)]
	the absolute path of the CHANGELOG file parse

[--outfile (string)]
	the out release notes file to build
	
--withIssues]
	show IssueIds in STDOUT
```

So here we go:

```
$ cat CHANGELOG
1.0 #2 2016-01-02
=================
 - Comment4 This is a comment4
 - Comment3 This is a comment3
 * IssueId4 This is a Ticket Issue4
 * IssueId3 This is a Ticket Issue3

1.0 #1 2016-01-01
=================
 - Comment2 This is a comment2
 - Comment1 This is a comment2
 * IssueId2 This is a Ticket Issue2
 * IssueId1 This is a Ticket Issue1

$ changelogparser parse

$ cat CHANGELOG-RELEASENOTES.md 
1.0 #2
* Comment3 This is a comment3
* Comment4 This is a comment4
* IssueId3 This is a Ticket Issue3
* IssueId4 This is a Ticket Issue4

```

or to capture the IssueId's used in this build:

```
$ changelogparser parse --withIssues
$ cat CHANGELOG-ISSUES.TXT
```

To use this in combination with JiraUpdater:

```
$ changelogparser parse --withIssues
$ jiraUpdater update  --issueids "$(< CHANGELOG-ISSUES.TXT)"
// ()COMING SOON as of 2016-08-21)
$ jiraUpdater comment --issueids --message "$(< CHANGELOG-VERSION.TXT)"
```

#### Get started

##### From Source
```
git clone https://github.com/lottadot/changelogparser.git
cd changelogparser
make install
```

##### Homebrew Tap (coming soon as of 2016-08-18)

```
brew tap lottadot/homebrew-formulae
brew install changelogparser
```

### Resources

This uses [https://github.com/lottadot/Changelogkit](ChangelogKit).

### License

Changelog Parser is released under the MIT License.

### Copyright

(c) 2016 Lottadot LLC. All Rights Reserved.
