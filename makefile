TEMPORARY_FOLDER?=/tmp/ChangelogParser.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-workspace 'ChangelogTools.xcworkspace' -scheme 'changelogparser' DSTROOT=$(TEMPORARY_FOLDER) 
BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/changelogparser.app
FRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks
EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/changelogparser
FRAMEWORKS_FOLDER=/Library
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=changelogparser.pkg
OUTPUT_FRAMEWORK=ChangelogKit.framework

VERSION_STRING=$(shell cd changelogparser && agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=changelogparser/changelogparser/Components.plist

.PHONY: all bootstrap clean build install package test uninstall carthage

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build| egrep '^(/.+:[0-9+:[0-9]+:.(error|warning):|fatal|===)' -

carthage:
	carthage update

bootstrap:
	carthage bootstrap --platform macOS --no-use-binaries

# xcodebuild -workspace ChangelogParser.xcworkspace -scheme changelogparser CONFIGURATION_BUILD_DIR='build'
build:
	$(BUILD_TOOL) $(XCODEFLAGS) build

buildVerbose:
	$(BUILD_TOOL) $(XCODEFLAGS) build -verbose

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -f "$(OUTPUT_FRAMEWORK_ZIP)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) clean

install: package
	sudo installer -pkg changelogparser.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/$(OUTPUT_FRAMEWORK)"
	rm -rf "$(PREFIX)/Frameworks/$(OUTPUT_FRAMEWORK)"
	rm -f "$(BINARIES_FOLDER)/changelogparser"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	
	# copy our Kit Framework into the destination Frameworks directory.
	rsync -a --prune-empty-dirs --include '*/'  --exclude '/libswift*.dylib' "$(FRAMEWORK_BUNDLE)/ChangelogKit.framework" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/Frameworks"

	# copy the app's frameworks into the "ChangelogKit Framework" *Frameworks directory* that we put into the destination Frameworks directory.
	rsync -a --prune-empty-dirs --include '*/'  --exclude '/libswift*.dylib /ChangelogKit.framework' "$(FRAMEWORK_BUNDLE)/" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/Frameworks/$(OUTPUT_FRAMEWORK)/Versions/Current/Frameworks"

	mv -fv "$(EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/changelogparser"
	rm -rf "$(BUILT_BUNDLE)"

prefix_install: installables
	mkdir -p "$(PREFIX)/Frameworks" "$(PREFIX)/bin"
	cp -Rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/Frameworks/$(OUTPUT_FRAMEWORK)" "$(PREFIX)/Frameworks/"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/changelogparser" "$(PREFIX)/bin/"
	install_name_tool -add_rpath "@executable_path/../Frameworks/$(OUTPUT_FRAMEWORK)/Versions/Current/Frameworks/" "$(PREFIX)/bin/changelogparser"

package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "com.lottadot.changelogtools.changelogparser" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"
