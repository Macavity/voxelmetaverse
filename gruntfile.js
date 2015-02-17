

module.exports = function(grunt) {
    "use strict";

    grunt.initConfig({
        pkg: grunt.file.readJSON("package.json"),

        browserify: {
            dist: {
                files: {
                    'build/main.js': ['js/main.js']
                },
                options: {
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
                    "/js/**/*.js"
                ],
                tasks: ["browserify"]
            }
        }
    });

    grunt.loadNpmTasks("grunt-browserify");
    grunt.loadNpmTasks("grunt-contrib-watch");

    // Used during development
    grunt.registerTask("default", function(){
        grunt.log.writeln("Let's make some fresh coffee.");
        grunt.task.run(["browserify"]);
    });

    grunt.event.on("watch", function(action, filepath) {
        grunt.log.writeln(filepath + " has " + action);
    });
};
