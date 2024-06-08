const path = require('path');

module.exports = {
  entry: './ts/index.ts',
  output: {
    library: 'Audio',
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: /node_modules/,
        use: 'ts-loader'
      },
    ],
  },
};