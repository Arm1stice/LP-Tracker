util = require 'util'
currentLeague = null
currentTier = null
currentLP = null
currentMiniSeries = null;
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
        mainWindow.webContents.send 'inAGame', {inGame: false}
        if inGame # We just finished a match
          inGame = false
          db.matchlist.find({}).sort({'timestamp': -1}).exec (err, docs) ->
            util.log "Getting timestamp of most recent game in database..."
            if err
              throw err
            else
              util.log "Getting new matchlist..."
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
                  util.log "Inserting matchlist into matchlist db...."
                  db.matchlist.insert data.matches, (err, doc) ->
                    console.log doc
                    if err
                      throw err
                    else # Get the match data
                      util.log "Successful! Getting match data..."
                      lolClient.getMatch {
                        id: data.matches[0].matchId
                        options:
                          includeTimeline: false
                      }, (err, data2) ->
                        if err then throw err
                        util.log "Got match data, inserting into matches db..."
                        # Add match data to db
                        db.matches.insert data2, (err, doc2) ->
                          if err
                            throw err
                          util.log "Inserted into db! Updating matchlist entry with id of #{doc[0]._id} to say that the match is now in db"
                          # Now we can go back and mark the matchlist entry as having the match
                          db.matchlist.update {_id: doc[0]._id}, {$set: {matchInDb: true}}, (err) ->
                            if err
                              throw err
                            else
                              util.log "Done! Checking to see if we won or not..."
                              getIfWin data2, (win) ->
                                util.log "Done! (#{win}) Sending over the event...."
                                if config.lpUpdateOption is "manually"
                                  # Prompt the user to tell us how much lp they gained/lost
                                  mainWindow.webContents.send 'newMatchLPGainLoss', {
                                    win: win
                                    matchId: data.matches[0].matchId
                                    queue: (if flex then "flex" else "solo")
                                    unixTime: data.matches[0].gameCreation
                                  }
                                else
                                  # Automatic checking is still in development
                                  #lpInterval = setInterval checkForChangeInLP, 30000
                                  # We have to start checking to see if the LP updates on the API
      if data # We are in a game
        inGame = true
        if data.gameQueueConfigId is 420
          flex = false
          mainWindow.webContents.send 'inAGame', {inGame: true, type: 'Solo/Duo'}
        else if data.gameQueueConfigId is 440
          mainWindow.webContents.send 'inAGame', {inGame: true, type: 'Flex'}
          flex = true
        else
          ranked = false
          flex = false
          inGame = false
  checkForChangeInLP = ->
    # Check for changes in LP
  getIfWin = (data, cb) ->
    win = false;
    for player in data.participantIdentities
      if player.player.accountId is config.accounts[0].id
        if data.participants[player.participantId - 1].stats.win is true then win = true
    cb win
  getLP = (cb) ->
    lp = {
      solo:
        tier: null
        division: null
        lp: null
        wins: null
        losses: null
        series:
          inSeries: false
          wins: null
          losses: null
      flex: {
        tier: null
        division: null
        lp: null
        wins: null
        losses: null
        series:
          inSeries: false
          wins: null
          losses: null
      }
    }
    lolClient.getLeagueEntries {
      region: config.accounts[0].region
      id: config.accounts[0].id
    }, (err, data) ->
      if err
        # They aren't ranked at all
        cb lp
      else
        data = data[config.accounts[0].id.toString()]
        for ranking in data
          if ranking.queue is "RANKED_SOLO_5x5" # Solo ranked
            lp.solo.tier = ranking.tier
            lp.solo.division = ranking.entries[0].division
            lp.solo.lp = ranking.entries[0].leaguePoints
            lp.solo.wins = ranking.entries[0].wins
            lp.solo.losses = ranking.entries[0].losses
            if ranking.entries[0].miniSeries isnt undefined
              lp.solo.series.inSeries = true
              lp.solo.series.wins = ranking.entries[0].miniSeries.wins
              lp.solo.series.losses = ranking.entries[0].miniSeries.losses
          else if ranking.queue is "RANKED_FLEX_SR" # Flex ranked
            lp.flex.tier = ranking.tier
            lp.flex.division = ranking.entries[0].division
            lp.flex.lp = ranking.entries[0].leaguePoints
            lp.flex.wins = ranking.entries[0].wins
            lp.flex.losses = ranking.entries[0].losses
            if ranking.entries[0].miniSeries isnt undefined
              lp.flex.series.inSeries = true
              lp.flex.series.wins = ranking.entries[0].miniSeries.wins
              lp.flex.series.losses = ranking.entries[0].miniSeries.losses
        cb lp
  checkIfInGame()
  getLP (lp) -> mainWindow.webContents.send "lpUpdate", lp
  inGameInterval = setInterval checkIfInGame, 30000
