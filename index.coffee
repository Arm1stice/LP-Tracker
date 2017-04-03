# Import all the stuffs
console.time 'init'
e = require 'electron'
app = e.app
fs = require 'fs'
pathExists = require 'path-exists'
path = require 'path'
BrowserWindow = e.BrowserWindow
ipcMain = (require 'electron').ipcMain
loljs = require 'lol-js'
lolClient = null;
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
    #fs.createReadStream(path.join __dirname, "../../../config.default.json").pipe(fs.createWriteStream(path.join __dirname, "../../../config.json"))
    mainWindow = new BrowserWindow {
      width: 500
      height: 300
      show: false
      resizable: false
      title: "Setup LP-Tracker"
    }
    mainWindow.loadURL "file://#{__dirname}/views/initial.html"
    mainWindow.webContents.once 'did-finish-load', ->
      console.timeEnd 'init'
      mainWindow.center()
      mainWindow.show()
      #mainWindow.webContents.openDevTools {mode: "detach"}
    ipcMain.on 'initialSetupInfo', (event, arg) -> #Initial API Key, Summoner Info, and Region
      console.log arg
      lolClient = loljs.client {
        apiKey: arg.apiKey
      }
      lolClient.getSummonersByName arg.region, [arg.summonerName], (err, data) ->
        if err
          event.sender.send 'initialSetupResponse', {error: 1} # API Key invalid
        else
          console.log data
          if not data[summonerName]
            event.sender.send 'initialSetupResponse', {error: 2} # Summoner/Region invalid
          else
            # Import the default config, change the values, and save the config
            configTemplate = require '../../../config.default.json'
            configTemplate.riotApiKey = arg.apiKey
            data.region = arg.region
            configTemplate.accounts.push data
            fs.writeFile '../../../config.json', JSON.stringify data, (err) ->
              if err
                throw err
              else
                # Next we can open the actual window! Yay, progress!
  else
    # In this scenario, the api key is already set and the application is set up already, so we just open the main window
    lptConfig = require '../../../config.json' # Import the config
    console.log 'exists'
