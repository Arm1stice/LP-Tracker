ipcRenderer.on('newMatchLPGainLoss', function(event, gameObject){
  mainProcess = event.sender
  if(gameObject.win === true){
    $("#lpModalWinLoss").text("won")
    $("#lpModalWinLoss").css("color", 'green')
    $("#lpModalAmount").setAttribute('placeholder', 'How much LP did you gain?')
  }else{
    $("#lpModalWinLoss").text("lost")
    $("#lpModalWinLoss").css("color", 'red')
    $("#lpModalAmount").setAttribute('placeholder', 'How much LP did you lose?')
  }
  if(gameObject.queue === 'solo'){
    $("#lpModalTypeOfMatch").text("Solo/Duo")
  }else{
    $("#lpModalTypeOfMatch").text("Flex")
  }
  str = JSON.stringify(gameObject)

  // If you were close to series, ask if you got into series
  if(gameObject.oldLP > 70 && gameObject.oldSeries === null && gameObject.win === true && gameObject.oldTier !== "MASTER" && gameObject.oldTier !== "CHALLENGER"){
    $("#intoSeries").show()
  }else{
    $("#intoSeries").hide()
  }
  // If you were in a series before, we can assume a lot of stuff
  if(gameObject.oldSeries !== null){
    var newSeries = gameObject.oldSeries
    if(gameObject.win === true){
      gameObject.oldSeries.win += 1
    }else{
      gameObject.oldSeries.losses += 1
    }
    // Best of 3
    if(gameObject.oldSeries.target === 2){
      // If we won the series
      if(gameObject.oldSeries.wins === 2){
        iterateLP(gameObject, true, function(newLP){
          
        })
      // We lost the series
      }else if(gameObject.oldSeries.losses === 2){
        // Now we need to ask what LP we got put to now that we lost
      }
    // Best of 5
    }else{
      // If we won the series
      if(gameObject.oldSeries.wins === 3){

      // We lost the series
      }else if(gameObject.oldSeries.losses === 3){

      }
    }
  // Well, if you weren't in a series, but your were at 0 LP and you lost, maybe you just got demoted, we should ask
  }else if(gameObject.oldLP === 0){
    if(gameObject.win === false){
      $("#gotDemoted").show()
    }else{
      $("#gotDemoted").hide()
    }
  }
  $("#lpModalJSON").val(str)
  $('#lpModal').modal('show')
})
