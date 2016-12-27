module.exports = function(grunt) {

    grunt.initConfig({
        less: {
            production: {
                files: {
                    "css/fiddle.css": "css/fiddle.less",
                    "css/fiddle_responsive.css": "css/fiddle_responsive.less",
                    "css/fiddle_bootstrap_overrides.css": "css/fiddle_bootstrap_overrides.less"
                }
            }
        },
        requirejs: {
            minifyMainJS: {
                options: {
                    baseUrl: "javascript",
                    mainConfigFile: "javascript/main.js",
                    include: ["../node_modules/almond/almond", "main"],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: "javascript/main_min.js"
                }
            },
            minifyOAuthJS: {
                options: {
                    baseUrl: "javascript",
                    mainConfigFile: "javascript/oauth.js",
                    include: ["../node_modules/almond/almond", "oauth"],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: "javascript/oauth_min.js"
                }
            },
            minifyMainCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: 'css/styles.css',
                    out: 'css/styles_min.css'
                }
            },
            minifyPrintCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: 'css/print.css',
                    out: 'css/print_min.css'
                }
            }
        },
        watch: {
            copyUIJS: {
                files: ['javascript/**/*'],
                tasks: ['requirejs:minifyMainJS', 'requirejs:minifyOAuthJS' ]
            },
            copyLESS: {
                files: ['css/*.less', 'css/*.css'],
                tasks: [ 'less', 'requirejs:minifyMainCSS', 'requirejs:minifyPrintCSS' ]
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-contrib-less');

    grunt.registerTask('default', ['less', 'requirejs', 'watch']);

};
