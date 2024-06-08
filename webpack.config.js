const path = require('path');

module.exports = {
  entry: './ts/index.js',
  output: {
    library: 'Audio',
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
      },
    ],
  },
};