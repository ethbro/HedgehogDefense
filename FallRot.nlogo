__includes ["libCommon.nls" "libCombatModel.nls" "libBridgeModel.nls"]

;We make use of arrays in the bridge model
extensions [array]

globals[ 
  ; Used for the duration of the retreat phase
  nrTicksToNextRetreatline
]

; Executed when the user click on the 'Setup' button
to setup
  setup-Common ;Procedure found in libCommon. Initializes various system constants.
  setup-CombatModel ;Procedure found in libCombatModel. Initializes attrition coefficients.
  setup-BridgeModel ;Procedure found in libBridgeModel. Initializes staging coordinates.
  setup-globals;Get all the fields set to their starting values.
  setup-patches ;Display the background
  setup-units ;Place brigades and set their attributes.
end

to setup-globals
  set nrTicksToNextRetreatline 15 ; Defined for the duration of the retreat phase
  setup-bridge-sliders ;Logic to handle various inputs for the bridge crossing sliders.
end

to setup-patches
 import-drawing "Map.png" ;Sets up the map background.
end

to setup-units
  ;Creates German infantry brigades, sets their color red, makes them face towards the French, and places them on the map.
  create-units (188) [
    c_writeUnit DefaultGermanUnit
    
    set name "German infantry"
    set allegiance GERMAN
    set heading 225
    set color 15
    set state 1
    set newState sn_ATTACK
    set destinationNum -1
    set curSpeed 1
    place-germans ;Procedure found in libBridgeModel. Places German brigades in random clusters.
  ]
  ;Creates German tank brigades, sets their color red, makes them face towards the French, and places them on the map.
  create-units (24) [
    c_writeUnit DefaultGermanUnit
    
    set name "German tank"
    set allegiance GERMAN
    set heading 225  
    set color 15
      
    set state 1
    set newState sn_ATTACK
    set destinationX -1
    set destinationY -1
    set destinationNum -1
    set curSpeed 1
    place-germans  ;Procedure found in libBridgeModel. Places German brigades in random clusters.
  ]  
  ;Creates French infantry brigades, sets their color blue, makes them face towards the Germans.
  create-units (116)[
    c_writeUnit DefaultFrenchUnit
    
    set name "French infantry"
    set allegiance FRENCH
    set heading INITIAL_FRENCH_HEADING
    set color 95

    set state 1
    set newState sn_P_DEFENSE
    set destinationX -1
    set destinationY -1
    set destinationNum -1
    set stepsTaken 0
    set numberOfLinesPassed 0
  ]
  ;Creates French light brigades, sets their color blue, makes them face towards the Germans.
  create-units (6) [
    c_writeUnit DefaultFrenchUnit
    
    set name "French light"
    set allegiance FRENCH
    set heading INITIAL_FRENCH_HEADING
    set color 95

    set state 1
    set newState sn_P_DEFENSE
    set destinationX -1
    set destinationY -1
    set destinationNum -1
    set stepsTaken 0
    set numberOfLinesPassed 0
  ]
  ;Creates French armored brigades, sets their color blue, makes them face towards the Germans.
  create-units (10) [
    c_writeUnit DefaultFrenchUnit

    set name "French armor"
    set allegiance FRENCH
    set heading INITIAL_FRENCH_HEADING
    set color 95

    set state 1
    set newState sn_P_DEFENSE
    set destinationX -1
    set destinationY -1
    set destinationNum -1
    set stepsTaken 0
    set numberOfLinesPassed 0
  ]      
  ; Places the French in a checkerboard pattern.
  ask units with [allegiance = FRENCH] [
    ifelse (who < 278) [
      setxy (110 + round(3.83 * (who - 212))) (471 + round(-2.56 * (who - 212))) + (remainder who 2) * 8
    ] [
    setxy (363 + round(3.46 * (who - 278))) (302 + round(.5 * (who - 278))) + (remainder who 2) * 8     
    ]
  ]
end

;This procedure is called when the user presses the 'Go' button.
to go
  ;Movement
  ask units with [effectiveness > 0] [
    ;Since Lanchester only goes to 0 only in the asymptotic case, zero out small units
    if (curInf < 25) [
      set effectiveness 0
      set color gray
      set size 4
    ]
    if (allegiance = GERMAN and state < 4) [
      selectBridge ;Procedure found in libBridgeModel. Initializes destinations of the German brigades before the bridge crossing takes place.
      crossBridge ;Procedure found in libBridgeModel. Logic for the German brigades crossing the bridge.
    ]
    move
  ]
  
  ;Combat
  ask units with [effectiveness > 0] [cm_declareTarget] ;Procedure found in libCombatModel.
  ask units with [effectiveness > 0] [cm_attritTargets] ;Procedure found in libCombatModel.
  ask units with [effectiveness > 0] [cm_realizeAttrition] ;Procedure found in libCombatModel.
  clear-links
  if(numBridges > MaxBridgeheads)[
   set numBridges MaxBridgeheads 
  ]
  if(numBridges < MaxBridgeheads and ticks > (hoursBetweenBridgeheads * numBridges))[ ;After 500 hours...
    set numBridges numBridges + 1 ;Two bridgeheads wide for the crossing
  ]
  if (ticks >= 42800) [        ;after a set amount of time stop the simulation
    stop
  ]
  tick
end


to move
  let nearestEnemy c_nearestEnemy ;Procedure found in libCommon. Returns the nearest opponent.
  if (nearestEnemy = nobody) [stop]
  let enemyDistance c_distance nearestEnemy ;Procedure found in libCommon. Returns the distance to the nearest opponent.
  
  ;GERMAN BEHAVIOR
  ifelse (allegiance = GERMAN) [ ;If the unit is German...
    if (state = 4 or state = 5) [  ;If it just crossed the bridge...
      if (enemyDistance > curDRange) [ ;If the enemy is out of range...
        face nearestEnemy ; Face the nearest enemy
        ifelse (enemyDistance > curSpeed) [ ;If the enemy can't be reached in an hour
          jump curSpeed ;Approach the enemy
        ] [
          jump (enemyDistance - 0.3)             ;else, approach the enemy at a reduced distance
        ]
      ]
    ]
  ;FRENCH BEHAVIOR
  ] [
    ifelse (newState != sn_RETREAT) [
      if (enemyDistance < 2 * curIRange) [face c_nearestEnemy]  ;face the nearest enemy
    ] [

;======================RETREAT LOGIC START=====================================    
;if the french brigade has less than 70% left, it retreats to the first zone
    if (numberOfLinesPassed = 0)[
      ;output-print (who + 100000)
      if ( stepsTaken = 0 ) [ ;If the first retreat has just started, turn around.
        set heading ((INITIAL_FRENCH_HEADING + 180) mod 360)
      ]
      
      ifelse ( stepsTaken = nrTicksToNextRetreatline ) [ ;If the first retreat has just ended, turn around.
        rt 180
        set retreatState 0
        set newState sn_DEFENSE
        set beginEffectiveness effectiveness
        set numberOfLinesPassed 1
      ][
        if ( stepsTaken < nrTicksToNextRetreatline ) [ ;If the first retreat is in progress, continue to move.
          jump curSpeed
        ]
      ]
      if not ( stepsTaken > nrTicksToNextRetreatline ) [ ;Increment the steps taken.
        set stepsTaken (stepsTaken + 1)
      ]
    ]
    
    ;if the french brigade has less than 50% left, it retreats to the second zone
    if (numberOfLinesPassed = 1) [
      ;output-print (who + 200000)
      if ( stepsTaken = nrTicksToNextRetreatline + 1 ) [ ;If the second retreat has just started, turn around.
        set heading ((INITIAL_FRENCH_HEADING + 180) mod 360)
      ]
      
      ifelse ( stepsTaken = 2 * nrTicksToNextRetreatline ) [ ;If the second retreat has just ended, turn around.
        rt 180
        set retreatState 0
        set newState sn_DEFENSE
        set beginEffectiveness effectiveness
        set numberOfLinesPassed 2
      ][
      if ( stepsTaken < 2 * nrTicksToNextRetreatline ) [ ;If the second retreat is in progress, continue to move.
        jump curSpeed
      ]
      ]
      if not ( stepsTaken > 2 * nrTicksToNextRetreatline ) [ ;Increment the steps taken.
        set stepsTaken (stepsTaken + 1)
      ]
    ]
    
    ;if the french brigade has less than 30% left, it retreats to the third zone
    if (numberOfLinesPassed = 2) [
      ;output-print (who + 300000)
      if ( stepsTaken = 2 * nrTicksToNextRetreatline + 1 ) [ ;If the third retreat has just started, turn around.
        set heading ((INITIAL_FRENCH_HEADING + 180) mod 360)
      ]
      
      ifelse ( stepsTaken = 3 * nrTicksToNextRetreatline ) [ ;If the third retreat has just ended, turn around.
        rt 180
        set retreatState 0
        set newState sn_DEFENSE
        set beginEffectiveness effectiveness
        set numberOfLinesPassed 3
      ][
      if ( stepsTaken < 3 * nrTicksToNextRetreatline ) [;If the third retreat is in progress, continue to move.
        jump curSpeed
        
      ]
      ]
      if not ( stepsTaken > 3 * nrTicksToNextRetreatline ) [ ;Increment the steps taken.
        set stepsTaken (stepsTaken + 1)
      ]
      
    ]
    ;======================RETREAT LOGIC END=====================================
    
    
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
435
9
1093
688
-1
-1
1.013
1
4
1
1
1
0
0
0
1
0
639
0
639
0
0
1
ticks
30.0

BUTTON
16
11
83
44
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
17
66
80
99
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
432
56
NIL
Ticks
0
1
11

SLIDER
15
152
187
185
crossingAbbeville
crossingAbbeville
0
212
53
1
1
NIL
HORIZONTAL

SLIDER
15
196
187
229
crossingAmiens
crossingAmiens
0
212
41
1
1
NIL
HORIZONTAL

SLIDER
16
243
188
276
crossingBray
crossingBray
0
212
30
1
1
NIL
HORIZONTAL

SLIDER
18
291
190
324
crossingPeronne
crossingPeronne
0
212
34
1
1
NIL
HORIZONTAL

SLIDER
14
109
186
142
crossingChannel
crossingChannel
0
212
54
1
1
NIL
HORIZONTAL

PLOT
18
337
218
487
Forces
Time
Soldiers
0.0
100.0
0.0
190000.0
true
true
"" "if(plotForces = true)[\nlet numGerman 0\nlet numFrench 0\nask turtles[\nif(allegiance = GERMAN)[\nset numGerman numGerman + curInf + curAT + curArt + curTanks\n]\nif(allegiance = FRENCH)[\nset numFrench numFrench + curInf + curAT + curArt + curTanks\n]\n]\nset-current-plot-pen \"French\"\nplot numFrench\nset-current-plot-pen \"German\"\nplot numGerman\n]"
PENS
"German" 1.0 0 -2674135 true "" ""
"French" 1.0 0 -13791810 true "" ""

SWITCH
225
338
354
371
plotForces
plotForces
0
1
-1000

MONITOR
198
278
365
331
Number of Bridgeheads
numBridges
0
1
13

SWITCH
225
374
353
407
fireAnimation
fireAnimation
0
1
-1000

SLIDER
195
109
404
142
FrenchForceRetreat
FrenchForceRetreat
0
1
0.82
0.01
1
attrition
HORIZONTAL

SLIDER
196
196
431
229
hoursBetweenBridgeheads
hoursBetweenBridgeheads
1
1000
100
1
1
NIL
HORIZONTAL

SLIDER
198
242
370
275
MaxBridgeheads
MaxBridgeheads
0
10
10
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is an agent-based simulation that represents the first week of Fall Rot in the Battle of France of World War II. The Germans (in red), deploying the Blitzkrieg tactic, attack fortified French positions, "hedgehogs," (in blue) across the river. This scenario opens up interesting tactical questions of how the allocation and speed of the German bridge crossing impacts attrition. Each arrow represents a brigade.

## HOW IT WORKS

German brigades will move towards French static positions and both sides engage each other with direct and indirect fire (based on the distance). The Lanchester model of attrition was used. Retreat will start once the number of soldiers in a brigade reaches a certain pre-defined level.

## HOW TO USE IT

The 'Setup' button will place the brigades in their initial positions, where the French positions are in a checkerboard pattern. The Go button will make the simulation run (each tick represents one hour). The user may set the numbers of brigades that are crossing each bridge. Further, to analyze attrition, the user may plot the forces in the Interface tab and inspect statistics of both sides. Lastly, the user may choose to animate fire.

## THINGS TO NOTICE

The 'Forces' plot will give insight to the attrition dynamics based on the parameters the user has chosen to set.

## THINGS TO TRY

The analyst can choose to vary the bride-crossing mobility of the German forces and its impact on attrition by enabling the 'plotForces' switch.

## EXTENDING THE MODEL

Mobility could be made more accurate by taking into account human factor studies.
The hedgehog defense could be analyzed in more depth and in isolation in a submodel at the scope of individual soldiers and obstacles (urban warfare).
Command and control features could be added to make brigades act with higher intelligence and communication. 

## NETLOGO FEATURES

This simulation makes use of includes.

## RELATED MODELS

There don't appear to be any military models in the NetLogo library.

## CREDITS AND REFERENCES

INTA 6742 Project
Team 4 - Operation Fall Rot
Manuel Aguilar
John Bieniek
Ethan Brown
Philip Pecher
David Richards
Lucas Smith
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
