# Basic imports
e = require 'electron'
app = e.app
fs = require 'fs'
pathExists = require 'path-exists'
config = require '../../../../config.json'
path = require 'path'
Datastore = require 'nedb'
BrowserWindow = e.BrowserWindow
ipcMain = e.ipcMain
loljs = require 'lol-js'
lolClient = null;
util = require 'util'
screen = (require 'electron').screen
screen_width = screen.getPrimaryDisplay().workAreaSize.width
screen_height = screen.getPrimaryDisplay().workAreaSize.height
db = {} # Create empty object to store database objects in
mainWindow = null;
lolClient = loljs.client
  apiKey: config.riotApiKey
###
  INITIAL STARTUP PROCESS
###
# Create window
mainWindow = new BrowserWindow
  show: false
  resizable: false
  width: screen_width
  height: screen_height
  title: "LP-Tracker"
mainWindow.maximize()
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
  page.send 'loadingDatabasesFinished', {}
  # Step 4: Check to see if we have any matches in the database,
  # if not, download all. If we do, look for new matches.
  db.matchlist.find({}).sort({'timestamp': -1}).exec (err, docs) ->
    if err
      throw err
    else
      if docs.length is 0 # There are no matches in the database!
        lolClient.getMatchlistBySummoner(config.accounts[0].region, config.accounts[0].id, {rankedQueues: ['TEAM_BUILDER_RANKED_SOLO', 'RANKED_FLEX_SR', 'RANKED_SOLO_5x5', 'RANKED_TEAM_3x3', 'RANKED_TEAM_5x5', 'TEAM_BUILDER_DRAFT_RANKED_5x5']}).then (data) ->
          util.log "Got #{data.matches.length} matches"
          db.matchlist.insert data.matches, (err) ->
            if err
              throw err
            else
              page.send 'loadingMatchlistFinished', {}
              util.log 'Yay we added the matches to the database'
      else
        util.log "Run"
        lolClient.getMatchlistBySummoner(config.accounts[0].region,
          config.accounts[0].id,
          {
            rankedQueues: ['TEAM_BUILDER_RANKED_SOLO',
              'RANKED_FLEX_SR',
              'RANKED_SOLO_5x5',
              'RANKED_TEAM_3x3',
              'RANKED_TEAM_5x5',
              'TEAM_BUILDER_DRAFT_RANKED_5x5'],
            beginTime: (Number(docs[0].timestamp) + 1)
        }).then (data) ->
          if not data.matches
            util.log "No new matches detected"
            page.send 'loadingMatchlistFinished', {}
          else
            util.log "Got #{data.matches.length} new matches"
            db.matchlist.insert data.matches, (err) ->
              if err
                throw err
              else
                page.send 'loadingMatchlistFinished', {}
        # Get new matches

  # Check to see if we need to load new matches
