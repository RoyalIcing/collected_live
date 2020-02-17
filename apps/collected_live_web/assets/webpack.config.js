const Path = require("path");
const glob = require("glob");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const VueLoaderPlugin = require("vue-loader/lib/plugin");

module.exports = (env, options) => ({
  optimization: {
    minimizer: [new TerserPlugin(), new OptimizeCSSAssetsPlugin({})]
  },
  entry: {
    "./js/app.js": ["./js/app.js"].concat(glob.sync("./vendor/**/*.js"))
  },
  output: {
    filename: "app.js",
    path: Path.resolve(__dirname, "../priv/static/js")
  },
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: "vue-loader"
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader"
        }
      },
      {
        test: /\.css$/,
        use: [
          MiniCssExtractPlugin.loader,
          // 'vue-style-loader',
          "css-loader",
          {
            loader: "postcss-loader",
            options: {
              ident: "postcss",
              plugins: [
                require("postcss-import")({
                  // root: Path.resolve(__dirname, "css")
                  path: [Path.resolve(__dirname, "css")]
                  //
                }),
                require("tailwindcss"),
                require("autoprefixer")
              ]
            }
          }
        ]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: "../css/app.css" }),
    new CopyWebpackPlugin([{ from: "static/", to: "../" }]),
    new VueLoaderPlugin()
  ]
});
