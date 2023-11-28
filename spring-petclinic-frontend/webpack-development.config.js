const commonConfig = require('./webpack.config.js');
const { merge} = require('webpack-merge');
const CopyPlugin = require("copy-webpack-plugin");
const WebpackShellPluginNext = require("webpack-shell-plugin-next");
const path = require("path");

module.exports = merge(commonConfig,
    {
        devtool: 'inline-source-map',
        mode: 'development',
        devServer: {
            static: false,
            port: 3000,
            https: false,
        },
        output: {
            filename: '[name].[contenthash].js',
            path: path.resolve(__dirname, 'public'),
            clean: true,
        },
        plugins: [
            new WebpackShellPluginNext({
                onBuildStart:{
                    scripts: ['shx rm -rf "public/index.html"'],
                    blocking: true,
                    parallel: false
                },
            }),
            new CopyPlugin({
                patterns: [
                    {
                        from: 'src/scripts/fragments/footer.html',
                        to: 'scripts/fragments/footer.html',
                    },
                    {
                        from: 'src/scripts/fragments/nav.html',
                        to: 'scripts/fragments/nav.html',
                    },
                    {
                        from: 'src/scripts/fragments/welcome.html',
                        to: 'scripts/fragments/welcome.html',
                    },
                    {
                        from: 'src/scripts/owner-details/owner-details.template.html',
                        to: 'scripts/owner-details/owner-details.template.html',
                    },
                    {
                        from: 'src/scripts/owner-form/owner-form.template.html',
                        to: 'scripts/owner-form/owner-form.template.html',
                    },
                    {
                        from: 'src/scripts/owner-list/owner-list.template.html',
                        to: 'scripts/owner-list/owner-list.template.html',
                    },
                    {
                        from: 'src/scripts/pet-form/pet-form.template.html',
                        to: 'scripts/pet-form/pet-form.template.html',
                    },
                    {
                        from: 'src/scripts/vet-list/vet-list.template.html',
                        to: 'scripts/vet-list/vet-list.template.html',
                    },
                    {
                        from: 'src/scripts/visits/visits.template.html',
                        to: 'scripts/visits/visits.template.html',
                    },
                    {
                        from: 'src/images/',
                        to: 'images/',
                    },
                    {
                        from: 'src/fonts/',
                        to: 'fonts/',
                    },
                    "public",
                ],
            }),
        ],
    });
