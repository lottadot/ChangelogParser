## Changelog Parser

### Description

A macOS command line app (in Swift) to parse Changelog's. Uses [https://github.com/lottadot/Changelogkit](ChangelogKit).


#### Why?

I created this to use it in our CI Environment. It's output can be used with [JiraTools](https://github.com/lottadot/JiraTools) or to create build documentation before you upload a binary to [Hockey](https://rink.hockeyapp.net) or [TestFlight](https://developer.apple.com/testflight/).

##### How To use this?

```
 changelogparser help
Available commands:

   help      Display general or command-specific help
   version   Display the current version of JiraUpdater
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

### License

Changelog Parser is released under the MIT License.

### Copyright

(c) 2016 Lottadot LLC. All Rights Reserved.
