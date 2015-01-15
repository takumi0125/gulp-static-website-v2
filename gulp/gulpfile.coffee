gulp         = require 'gulp'
autoprefixer = require 'gulp-autoprefixer'
changed      = require 'gulp-changed'
clean        = require 'gulp-clean'
coffee       = require 'gulp-coffee'
concat       = require 'gulp-concat'
data         = require 'gulp-data'
filter       = require 'gulp-filter'
notify       = require 'gulp-notify'
jade         = require 'gulp-jade'
jshint       = require 'gulp-jshint'
jsonlint     = require 'gulp-jsonlint'
plumber      = require 'gulp-plumber'
print        = require 'gulp-print'
sass         = require 'gulp-ruby-sass'
sourcemap    = require 'gulp-sourcemaps'
sprite       = require 'gulp.spritesmith'
webserver    = require 'gulp-webserver'

bower        = require 'main-bower-files'
exec         = require('child_process').exec
runSequence  = require 'run-sequence'

SRC_DIR = './src'
PUBLISH_DIR = '../htdocs'
BOWER_COMPONENTS = './bower_components'
DATA_JSON = "#{SRC_DIR}/_data.json"

ASSETS_DIR = '/assets'

paths =
  html  : "#{SRC_DIR}/**/*.html"
  jade  : "#{SRC_DIR}/**/*.jade"
  css   : "#{SRC_DIR}/**/*.css"
  sass  : "#{SRC_DIR}/**/*.{sass,scss}"
  js    : "#{SRC_DIR}/**/*.js"
  json  : "#{SRC_DIR}/**/*.json"
  coffee: "#{SRC_DIR}/**/*.coffee"
  img   : "#{SRC_DIR}/**/img/**"
  others: [
    "#{SRC_DIR}/**"
    "#{SRC_DIR}/**/.htaccess"
    "!#{SRC_DIR}/**/*.{html,jade,css,sass,scss,js,json,coffee,md}"
    "!#{SRC_DIR}/**/img/**"
    "!#{SRC_DIR}/**/_*/**"
    "!#{SRC_DIR}/**/_*/"
    "!#{SRC_DIR}/**/_*"
  ]
  jadeInclude  : "#{SRC_DIR}/**/_*.jade"
  sassInclude  : "#{SRC_DIR}/**/_*.{sass,scss}"
  coffeeInclude: "#{SRC_DIR}/**/_*.{coffee}"


spritesTask = []
watchSpritesTasks = []

errorHandler = (name)-> return notify.onError name + ": <%= error %>"

createSrcArr = (name) -> [].concat paths[name], "!#{SRC_DIR}/_*", "!#{SRC_DIR}/**/_*/", "!#{SRC_DIR}/**/_*/**"

#
# spritesmith のタスクを生成
#
# @param {string} taskName       タスクを識別するための名前 スプライトタスクが複数ある場合はユニークにする
# @param {string} imgDir         画像ディレクトリへのパス
# @param {string} cssDir         CSSディレクトリへのパス
# @param {string} outputImgPath  CSSに記述される画像パス
#
# #{SRC_DIR}#{imgDir}/_#{taskName}/
# 以下にソース画像を格納しておくと
# #{SRC_DIR}#{cssDir}/_#{taskName}.scss と
# #{SRC_DIR}#{imgDir}/#{taskName}.png が生成される
# かつ watch タスクの監視も追加
#
createSpritesTask = (taskName, imgDir, cssDir, outputImgPath = '') ->
  spritesTask.push taskName

  srcImgFiles = "#{SRC_DIR}#{imgDir}/_#{taskName}/*"
  gulp.task taskName, ->
    spriteObj =
      imgName: "#{taskName}.png"
      cssName: "_#{taskName}.scss"
      algorithm: 'binary-tree'
      padding: 2

    if outputImgPath then spriteObj.imgPath = outputImgPath

    spriteData = gulp.src srcImgFiles
    .pipe plumber errorHandler: errorHandler taskName
    .pipe sprite spriteObj

    spriteData.img
    .pipe gulp.dest "#{SRC_DIR}#{imgDir}"
    .pipe gulp.dest "#{PUBLISH_DIR}#{imgDir}"

    spriteData.css.pipe gulp.dest "#{SRC_DIR}#{cssDir}"

  watchSpritesTasks.unshift => gulp.watch srcImgFiles, [ taskName ]



#############
### clean ###
#############

# clean
gulp.task 'clean', ->
  gulp.src PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'clean'
  .pipe clean force: true


##############
### concat ###
##############

# concat
gulp.task 'concat', ->
  gulp.src ['']
  .pipe plumber errorHandler: errorHandler 'concat'
  .pipe concat 'common.js'
  .pipe gulp.dest "#{PUBLISH_DIR}#{ASSETS_DIR}/js/lib"
  .pipe print (path)-> "[concat]: #{path}"


############
### copy ###
############

# copyHtml
gulp.task 'copyHtml', ->
  gulp.src createSrcArr 'html'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'copyHtml'
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[copyHtml]: #{path}"

# copyCss
gulp.task 'copyCss', ->
  gulp.src createSrcArr 'css'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'copyCss'
  .pipe autoprefixer()
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[copyCss]: #{path}"

# copyJs
gulp.task 'copyJs', [ 'jshint' ], ->
  gulp.src createSrcArr 'js'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'copyJs'
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[copyJs]: #{path}"

# copyJson
gulp.task 'copyJson', [ 'jsonlint' ], ->
  gulp.src createSrcArr 'json'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'copyJson'
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[copyJson]: #{path}"

# copyImg
gulp.task 'copyImg', ->
  gulp.src createSrcArr 'img'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'copyImg'
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[copyImg]: #{path}"

# copyOthers
gulp.task 'copyOthers', ->
  gulp.src createSrcArr 'others'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'copyOthers'
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[copyOthers]: #{path}"


############
### html ###
############

# jade
gulp.task 'jade', ->
  gulp.src createSrcArr 'jade'
  .pipe changed PUBLISH_DIR, { extension: '.html' }
  .pipe plumber errorHandler: errorHandler 'jade'
  .pipe data -> require DATA_JSON
  .pipe jade
    pretty: true
    basedir: SRC_DIR
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[jade]: #{path}"

# jadeAll
gulp.task 'jadeAll', ->
  gulp.src createSrcArr 'jade'
  .pipe plumber errorHandler: errorHandler 'jadeAll'
  .pipe data -> require DATA_JSON
  .pipe jade
    pretty: true
    basedir: SRC_DIR
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[jadeAll]: #{path}"

# html
gulp.task 'html', [ 'copyHtml', 'jade' ]


###########
### css ###
###########

# sass
gulp.task 'sass', ->
  gulp.src createSrcArr 'sass'
  .pipe changed PUBLISH_DIR, { extension: '.css' }
  .pipe plumber errorHandler: errorHandler 'sass'
  .pipe sass
    unixNewlines: true
    "sourcemap=none": true
    style: 'expanded'
  .pipe autoprefixer()
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[sass]: #{path}"

# sassAll
gulp.task 'sassAll', ->
  gulp.src createSrcArr 'sass'
  .pipe plumber errorHandler: errorHandler 'sass'
  .pipe sass
    unixNewlines: true
    "sourcemap=none": true
    style: 'expanded'
  .pipe autoprefixer()
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[sassAll]: #{path}"

# css
gulp.task 'css', [ 'copyCss', 'sass' ]


##########
### js ###
##########

# jshint
gulp.task 'jshint', ->
  libFilter = filter [ '**', '!**/lib/**' ]
  gulp.src createSrcArr 'js'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'jshint'
  .pipe libFilter
  .pipe jshint()
  .pipe jshint.reporter()
  .pipe notify (file)-> return if file.jshint.success then false else 'jshint error'

# coffee
gulp.task 'coffee', ->
  gulp.src createSrcArr 'coffee'
  .pipe changed PUBLISH_DIR, { extension: '.js' }
  .pipe plumber errorHandler: errorHandler 'coffeelint'
  .pipe coffee()
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[coffee]: #{path}"

# coffeeAll
gulp.task 'coffeeAll', ->
  gulp.src createSrcArr 'coffee'
  .pipe plumber errorHandler: errorHandler 'coffeelint'
  .pipe coffee()
  .pipe gulp.dest PUBLISH_DIR
  .pipe print (path)-> "[coffeeAll]: #{path}"

# js
gulp.task 'js', [ 'copyJs', 'coffee' ]


############
### json ###
############

# jsonlint
gulp.task 'jsonlint', ->
  gulp.src createSrcArr 'json'
  .pipe changed PUBLISH_DIR
  .pipe plumber errorHandler: errorHandler 'jsonlint'
  .pipe jsonlint()
  .pipe jsonlint.reporter()
  .pipe notify (file)-> return if file.jsonlint.success then false else 'jsonlint error'

# json
gulp.task 'json', [ 'copyJson' ]


###########
### img ###
###########

# sprite
createSpritesTask 'commonSprites', "#{ASSETS_DIR}/img/common", "#{ASSETS_DIR}/css/_sprites", "../img/common/commonSprites.png"

gulp.task 'sprites', spritesTask


###############
### watcher ###
###############

# watcher
gulp.task 'watcher', ->
  gulp.watch paths.html, [ 'copyHtml' ]
  gulp.watch paths.css, [ 'copyCss' ]
  gulp.watch paths.js, [ 'copyJs' ]
  gulp.watch paths.json, [ 'copyJson' ]
  gulp.watch paths.img, [ 'copyImg' ]
  gulp.watch paths.others, [ 'copyOthers' ]
  gulp.watch createSrcArr('jade'), [ 'jade' ]
  gulp.watch createSrcArr('sass'), [ 'sass' ]
  gulp.watch createSrcArr('coffee'), [ 'coffee' ]

  # インクルードファイル(アンスコから始まるファイル)更新時はすべてをコンパイル
  gulp.watch paths.jadeInclude, [ 'jadeAll' ]
  gulp.watch paths.sassInclude, [ 'sassAll' ]
  gulp.watch paths.coffeeInclude, [ 'coffeeAll' ]

  for task in  watchSpritesTasks then task()

  gulp.src PUBLISH_DIR
  .pipe webserver
    livereload: true
    port: 50000
    open: true
    host: '0.0.0.0'
  .pipe notify 'start local server. http://localhost:50000/'


#############
### bower ###
#############

gulp.task 'bower', ->
  console.log 'install bower components'
  exec 'bower install', (err, stdout, stderr)->
    if err
      console.log err
    else
      console.log stdout

      jsFilter = filter '**/*.js'
      cssFilter = filter '**/*.css'
      gulp.src bower
        debugging: true
        includeDev: true
        paths:
          bowerDirectory: BOWER_COMPONENTS
          bowerJson: 'bower.json'
      .pipe plumber errorHandler: errorHandler
      .pipe jsFilter
      .pipe gulp.dest "#{SRC_DIR}#{ASSETS_DIR}/js/lib"
      .pipe jsFilter.restore()
      .pipe cssFilter
      .pipe gulp.dest "#{SRC_DIR}#{ASSETS_DIR}/css/_sprites/lib"
      .pipe cssFilter.restore()
      .pipe notify 'done bower task'


############
### init ###
############

gulp.task 'init', [ 'bower' ]


###############
### default ###
###############

gulp.task 'default', [ 'clean' ], ->
  runSequence [ 'json', 'sprites' ], [ 'html', 'css', 'js', 'copyImg', 'copyOthers', 'concat' ], ->
    gulp.src(PUBLISH_DIR).pipe notify 'build complete'
