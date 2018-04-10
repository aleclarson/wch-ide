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

  'compile': (event) ->
    linter.setMessages event.file, none

  'compile:error': (event) ->
    linter.setMessages event.file, [
      severity: 'error'
      excerpt: event.message
      location:
        file: event.file
        position: event.location
    ]

module.exports =

  activate: safe ->
    subs = new CompositeDisposable
    for id, fn of events
      subs.add wch.on id, fn
    return

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
