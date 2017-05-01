util = require 'util'
module.exports.setupIntervals = (lolClient, ipcMain, config, mainWindow, db) ->
  # Check to see if the person is in game
  inGame = false;
  ranked = false;
  flex = false;
  lpInterval = null
  checkIfInGame = ->
    util.log "Checking to see if #{config.accounts[0].name} is in a game..."
    lolClient.getCurrentGame {
      region: config.accounts[0].region
      id: config.accounts[0].id
    }, (err, data) ->
      if err # We aren't in a game
        if inGame # We just finished a match
          inGame = false
          db.matchlist.find({}).sort({'timestamp': -1}).exec (err, docs) ->
            if err
              throw err
            else
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
                else
                  db.matchlist.insert data.matches, (err) ->
                    if err
                      throw err
                    else # Get the match data
                      lolClient.getMatch {
                        id: data.matches[0]
                      }, (err, data2) ->
                        # Add match data to db
                        db.matches.insert data2, (err) ->
                          if err
                            throw err
                          # Now we can go back and mark the matchlist entry as having the match
                          db.matchlist.update {matchId: data.matches[0].matchId}, {matchInDb: true}, (err) ->
                            if err
                              throw err
                            else
                              getIfWin data, (win) ->
                                if config.lpUpdateOption is "manually"
                                  # Prompt the user to tell us how much lp they gained/lost
                                  mainWindow.webContents.send 'newMatchLPGainLoss', {
                                    win: win
                                    matchId: data.matches[0].matchId
                                    queue: (if flex then "flex" else "solo")
                                    unixTime: data.matches[0].gameCreation
                                  }

                                else
                                  lpInterval = setInterval checkForChangeInLP, 30000
                                  # We have to start checking to see if the LP updates on the API
      if data # We are in a game
        inGame = true
        if data.gameQueueConfigId is 420
          flex = false
        else if data.gameQueueConfigId is 440
          flex = true
        else
          ranked = false
          flex = false
          inGame = false
  checkIfInGame()
  inGameInterval = setInterval checkIfInGame, 30000
  checkForChangeInLP = ->
    # Check for changes in LP
  getIfWin = (data, cb) ->
    for player in data.participantIdentities
      if player.player.accountId is config.accounts[0].id
        if data.participants[player.participantId - 1].stats.win is true then return cb true
        return cb false
