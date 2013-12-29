module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    browserify:
      build:
        src: ['src/background.coffee']
        dest: 'build/background.js'
        options:
          transform: ['coffeeify', 'node-lessify']
    copy:
      tabs:
        files: [
          src: ['src/tabs/*'], dest: 'build/tabs/', expand: true, flatten: true
        ]
    watch:
      files: ['src/**/*.coffee', 'src/**/*.js', 'src/**/*.less', 'src/**/*.css', 'src/**/*.html']
      tasks: ['build']


  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.registerTask 'build', ['browserify', 'copy']