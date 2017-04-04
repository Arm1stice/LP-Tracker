# Import all the stuffs
console.time 'init'
e = require 'electron'
app = e.app
path = require 'path'
pathExists = require 'path-exists'
BrowserWindow = e.BrowserWindow
globalShortcut = require('electron').globalShortcut
# Here we goooo
app.once 'ready', ->
  mainWindow = null;
  globalShortcut.register 'Super+D', ->
    BrowserWindow.getFocusedWindow().webContents.openDevTools {mode: 'detach'}
  ###
    Initial run - We have to copy the default config file
  ###
  if not pathExists.sync path.join __dirname, "../../../config.json"
    require './src/initial.coffee'
  else
    # In this scenario, the api key is already set and the application is set up already, so we just open the main window
    lptConfig = require '../../../config.json' # Import the config
    require './src/index.coffee'
    console.log 'exists'
