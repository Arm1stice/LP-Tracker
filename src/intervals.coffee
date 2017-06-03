util = require 'util'
utils = require './utils'
currentDivision = null
currentTier = null
currentLP = null
currentMiniSeries = null
module.exports.setupIntervals = (lolClient, ipcMain, config, mainWindow, db) ->
  # Check to see if the person is in game
  inGame = false
  ranked = false
  flex = false
  matchId = null
  lpInterval = null
  checkIfInGame = ->
    util.log "[checkIfInGame] Checking to see if #{config.accounts[0].name} is in a game..."
    lolClient.getCurrentGame {
      region: config.accounts[0].region
      id: config.accounts[0].id
    }, (err, data) ->
      if err # We aren't in a game
        mainWindow.webContents.send 'inAGame', {inGame: false}
        if inGame # We just finished a match
          inGame = false
          if ranked is true
            utils.updateMatchListDb config, lolClient, db, (err, doc) ->
              if err then throw err
              utils.getMatchAndInsert matchId, doc, lolClient, db, (err, data) ->
                if err then throw err
                util.log "[checkIfInGame] Done! Checking to see if we won or not..."
                utils.getIfWin data, (win) ->
                  util.log "[checkIfInGame] Done! (#{win}) Sending over the event...."
                  if config.lpUpdateOption is "manually"
                    # Prompt the user to tell us how much lp they gained/lost
                    mainWindow.webContents.send 'newMatchLPGainLoss', {
                      win: win
                      matchId: matchId
                      queue: (if flex then "flex" else "solo")
                      unixTime: data.matches[0].gameCreation
                      oldTier: currentTier
                      oldDivision: currentDivision
                      oldLP: currentLP
                      oldSeries: currentMiniSeries
                    }
                    ipcMain.removeAllListeners 'lpUpdateModal'
                    ipcMain.on 'lpUpdateModal', (event, data) ->
                      util.log "[checkIfInGame] Got update modal info"
                      dbToUse = db.solo
                      if data.queue is "flex" then dbToUse = db.flex
                      dbToUse.insert data, (err) ->
                        if err then throw err
                        mainWindow.webContents.send 'updateLPGraphs', {} # Tell the client to update the graphs, since we just added new info to the database
                  else
                    # Automatic checking is still in development
                    #lpInterval = setInterval checkForChangeInLP, 30000
                    # We have to start checking to see if the LP updates on the API
          else
            # If it is a norm, then we just add the match data into the matches database and move on
            utils.getMatchAndInsert matchId, null, lolClient, db, (err, data) ->
              if err then throw err
              util.log "[checkIfInGame] Added norm match data into database"
          ranked = false
          matchId = null
      if data # We are in a game
        matchId = data.gameId # Set matchId variable to the matchid of the current game so that way we save an api call when the player's game finshes
        if data.gameQueueConfigId is 420 or data.gameQueueConfigId is 440
          if not inGame # If this is the first time we have realized we are in the game
            util.log "This is the first time we have realized we are in a game. Getting current LP..."
            utils.getLp config, lolClient, (lp) ->
              if data.gameQueueConfigId is 420
                currentLP = lp.solo.lp
                currentTier = lp.solo.tier
                currentDivision = lp.solo.division
                if lp.solo.series.inSeries is true
                  currentMiniSeries = lp.solo.series
                else
                  currentMiniSeries = null
              else
                currentLP = lp.flex.lp
                currentTier = lp.flex.tier
                currentDivision = lp.flex.division
                if lp.flex.series.inSeries is true
                  currentMiniSeries = lp.flex.series
                else
                  currentMiniSeries = null
        if data.gameQueueConfigId is 420
          mainWindow.webContents.send 'inAGame', {inGame: true, ranked: true, type: 'Solo/Duo'}
          inGame = true
          ranked = true
          flex = false
        else if data.gameQueueConfigId is 440
          mainWindow.webContents.send 'inAGame', {inGame: true, ranked: true, type: 'Flex'}
          inGame = true
          ranked = true
          flex = true
        else
          mainWindow.webContents.send 'inAGame', {inGame: true, ranked: false}
          ranked = false
          flex = false
          inGame = true
  checkIfInGame()
  updateLP = ->
    util.log "[updateLP] Updating LP..."
    utils.getLp config, lolClient, (lp) ->
      mainWindow.webContents.send "lpUpdate", lp
  updateLP()

  updateLPInterval = setInterval updateLP, 60000
  inGameInterval = setInterval checkIfInGame, 30000
