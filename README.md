compoonent2duo
==============

convert your component app into duo app

Duo doesn't have any concept of __local components__.
This tool rewrites your require paths for local components by
analyzing your root component and all your locals and scripts which are listed in your `component.json` files.


## Limitation / not implemented yet
- root component should have only __one__ element in the `paths` array
- local components cannot have any lookup path like the root component


## install

    npm install component2duo

## usage

```js
var Converter = require('component2duo');
var c = new Converter('rootComponentPath', Converter.ABSOLUTE, {simulate:true});
var result = c.start();
console.log(result);
```

## API

### Converter(path, mode, opt)

- __path__ to the root component.json
- __mode__ Converter.ABSOLUTE or Converter.RELATIVE
- __opt__ options object
    - __simulate__ - boolean, if true: don't rewrite changes to filesystem, return the changes as result of `start()`, default false
    - __debug__ - boolean, if true: print each require path transformation to stdout
    - __localManifest__ filename of the local components manifest, default `component.json`

### Mode
__Converter.ABSOLUTE__ will rewrite require paths relative to the root component with a leading slash, for instance: `/lib/local`.

__Converter.RELATIVE__ will rewrite require paths relative to each local component, for instance: `../local`.

### CLI

    node_modules/.bin/component2duo ~/myApp 0 true

- first argument: path to root component
- second argument: mode; 0 = ABSOLUTE, 1 = RELATIVE
- third argument (optional): simulate and print require transformation to stdout


## example

Assume you have this directory structure

    myApp
    ├── component.json
    └── lib
        ├── bar
        │   ├── component.json
        │   ├── index.js
        │   └── qux.js
        └── foo
            ├── component.json
            ├── index.js
            ├── script.js
            └── sub
                └── baz.js

Your root component is located at `myApp/component.json` with this content: 

    {
        "name": "myApp",
        "paths": ["lib"],
        "locals": ["foo"]
    }

`myApp/foo/component.json`:

    {
        "locals": ["bar"],
        "scripts": [
            "index.js",
            "script.js",
            "sub/baz.js"
        ],
        "main": "index.js"
    }

With component you can write `require('bar')` in the scripts of __foo__.
With this tool you can choose if you want to rewrite it into an absolute `require('/lib/bar')` or relative `require('../bar')` path.

### example CLI output

If you checkout this project (and make a `npm install`) you can run:

`$ ./bin/cli test/fixtures/simple/component.json 0 true`

then you get this result:

    lib/foo/script.js: 'bar' -> '/lib/bar'
    lib/foo/script.js: 'bar/qux' -> '/lib/bar/qux'