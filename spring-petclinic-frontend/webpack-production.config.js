const commonConfig = require('./webpack.config.js');
const { merge} = require('webpack-merge');
const fs = require('fs-extra');
const path = require("path");
const WebpackShellPluginNext = require("webpack-shell-plugin-next");

module.exports = merge(commonConfig,
    {
        mode: 'production',
        cache: false,
        output: {
            filename: '[name].[contenthash].js',
            path: path.resolve(__dirname, 'public'),
            publicPath: '/',
        },
        plugins: [
            new WebpackShellPluginNext({
                onBeforeBuild: () => {
                    if (fs.exists(path.resolve(__dirname, 'public'))) {
                        fs.emptyDirSync(path.resolve(__dirname, 'public'));
                    } else {
                        fs.mkdirpSync(path.resolve(__dirname, 'public'), 0o777);
                    }
                    fs.copy('src/scripts/fragments/', 'public/scripts/fragments/');
                    fs.copy('src/scripts/owner-details/owner-details.template.html', 'public/scripts/owner-details/owner-details.template.html');
                    fs.copy('src/scripts/owner-form/owner-form.template.html', 'public/scripts/owner-form/owner-form.template.html');
                    fs.copy('src/scripts/owner-list/owner-list.template.html', 'public/scripts/owner-list/owner-list.template.html');
                    fs.copy('src/scripts/pet-form/pet-form.template.html', 'public/scripts/pet-form/pet-form.template.html');
                    fs.copy('src/scripts/vet-list/vet-list.template.html', 'public/scripts/vet-list/vet-list.template.html');
                    fs.copy('src/scripts/visits/visits.template.html', 'public/scripts/visits/visits.template.html');
                    fs.copy('src/images/', 'public/images/');
                    fs.copy('src/fonts/', 'public/fonts/');
                },
            }),
        ],
        performance: {
            hints: false,
        },
    });
