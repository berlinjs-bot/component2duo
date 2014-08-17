module.exports = require('generator-supported')
  ? require('./build')
  : require('./build-generator');