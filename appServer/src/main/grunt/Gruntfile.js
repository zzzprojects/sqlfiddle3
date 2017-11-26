module.exports = function(grunt) {

    var srcFolder = '../src/main/webroot/',
        targetFolder = 'docker/webroot/';

    grunt.initConfig({
        copy: {
            swagger: {
                files: [{
                    cwd     : targetFolder + 'node_modules/swagger-ui-dist/',
                    src     : [ '**/*', '*', '!index.html' ],
                    dest    : targetFolder + 'api/',
                    flatten : false,
                    expand  : true
                }]
            }
        },
        sync: {
            webroot: {
                files: [{
                    cwd     : srcFolder,
                    src     : ['**/*', '*'],
                    dest    : targetFolder,
                    flatten : false,
                    expand  : true
                }]
            },
            verticles: {
                files: [{
                    cwd     : "../src/main/verticles",
                    src     : ['**/*'],
                    dest    : "docker",
                    flatten : false,
                    expand  : true
                }]
            }
        },
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
                    baseUrl: targetFolder + "javascript",
                    mainConfigFile: targetFolder + "javascript/main.js",
                    include: [
                        "../node_modules/almond/almond",
                        "main"
                    ],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: targetFolder + "javascript/main_min.js"
                }
            },
/*            minifyOAuthJS: {
                options: {
                    baseUrl: targetFolder + "javascript",
                    mainConfigFile: targetFolder + "javascript/oauth.js",
                    include: [
                        "../node_modules/almond/almond",
                        "oauth"
                    ],
                    optimize: "uglify2",
                    generateSourceMaps: true,
                    preserveLicenseComments: false,
                    out: targetFolder + "javascript/oauth_min.js"
                }
            },
*/
            minifyMainCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: targetFolder + 'css/styles.css',
                    out: targetFolder + 'css/styles_min.css'
                }
            },
            minifyPrintCSS: {
                options: {
                    optimizeCss: 'standard',
                    cssIn: targetFolder + 'css/print.css',
                    out: targetFolder + 'css/print_min.css'
                }
            }
        },
        watch: {
            copyUIJS: {
                files: [srcFolder + 'javascript/**/*', "!" + srcFolder + 'javascript/*_min.js*'],
                tasks: ['sync:webroot', 'requirejs:minifyMainJS', 'requirejs:minifyOAuthJS' ]
            },
            copyLESS: {
                files: [srcFolder + 'css/*.less', srcFolder + 'css/*.css', "!" + srcFolder + 'css/*_min.css',],
                tasks: ['sync:webroot', 'less', 'requirejs:minifyMainCSS', 'requirejs:minifyPrintCSS' ]
            },
            copyStatic: {
                files: [srcFolder + '*.html', srcFolder + 'images/**', srcFolder + 'img/*', srcFolder + 'api/*'],
                tasks: ['sync:webroot']
            },
            copyVerticles: {
                files: ["../src/main/verticles/**"],
                tasks: ['sync:verticles']
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-sync');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-copy');

    grunt.registerTask('build', ['sync:verticles', 'less', 'requirejs', 'copy:swagger']);
    grunt.registerTask('default', ['build', 'watch']);

};
