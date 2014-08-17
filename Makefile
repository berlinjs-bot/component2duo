BIN = ./node_modules/.bin/
NODE ?= node

build: build/index.js build-generator/index.js

build/index.js: lib/index.coffee
	$(BIN)coffee --compile --output build lib/index.coffee

build-generator/index.js: build/index.js
	$(BIN)regenerator --include-runtime $< > $@

clean: 
	rm -rf build build-generator
	mkdir build build-generator

test: 
	npm test

.PHONY: test clean
