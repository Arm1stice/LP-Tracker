util = require 'util'

getMatchAndInsert = (matchId, doc, lolClient, db, done) ->
  util.log "[getMatchAndInsert] Getting match data for match #{matchId}..."
  lolClient.getMatch {
    id: matchId
    options:
      includeTimeline: true
  }, (err, data) ->
    if err then return done err
    util.log "[getMatchAndInsert] Got match data, inserting into matches db..."
    # Add match data to db
    db.matches.insert data, (err, doc2) ->
      if err
        done err
      if doc isnt null
        util.log "[getMatchAndInsert] Inserted into db! Updating matchlist entry with id of #{doc[0]._id} to say that the match is now in db"
        # Now we can go back and mark the matchlist entry as having the match
        db.matchlist.update {_id: doc._id}, {$set: {matchInDb: true}}, (err) ->
          if err
            done err
          else
            util.log "[getMatchAndInsert] Updated matchlist entry. Function calling back succcessfully!"
            done null, data
      else
        # If we are just inserting the match (if you played norms instead of rank) then we don't need to update matchlist db
        util.log "[getMatchAndInsert] Inserted into db! 'doc' argument set to null, so not updating matchlist db"
        done null, data
module.exports.getMatchAndInsert = getMatchAndInsert

updateMatchListDb = (config, lolClient, db, done) ->
  # Sort the matches in the matchlist based on the timestamp
  db.matchlist.find({}).sort({'timestamp': -1}).exec (err, docs) ->
    util.log "[updateMatchListDb] Getting timestamp of most recent game in database..."
    if err
      throw err
    else
      util.log "[updateMatchListDb] Getting new matchlist..."
      # Now, we get the new matchlist from the api, only getting matches since at least one millisecond after the last match in the database, so that way there are no duplicates
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
          done err
        else
          util.log "[updateMatchListDb] Inserting matchlist into matchlist db...."
          # Insert the new matches into the matchlist database
          db.matchlist.insert data.matches, (err, doc) ->
            if err
              done err
            else
              util.log "[updateMatchListDb] Successful!"
              done null, doc[0]
module.exports.updateMatchListDb = updateMatchListDb

getIfWin = (data, done) ->
  win = false;
  for player in data.participantIdentities
    if player.player.accountId is config.accounts[0].id
      if data.participants[player.participantId - 1].stats.win is true then win = true
  done win
module.exports.getIfWin = getIfWin

getLP = (config, lolClient, done) ->
  lp =
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
        target: null
    flex:
      tier: null
      division: null
      lp: null
      wins: null
      losses: null
      series:
        inSeries: false
        wins: null
        losses: null
        target: null
  lolClient.getLeagueEntries {
    region: config.accounts[0].region
    id: config.accounts[0].id
  }, (err, data) ->
    if err
      # They aren't ranked at all
      done null
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
            lp.solo.series.target = ranking.entries[0].miniSeries.target
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
            lp.flex.series.target = ranking.entries[0].miniSeries.target
            lp.flex.series.losses = ranking.entries[0].miniSeries.losses
      done lp
module.exports.getLp = getLp
