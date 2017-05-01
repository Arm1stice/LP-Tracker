# Basic imports
e = require 'electron'
app = e.app
fs = require 'fs'
pathExists = require 'path-exists'
path = require 'path'
BrowserWindow = e.BrowserWindow
ipcMain = (require 'electron').ipcMain
KindredAPI = require 'kindred-api'
REGIONS = KindredAPI.REGIONS
LIMITS = KindredAPI.LIMITS
CACHE_TYPES = KindredAPI.CACHE_TYPES
lolClient = null;
formatSummonerName = (name) -> return name.replace(/\s/g, '').toLowerCase()
# Start of logic for initial start
mainWindow = new BrowserWindow {
  width: 500
  height: 300
  show: false
  resizable: false
  title: "Setup LP-Tracker"
}
mainWindow.webContents.on 'will-navigate', (event) ->
  event.preventDefault()
mainWindow.loadURL "file://#{__dirname}/../views/initial.html"
mainWindow.webContents.once 'did-finish-load', ->
  console.timeEnd 'init'
  mainWindow.show()
  #mainWindow.webContents.openDevTools {mode: "detach"}
ipcMain.on 'initialSetupInfo', (event, arg) -> #Initial API Key, Summoner Info, and Region
  console.log arg
  lolClient = new KindredAPI.Kindred {
    key: arg.apiKey
    defaultRegion: REGIONS.NORTH_AMERICA
    debug: false
    limits: 'dev'
    cacheOptions: CACHE_TYPES[0]
  }
  lolClient.getSummoner {
    region: arg.region
    name: arg.summonerName
  }, (err, data) ->
    if err
      console.error err
      event.sender.send 'initialSetupResponse', {error: 1} # API Key invalid
    else
      summonerInfo = data
      if summonerInfo == undefined
        event.sender.send 'initialSetupResponse', {error: 2} # Summoner/Region invalid
      else
        # Import the default config, change the values, and save the config
        event.sender.send 'initialSetupResponse', {}
        ipcMain.once 'lpUpdateOption', (event, arg2) ->
          console.log __dirname
          configTemplate = JSON.parse fs.readFileSync path.join __dirname, '../../../../config.default.json'
          configTemplate.riotApiKey = arg.apiKey
          configTemplate.lpUpdateOption = arg2
          summonerInfo.region = arg.region
          configTemplate.accounts.push summonerInfo
          fs.writeFile (path.join __dirname, '../../../../config.json'), JSON.stringify(configTemplate), (err) ->
            console.log "got callback"
            if err
              console.log err
            else
              # Next we can open the actual window! Yay, progress!
              require './index.coffee'
              mainWindow.close()
