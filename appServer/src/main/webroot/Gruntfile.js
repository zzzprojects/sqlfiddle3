module.exports = function(grunt) {

    var srcFolder = './',
        targetFolder = './';

    grunt.initConfig({
        less: {
            production: {
                files: [{
                    src: srcFolder + "css/fiddle.less",
                    dest: targetFolder + "css/fiddle.css"
                }, {
                    src: srcFolder + "css/fiddle_responsive.less",
                    dest: targetFolder + "css/fiddle_responsive.css"
                }, {
                    src: srcFolder + "css/fiddle_bootstrap_overrides.less",
                    dest: targetFolder + "css/fiddle_bootstrap_overrides.css"
                }]
            }
        },
        requirejs: {
            minifyMainJS: {
                options: {
                    baseUrl: srcFolder + "javascript",
                    mainConfigFile: srcFolder + "javascript/main.js",
                    include: [
                        targetFolder + "../node_modules/almond/almond",
                        targetFolder + "main"
                    ],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: targetFolder + "javascript/main_min.js"
                }
            },
            minifyOAuthJS: {
                options: {
                    baseUrl: srcFolder + "javascript",
                    mainConfigFile: srcFolder + "javascript/oauth.js",
                    include: [
                        targetFolder + "../node_modules/almond/almond",
                        targetFolder + "oauth"
                    ],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: targetFolder + "javascript/oauth_min.js"
                }
            },
            minifyMainCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: srcFolder + 'css/styles.css',
                    out: targetFolder + 'css/styles_min.css'
                }
            },
            minifyPrintCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: srcFolder + 'css/print.css',
                    out: targetFolder + 'css/print_min.css'
                }
            }
        },
        watch: {
            copyUIJS: {
                files: [srcFolder + 'javascript/**/*', "!" + srcFolder + 'javascript/*_min.js*'],
                tasks: ['requirejs:minifyMainJS', 'requirejs:minifyOAuthJS' ]
            },
            copyLESS: {
                files: [srcFolder + 'css/*.less', srcFolder + 'css/*.css', "!" + srcFolder + 'css/*_min.css',],
                tasks: [ 'less', 'requirejs:minifyMainCSS', 'requirejs:minifyPrintCSS' ]
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-contrib-less');

    grunt.registerTask('build', ['less', 'requirejs']);
    grunt.registerTask('default', ['build', 'watch']);

};
