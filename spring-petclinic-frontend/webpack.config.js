const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    entry: {
        index: './src/index.js',
    },
    module: {
        rules: [
            {
                test: /\.less$/i,
                use: [
                    'style-loader',
                    'css-loader',
                    'less-loader',
                ],
            },
            {
                test: /\.css$/i,
                use: [
                    'css-loader',
                ],
            },
            {
                test: /.html$/,
                exclude: /index.html$/,
                use: 'html-loader'
            },
        ],
    },
    plugins: [
        new webpack.ProgressPlugin(),
        new webpack.ProvidePlugin({
            $: "jquery",
            jQuery: "jquery"
        }),
        new HtmlWebpackPlugin({
            filename: 'index.html',
            template: path.resolve(__dirname, `src/index.html`),
            cache: false,
        }),
    ],
};
