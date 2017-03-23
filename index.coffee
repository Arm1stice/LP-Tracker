# Import all the stuffs
e = require 'electron'
app = e.app
fs = require 'fs'
pathExists = require 'path-exists'
path = require 'path'
BrowserWindow = e.BrowserWindow

# Here we goooo
app.once 'ready', ->
  mainWindow = null;
  ###
    Initial run - We have to copy the default config file
  ###
  if not pathExists.sync path.join __dirname, "../../../config.json"
    #fs.createReadStream(path.join __dirname, "../../../config.default.json").pipe(fs.createWriteStream(path.join __dirname, "../../../config.json"))
    mainWindow = new BrowserWindow {
      width: 500
      height: 150
      show: false
      resizable: false
      title: "Setup LP-Tracker"
    }
    mainWindow.loadURL "file://#{__dirname}/views/initial.html"
    mainWindow.webContents.once 'did-finish-load', ->
      mainWindow.show()
  else
    # In this scenario, the api key is already set and the application is set up already, so we just open the main window
    console.log 'exists'
