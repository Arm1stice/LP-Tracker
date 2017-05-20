/*
  iterateLP - Returns a new Tier and Division given an old Tier and Division and whether the player is getting promoted or demoted
  Arguments:
   - lp: An object containing the player's old LP
    - type: object
    - properties:
      - oldTier: The player's old tier (eg. BRONZE)
        - type: string
      - oldDivision: The player's old division (eg. IV)
        - type: string
  - goUp: A boolean value describing whether the player is getting promoted or demoted
    - type: boolean
  - cb: The callback function which returns the new LP as JSON
    - type: function
      - arguments:
        - newLP: An object containing the new LP
          - type: object
          - properties:
            - newTier: The new tier (eg. CHALLENGER)
              - type: string
            - newDivision: The new division (eg. I)
              - type: string
*/
function iterateLP(lp, goUp, cb){
  var newLP = {};
  var tiers = [
    'BRONZE',
    'SILVER',
    'GOLD',
    'PLATINUM',
    'DIAMOND',
    'MASTER',
    'CHALLENGER'
  ]
  var divisions = [
    'V',
    'IV',
    'III',
    'II',
    'I'
  ]
  tierIndex = tiers.indexOf(lp.oldTier)
  console.log("Tier Index: " + tierIndex)
  divisionIndex = divisions.indexOf(lp.oldDivision)
  // If we get promoted
  if(goUp === true){
    // If we were first division, we go up a tier instead of just a division
    if(lp.oldDivision === "I"){
      newLP.newDivision = divisions[0]
      newLP.newTier = tiers[++tierIndex]
      cb(newLP)
    }else{
      newLP.newTier = lp.oldTier
      newLP.newDivision = divisions[++divisionIndex]
      cb(newLP)
    }
  // If we get demoted
  }else{
    // If we were fifth division, then we go down a tier instead of just a division.
    if(lp.oldDivision === "V"){
      newLP.newDivision = divisions[divisions.length - 1]
      newLP.newTier = tiers[--tierIndex]
      cb(newLP)
    }else{
      newLP.newTier = lp.oldTier
      newLP.newDivision = divisions[--divisionIndex]
      cb(newLP)
    }
  }
}
