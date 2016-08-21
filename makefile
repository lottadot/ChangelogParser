TEMPORARY_FOLDER?=/tmp/ChangelogParser.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-workspace 'ChangelogTools.xcworkspace' -scheme 'changelogparser' DSTROOT=$(TEMPORARY_FOLDER) 
#CONFIGURATION_BUILD_DIR=$(TEMPORARY_FOLDER) CONFIGURATION_TEMP_DIR=$(TEMPORARY_FOLDER)


BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/changelogparser.app
FRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks
EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/changelogparser

FRAMEWORKS_FOLDER=/Library
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=changelogparser.pkg

VERSION_STRING=$(shell cd changelogparser && agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=changelogparser/changelogparser/Components.plist

.PHONY: all bootstrap clean build install package test uninstall carthage

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build| egrep '^(/.+:[0-9+:[0-9]+:.(error|warning):|fatal|===)' -

carthage:
	carthage update

bootstrap:
	carthage bootstrap --platform mac --no-use-binaries

# xcodebuild -workspace ChangelogParser.xcworkspace -scheme changelogparser CONFIGURATION_BUILD_DIR='build'
build:
	$(BUILD_TOOL) $(XCODEFLAGS) build

buildVerbose:
	$(BUILD_TOOL) $(XCODEFLAGS) build -verbose

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) clean

install: package
	sudo installer -pkg changelogparser.pkg -target /

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	mv -f "$(FRAMEWORK_BUNDLE)/" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)"
	mv -fv "$(EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/changelogparser"
	rm -rf "$(BUILT_BUNDLE)"

prefix_install: installables
	mkdir -p "$(PREFIX)/Frameworks" "$(PREFIX)/bin"
	cp -rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(PREFIX)/Frameworks/"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/changelogparser" "$(PREFIX)/bin/"
	install_name_tool -add_rpath "@executable_path/../Frameworks/ChangelogParserKit.framework/Versions/Current/Frameworks/" "$(PREFIX)/bin/changelogparser"

package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "com.lottadot.changelogtools.changelogparser" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"
