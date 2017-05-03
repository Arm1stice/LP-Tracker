# Basic imports
e = require 'electron'
app = e.app
menu = e.Menu
fs = require 'fs'
pathExists = require 'path-exists'
config = require '../../../../config.json'
path = require 'path'
Datastore = require 'nedb'
BrowserWindow = e.BrowserWindow
ipcMain = e.ipcMain
KindredAPI = require 'kindred-api'
REGIONS = KindredAPI.REGIONS
LIMITS = KindredAPI.LIMITS
CACHE_TYPES = KindredAPI.CACHE_TYPES
lolClient = null;
util = require 'util'
###screen = (require 'electron').screen
screen_width = screen.getPrimaryDisplay().workAreaSize.width
screen_height = screen.getPrimaryDisplay().workAreaSize.height
###
db = {} # Create empty object to store database objects in
mainWindow = null;
lolClient = new KindredAPI.Kindred {
  key: config.riotApiKey
  defaultRegion: REGIONS.NORTH_AMERICA
  debug: true
  limits: 'dev'
  cacheOptions: CACHE_TYPES[0]
}
###
  INITIAL STARTUP PROCESS
###
# Create window
menu.setApplicationMenu null
mainWindow = new BrowserWindow
  show: false
  resizable: false
  center: true
  width: 800
  height: 450
  title: "LP-Tracker"
mainWindow.webContents.on 'will-navigate', (event) ->
  event.preventDefault()
mainWindow.loadURL "file://#{__dirname}/../views/index.html"

# Step 2: Wait for the page to load, using an ipc event instead of did-finish-load to grab the page's ipc object
ipcMain.once 'pageLoaded', (event, arg) ->
  console.timeEnd 'init'
  page = event.sender
  mainWindow.show()
  # Step 3: Load databases
  # Check to see if the db folder exists
  if not pathExists.sync path.join __dirname, "../../../../db"
    util.log 'Creating db folder'
    fs.mkdirSync path.join __dirname, "../../../../db"
  # Add our datastores to the db object
  db.matches = new Datastore
    filename: path.join __dirname, "../../../../db/matches.db"
    autoload: true
  db.matchlist = new Datastore
    filename: path.join __dirname, "../../../../db/matchlist.db"
    autoload: true
  db.solo = new Datastore
    filename: path.join __dirname, "../../../../db/ranked_solo.db"
    autoload: true
  db.flex = new Datastore
    filename: path.join __dirname, "../../../../db/ranked_flex.db"
    autoload: true
  page.send 'loadingDatabasesFinished', {}
  # Step 4: Check to see if we have any matches in the database,
  # if not, download all. If we do, look for new matches.
  db.matchlist.find({}).sort({'timestamp': -1}).exec (err, docs) ->
    if err
      throw err
    else
      if docs.length is 0 # There are no matches in the database!
        lolClient.MatchList.get {
          region: config.accounts[0].region
          id: config.accounts[0].id,
          options:
            rankedQueues: ['TEAM_BUILDER_RANKED_SOLO',
                          'RANKED_FLEX_SR',
                          'RANKED_SOLO_5x5',
                          'RANKED_TEAM_3x3',
                          'RANKED_TEAM_5x5',
                          'TEAM_BUILDER_DRAFT_RANKED_5x5']
        }, (err, data) ->
          if err
            throw err
          util.log "Got #{data.matches.length} matches"
          db.matchlist.insert data.matches, (err) ->
            if err
              throw err
            else
              page.send 'loadingMatchlistFinished', {summonerName: config.accounts[0].name}
              util.log 'Yay we added the matches to the database'
              mainFunction()
      else
        # Check to see if we need to load new matches
        lolClient.getMatchList {
          region: config.accounts[0].region
          id: config.accounts[0].id,
          options:
            rankedQueues: ['TEAM_BUILDER_RANKED_SOLO',
                          'RANKED_FLEX_SR',
                          'RANKED_SOLO_5x5',
                          'RANKED_TEAM_3x3',
                          'RANKED_TEAM_5x5',
                          'TEAM_BUILDER_DRAFT_RANKED_5x5'],
            beginTime: (Number(docs[0].timestamp) + 1)
        }, (err, data) ->
          if err
            throw err
          if not data.matches
            util.log "No new matches detected"
            page.send 'loadingMatchlistFinished', {summonerName: config.accounts[0].name}
            mainFunction()
          else
            util.log "Got #{data.matches.length} new matches"
            db.matchlist.insert data.matches, (err) ->
              if err
                throw err
              else
                page.send 'loadingMatchlistFinished', {}
                mainFunction()

mainFunction = ->
  (require './intervals').setupIntervals lolClient, ipcMain, config, mainWindow, db
