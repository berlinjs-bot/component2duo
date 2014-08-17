BIN = ./node_modules/.bin/
NODE ?= node

build: build/index.js

build/index.js: lib/index.coffee
	$(BIN)coffee --compile --output build lib/index.coffee

clean: 
	rm -rf build
	mkdir build

test: 
	npm test

.PHONY: test clean
