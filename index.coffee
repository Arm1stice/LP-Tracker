# Import all the stuffs
e = require 'electron'
app = e.app
BrowserWindow = e.BrowserWindow

# Here we goooo
app.once 'ready', ->
  console.log "ready"
  mainWindow = new BrowserWindow {
    width: 100
    height: 100
    show: false
  }
  console.log __dirname
  mainWindow.loadURL "file://#{__dirname}/views/index.html"
  mainWindow.webContents.once 'did-finish-load', ->
    mainWindow.show()
