

module.exports = function(grunt) {
    "use strict";

    grunt.initConfig({
        pkg: grunt.file.readJSON("package.json"),

        browserify: {
            dist: {
                files: {
                    'build/main.js': ['*.coffee']
                },
                options: {
                    transform: ['coffeeify'],
                    browserifyOptions: {
                        debug: true
                    }
                }
            }
        },

        /*
         * Watches for changes in files and executes the tasks
         */
        watch: {
            browserify: {
                files: [
                    "/**/*.coffee"
                ],
                tasks: ["browserify"]
            }
        }
    });

    grunt.loadNpmTasks("grunt-browserify");

    // Used during development
    grunt.registerTask("default", function(){
        grunt.log.writeln("Let's make some fresh coffee.");
        grunt.task.run(["browserify"]);
    });

    grunt.event.on("watch", function(action, filepath) {
        grunt.log.writeln(filepath + " has " + action);
    });
};
