{CompositeDisposable} = require 'atom'
path = require 'path'
wch = require 'wch'
fs = require 'fsx'

{workspace} = atom

subs = null
linter = null

safe = (fn) -> ->
  try fn.apply this, arguments
  catch err
    console.error err

none = []
events =

  'file:build': (event) ->
    linter.setMessages event.file, none

  'file:error': (event) ->
    linter.setMessages event.file, [
      severity: 'error'
      excerpt: event.message
      location:
        file: event.file
        position: event.location
    ]

hasWchPlugin = (deps) ->
  return false unless deps
  for name of deps
    return true if /^wch-/.test name
  return false

module.exports =

  activate: safe ->
    subs = new CompositeDisposable

    for id, fn of events
      subs.add wch.on id, fn

    # Auto-watch projects that depend on wch plugins.
    subs.add atom.project.onDidChangePaths (projectPaths) ->
      for projectPath in projectPaths
        packPath = path.join projectPath, 'package.json'
        continue unless fs.isFile packPath
        try deps = JSON.parse(fs.readFile packPath).devDependencies
        wch projectPath if hasWchPlugin deps

  deactivate: safe ->
    subs.dispose()
    return

  _livereload: (watch) ->
    watch 'wch-ide',
      include: ['lib/**/*.coffee', 'package.json']

  _linter: (Linter) ->
    linter = Linter
      name: 'wch-ide'
    subs.add linter
