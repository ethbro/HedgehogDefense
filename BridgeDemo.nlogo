extensions [array]
globals[
  ;MACROS
  UNIT_NAME
  UNIT_ICON
  UNIT_FORMATION
  COLOR_FR
  COLOR_GR

  WaitCount
   time-units      ;monitor to show the number of  goes 
   x; waiting positions for the units while they wait to cross the bridge
   y
   bridgeX; the start and end of the bridge
   bridgeY
   bridgeOccupied;boolean that announces if the bridge can be entered
   bridgeWait; time between the movement of the unit on the bridge
   randomrunnum    ;crappy hack to get unique filenames for each run in behaviourspace experiments
   filename        ;place for aforementioned filename
   fInfAccuracy
   fHedgAccuracy
   fTankAccuracy
   fArtAccuracy
   gInfAccuracy
   gTankAccuracy
   gArtAccuracy
   fInfDmg
   fHedgeDmg
   fTankDmg
   fArtDmg
   gInfDmg
   gTankDmg
   gArtDmg
   FrUnits
   GrUnits
]
breed [soldiers soldier]
soldiers-own[
  allegience;are they fighting for side 1 or 2?
  effectiveness
  maxRange;
  minRange;
  speed; amount they move when its time
  numInfantry;
  startingInfantry;
  numHedgehogs;
  startingHedgehogs
  numTanks
  startingTanks;
  numArtillary
  startingArtillary; 
  hitsTaken
  destinationX;where the unit is heading
  destinationY
  destinationNum;the position the unit has chosen to wait in
  state; 1 ready, 2 moving, 3 crossing bridge, 4 crossed bridge
]

to setup
  __clear-all-and-reset-ticks;clear the screen
  
  setup-globals;get all the fields set to their starting values 
  setup-patches
  setupSoldiers
end
to setup-patches
  import-drawing "AbbevilleBridge.png";background image
end
to setup-globals
  ; MACROS
  set UNIT_NAME 0
  set UNIT_ICON 1
  set UNIT_FORMATION 2
  set COLOR_FR 96   ; aka NATO friendly "light blue"
  set COLOR_GR 16   ; aka NATO hostile "light red"

  set randomrunnum random 999999
  set x array:from-list [145 142 157 134 164 154 161 145 136 166]
  set y array:from-list [174 179 172 181 168 186 181 192 195 176]

  ; List of French Units
  ; Unit name, appropriate shape name, commanding unit name
  set FrUnits [["3rd Cavalry Brigade" "brigade cavalry" "2nd Light Cavalry Division" ]
               ["12th Light Mechanized Brigade" "brigade light mechanized" "2nd Light Cavalry Division"]
               ["73rd Artillery Regiment" "brigade artillery" "2nd Light Cavalry Division"]
               ["6th Cavalry Brigade" "brigade cavalry" "5th Light Cavalry Division"]
               ["15th Light Mechanized Brigade" "brigade light mechanized" "5th Light Cavalry Division"]
               ["78th Artillery Regiment" "brigade artillery" "5th Light Cavalry Division"]
               ;FIXME French units need proper positioning (2nd Cav Div in close, 5th Cav Div farther back)
  ]

  ; List of German units (see above for formatting)
  set GrUnits [["25th Panzer Regiment" "brigade armored" "7th Panzer Division"]
               ["6th Motorized Infantry Regiment" "brigade motorized" "7th Panzer Division"]
               ["7th Motorized Infantry Regiment" "brigade motorized" "7th Panzer Division"]
               ["78th Motorized Artillery Regiment" "brigade artillery" "7th Panzer Division"]
               ;FIXME need to make a motorized artillery icon /\
               ["X Panzer Regiment" "brigade armored" "X Panzer Division"]
               ["Y Motorized Infantry Regiment" "brigade motorized" "X Panzer Division"]
               ["Z Motorized Infantry Regiment" "brigade motorized" "X Panzer Division"]
               ["A Motorized Artillery Regiment" "brigade artillery" "X Panzer Division"]
               ;FIXME need actual German units attacking from the Abbeville bridgehead
  ]
  set bridgeX array:from-list [153 141]
  set bridgeY array:from-list [168 140]
  set bridgeOccupied false
  set bridgeWait 4
  set WaitCount 10
  set fInfAccuracy 1; in percent out of 100
  set fHedgAccuracy 7
  set fTankAccuracy 5
  set fArtAccuracy 7
  set gInfAccuracy 1
  set gTankAccuracy 5
  set gArtAccuracy 5
  set fInfDmg 1;number of units it kills
  set fHedgeDmg 1
  set fTankDmg 1
  set fArtDmg 1
  set gInfDmg 1
  set gTankDmg 1
  set gArtDmg 1
end

to setupSoldiers
  ; Create French units
  let i 0
  create-soldiers (10) [
    ;let unitInfo (item i FrUnits)
    set i (i + 1)

    ;let thisIcon (item UNIT_ICON UnitInfo)
    set shape ("brigade infantry")
    set color COLOR_FR

    set effectiveness 100
    set startingInfantry 4000
    set numInfantry startingInfantry
    set startingHedgehogs 0
    set numHedgehogs startingHedgehogs
    set startingTanks 0
    set numTanks startingTanks
    set startingArtillary 0
    set numArtillary startingArtillary
    set maxRange 100
    set minRange 10
    set hitsTaken 0
    set speed 1
    set allegience 1
    set state 1
    set destinationX -1
    set destinationY -1
    set destinationNum -1
    set size 7
    set heading 40
  ]

  ; Create German units
  set i 0
  create-soldiers (10)[
    ;let unitInfo (item i GrUnits)
    set i (i + 1)

    ;let thisIcon (item UNIT_ICON UnitInfo)
    ;set shape (word thisIcon)
    set shape ("brigade infantry")
    set color COLOR_GR

    set startingInfantry 4000
    set numInfantry startingInfantry
    set startingHedgehogs 0
    set numHedgehogs startingHedgehogs
    set startingTanks 0
    set numTanks startingTanks
    set startingArtillary 0
    set numArtillary startingArtillary
    set maxRange 100
    set minRange 10
    set speed 1
    set allegience 2
    set hitsTaken 0
    set state 1
    set destinationX -1
    set destinationY -1
    set destinationNum -1
    set size 7
    set heading 220
  ]
  ask soldiers[
    ifelse color = COLOR_GR [
      setxy 120 + 5 * who (270 - 5 * who)
    ] [
      if(who < 5)[
        setxy 140 - 5 * who (120 + 5 * who)
      ]
      if(who > 4)[
       setxy 170 - 5 * who (100 + 5 * who)
      ]
    ]
  ]
end

to Step
  set time-units time-units + 1;increase the counter for the total number of ticks that have gone by so far 
  ask soldiers[
    if(any? soldiers with [color = COLOR_GR] and any? soldiers with [color = COLOR_FR])[
        attack
    ]  
  ]
  ask soldiers[
    getMoveOrders
    move
  ]
  ask soldiers[
    applyDamage 
  ]
end

to Steps
  repeat 50[
   Step 
  ]
end

to move
  if(state = 2)[;if the unit is moving toward a waiting position go toward it until it's too close to move farther
    ifelse(absolute-value (destinationX - xcor) < speed and absolute-value (destinationY - ycor) < speed)[
      ;if the unit reached its waiting position face the enemies and set its state to ready to move
      setxy destinationX destinationY
      facexy 125 125
      set state 1
    ]
    [
      ;if it hasn't reached its waiting point move toward it at its normal speed
      facexy destinationX destinationY
      forward speed
    ]
  ]
  if(state = 3)[
    ;if the unit is crossing the bridge wait a set time, then move a step across
    ifelse(bridgeWait = 0)[
     set bridgeWait 4;reset the wait time after he moves
     facexy destinationX destinationY
     forward 1 
    ]
    [
      set bridgeWait (bridgeWait - 1);decrease the wait time if it isn't ready to move
    ]
  ]
end

to getMoveOrders
  if(state = 1 and allegience = 2)[;for the ready germans
    let i 0
    let goal -1
    ;find the nearest empty waiting spot to fill in at
    repeat 10[
      if(goal = -1)[
        if not(any? soldiers with[destinationNum = i])[
          if(i < destinationNum or destinationNum = -1)[
            set goal i
            ;set that waiting spot as the units destination and state that the spot is occupied
            set state 2
            set destinationX (array:item x i) 
            set destinationY (array:item y i)
            set destinationNum i
          ]
        ]
      ]
      set i (i + 1)
    ]
  ]
  ;if the bridge is empty and the unit nearest the bridge is ready for orders
  if(destinationNum = 0 and state = 1 and bridgeOccupied = false)[
   ;set it to crossing the bridge and announce that its space is now available for someone else to take
   set destinationNum -1
   set state 3
   set destinationX (array:item bridgeX 1)
   set destinationY (array:item bridgeY 1)
   set bridgeOccupied true
  ]
  ;if the unit has gotten across the bridge
  if(state = 3 and absolute-value ((array:item bridgeX 1) - xcor) < speed and absolute-value ((array:item bridgeY 1) - ycor) < speed)[
    ;set its state to having crossed the bridge and announce that the bridge is empty and ready for someone else to cross
   set state 4
   set bridgeOccupied false
  ]
  ;if a unit has crossed the bridge
  if(state = 4)[
    ;move toward the nearest opponent if there are any, otherwise move to the bottom left of the map
    let opponent 0     
    ifelse(any? soldiers with [color = COLOR_FR])[
      set opponent nearest other-turtles with[allegience = 1];opponent always exists because of conditional in integrate function
      ifelse(distance opponent < speed)[
        set heading towards opponent
      ]
      [
        set heading towards opponent
        forward speed
      ]        
    ]
    [
      set destinationX 0
      set destinationY 0
      ifelse(absolute-value (destinationX - xcor) > speed and absolute-value (destinationY - ycor) > speed)[
        facexy destinationX destinationY
        forward speed
      ]
      [
        facexy destinationX destinationY
      ]
    ]
  ]
end

;run procedure
to go 
  ask soldiers [ 
    ;wait x ticks between each move so everything is visible
    ifelse (WaitCount <= 0)[
      Step
      set WaitCount  10; set up to wait for 10 ticks until each unit moves again
    ]
    [
      set WaitCount WaitCount - 1;if we are waiting to move then continue the count down until we do
    ]          
  ]
  if time-units >= 5000[ ;after a set amount of time stop the simulation
    file-close
    stop
  ]            
end  

to applyDamage
  if(allegience = 1)[
    ;for every hit the unit took assign a random soldier within the unit to die
     repeat hitsTaken[
        let whatsHit random (numInfantry + numTanks + numArtillary + numHedgehogs + 1 )
        if(whatsHit <= numInfantry)[
          set numInfantry numInfantry - 1
          if(numInfantry < 0)[
            set numInfantry  0
          ]
        ]
        ifelse(whatsHit <= (numInfantry + numTanks) and whatsHit > numInfantry)[
         set numTanks numTanks - 1 
         if(numTanks < 0)[
            set numTanks  0
          ]
        ][
        ifelse(whatsHit <= (numInfantry + numTanks + numArtillary) and whatsHit > (numInfantry + numTanks))[
         set numArtillary numArtillary - 1 
         if(numArtillary < 0)[
            set numArtillary  0
          ]
        ] 
        [
         set numHedgehogs numHedgehogs - 1 
         if(numHedgehogs < 0)[
            set numHedgehogs  0
          ]
        ]
        ]
      ]
     ;once all the hits have been applied reset the counter
      set hitsTaken 0
      set effectiveness (numInfantry + numHedgehogs + numTanks + numArtillary) / (startingInfantry + startingHedgehogs + startingTanks + startingArtillary)
      if( effectiveness = 0)[
        ;if there are no soldiers left inside the unit
        die
      ]
   ]
   if(allegience = 2)[
     repeat hitsTaken[
        let whatsHit random (numInfantry + numTanks + numArtillary + 1)
        if(whatsHit <= numInfantry)[
          set numInfantry numInfantry - 1
          if(numInfantry < 0)[
            set numInfantry 0
          ]
        ]
        ifelse(whatsHit <= (numInfantry + numTanks) and whatsHit > numInfantry)[
         set numTanks numTanks - 1 
         if(numTanks < 0)[
            set numTanks 0
          ]
        ][
         set numArtillary numArtillary - 1 
         if(numArtillary < 0)[
            set numArtillary 0
          ]
        ] 
      ]
      set hitsTaken 0
      set effectiveness (numInfantry + numTanks + numArtillary) / (startingInfantry + startingTanks + startingArtillary)
      if( effectiveness = 0)[
        if(state = 3)[
          set bridgeOccupied false
        ]
        if(destinationNum >= 0)[
          set destinationNum -1
        ]
        die
      ]
   ]
end       
                         
to attack     
  let opponent 0
  set opponent nearest other-turtles;opponent always exists because of conditional in integrate function
  ;currently finds the nearest enemy unit and starts shooting at them. 
  if(distance opponent <= maxRange)[
    if( allegience = 1)[
      repeat (numInfantry / 10)[
        if(random 100 <=  fInfAccuracy)[
          ask opponent[ set hitsTaken hitsTaken + fInfDmg]
        ]
      ]
      repeat numHedgehogs[
        if(random 100 <=  fHedgAccuracy)[
          ask opponent[ set hitsTaken hitsTaken + fHedgeDmg]
        ]
      ]
      repeat numTanks[
        if(random 100 <=  fTankAccuracy)[
          ask opponent[ set hitsTaken hitsTaken + fTankDmg]
        ]
      ]
      repeat numArtillary[
        if(random 100 <=  fArtAccuracy)[
          ask opponent[ set hitsTaken hitsTaken + fArtDmg]
        ]
      ]
    ]
    if( allegience = 2)[
      repeat (numInfantry / 10)[
        if(random 100 <=  gInfAccuracy)[
          ask opponent[ set hitsTaken hitsTaken + gInfDmg]
        ]
      ]
      repeat numTanks[
        if(random 100 <=  gTankAccuracy)[
          ask opponent[ set hitsTaken hitsTaken + gTankDmg]
        ]
      ]
      repeat numArtillary[
        if(random 100 <=  gArtAccuracy)[
          ask opponent[ set hitsTaken hitsTaken + gArtDmg]
        ]
      ]
    ]  
  ]     
end   
;removes negatives, used for finding distance to someone
to-report absolute-value [number]
  ifelse number >= 0
    [ report number ]
    [ report (- number) ]
end

to-report nearest [agentset]
  ifelse color = COLOR_GR [
    report min-one-of agentset with [color = COLOR_FR] [distance myself]          ;;find nearest agent in a group    
  ]
  [
    report min-one-of agentset with [color = COLOR_GR] [distance myself]          ;;find nearest agent in a group
  ]
end

to-report other-turtles
   report turtles with [self != myself] 
end
@#$#@#$#@
GRAPHICS-WINDOW
437
10
1049
643
-1
-1
2.0
1
4
1
1
1
0
1
1
1
0
300
0
300
0
0
1
ticks
30.0

BUTTON
16
12
83
45
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
277
62
340
95
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
350
11
428
56
NIL
time-units
0
1
11

BUTTON
82
65
145
98
Step
step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
157
63
251
96
Step (50)
Steps
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 151 152 137 77 105 67 89 67 66 74 48 85 36 100 24 116 14 134 0 151 15 167 22 182 40 206 58 220 82 226 105 226 134 222
Polygon -16777216 true false 151 150 149 128 149 114 155 98 178 80 197 80 217 81 233 95 242 117 246 141 247 151 245 177 234 195 218 207 206 211 184 211 161 204 151 189 148 171
Polygon -7500403 true true 246 151 241 119 240 96 250 81 261 78 275 87 282 103 277 115 287 121 299 150 286 180 277 189 283 197 281 210 270 222 256 222 243 212 242 192
Polygon -16777216 true false 115 70 129 74 128 223 114 224
Polygon -16777216 true false 89 67 74 71 74 224 89 225 89 67
Polygon -16777216 true false 43 91 31 106 31 195 45 211
Line -1 false 200 144 213 70
Line -1 false 213 70 213 45
Line -1 false 214 45 203 26
Line -1 false 204 26 185 22
Line -1 false 185 22 170 25
Line -1 false 169 26 159 37
Line -1 false 159 37 156 55
Line -1 false 157 55 199 143
Line -1 false 200 141 162 227
Line -1 false 162 227 163 241
Line -1 false 163 241 171 249
Line -1 false 171 249 190 254
Line -1 false 192 253 203 248
Line -1 false 205 249 218 235
Line -1 false 218 235 200 144

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

brigade
false
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60

brigade armored
false
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60
Circle -16777216 true false 45 120 90
Circle -16777216 true false 165 120 90
Rectangle -16777216 true false 90 120 210 210
Circle -7500403 true true 60 135 60
Circle -7500403 true true 180 135 60
Rectangle -7500403 true true 90 135 210 195

brigade artillery
false
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60
Circle -16777216 true false 120 135 60

brigade cavalry
false
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60
Polygon -16777216 true false 270 90 285 90 285 105 30 240 15 240 15 225

brigade infantry
true
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60
Polygon -16777216 true false 30 90 15 90 15 105 270 240 285 240 285 225
Polygon -16777216 true false 15 225 15 240 30 240 285 105 285 90 270 90

brigade light mechanized
false
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60
Circle -16777216 true false 45 120 90
Circle -16777216 true false 165 120 90
Rectangle -16777216 true false 90 120 210 210
Circle -7500403 true true 60 135 60
Circle -7500403 true true 180 135 60
Rectangle -7500403 true true 90 135 210 195
Polygon -16777216 true false 270 90 285 90 285 105 30 240 15 240 15 225

brigade mechanized
false
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60
Circle -16777216 true false 45 120 90
Circle -16777216 true false 165 120 90
Rectangle -16777216 true false 90 120 210 210
Circle -7500403 true true 60 135 60
Circle -7500403 true true 180 135 60
Rectangle -7500403 true true 90 135 210 195
Polygon -16777216 true false 270 90 285 90 285 105 30 240 15 240 15 225
Polygon -16777216 true false 30 90 15 90 15 105 270 240 285 240 285 225

brigade motorized
false
0
Rectangle -16777216 true false 0 75 300 255
Rectangle -7500403 true true 15 90 285 240
Polygon -16777216 true false 165 60 180 60 135 15 120 15 165 60
Polygon -16777216 true false 165 15 180 15 135 60 120 60
Polygon -16777216 true false 30 90 15 90 15 105 270 240 285 240 285 225
Polygon -16777216 true false 15 225 15 240 30 240 285 105 285 90 270 90
Rectangle -16777216 true false 137 90 162 240

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

tankleft
true
15
Rectangle -2674135 true false 60 60 90 270
Rectangle -2674135 true false 90 45 150 285
Circle -16777216 true false 54 234 42
Circle -16777216 true false 54 189 42
Circle -16777216 true false 54 144 42
Circle -16777216 true false 54 99 42
Circle -16777216 true false 54 54 42
Rectangle -2674135 true false 180 15 225 105
Rectangle -2674135 true false 180 0 240 15
Rectangle -2674135 true false 255 135 270 195
Rectangle -2674135 true false 135 270 150 300
Rectangle -2674135 true false 120 285 135 300
Rectangle -2674135 true false 120 30 150 45
Rectangle -2674135 true false 135 15 150 30
Rectangle -2674135 true false 165 225 240 240
Rectangle -2674135 true false 150 105 255 225

tankright
true
15
Rectangle -13345367 true false 210 60 240 270
Rectangle -13345367 true false 150 45 210 285
Circle -16777216 true false 204 234 42
Circle -16777216 true false 204 189 42
Circle -16777216 true false 204 144 42
Circle -16777216 true false 204 99 42
Circle -16777216 true false 204 54 42
Rectangle -13345367 true false 75 15 120 105
Rectangle -13345367 true false 60 0 120 15
Rectangle -13345367 true false 30 135 45 195
Rectangle -13345367 true false 150 270 165 300
Rectangle -13345367 true false 165 285 180 300
Rectangle -13345367 true false 150 30 180 45
Rectangle -13345367 true false 150 15 165 30
Rectangle -13345367 true false 60 225 135 240
Rectangle -13345367 true false 45 105 150 225

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144

@#$#@#$#@
NetLogo 5.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="end-reps" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 160 [go]</go>
    <final>print-final-report</final>
    <timeLimit steps="42801"/>
    <metric>report-boys</metric>
    <metric>report-girls</metric>
    <metric>differenciation</metric>
    <metric>girls-beating-boys</metric>
    <enumeratedValueSet variable="attraction?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intensity-of-aggression">
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
