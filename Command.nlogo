;====================================
;== Simulation and Model variables ==
;====================================
globals[
  ;== Simulation Globals ==
  ;-- Counters --
  TimeUnits       ;how many ticks have passed
  
  ;-- Cruft --
  RandomRunNum    ;random number for unique filenames
  FileName        ;file name to save as
  
  ;== Model Globals ==
  ;-- Units --
  UnitMax         ;max soldiers added to a unit before iterating
  
  ;-- Infantry --
  InfPopulation   ;how many soldiers to start with
  InfSize         ;how much space a soldier takes
  InfRange        ;max distance infantry effectively fights at
  InfView         ;distance infantry can see
  InfSpeed        ;distance infantry can move
  InfAttack       ;strength of infantry attack
  InfDefense      ;strength of infantry defense
  InfHealth       ;how hard infantry is to kill
  InfVisionAngle  ;what angle, centered on facing direction, infantry can see
  InfSearchAngle  ;what angle, centered on facing direction, infantry will attack
  
  WaitCount time between movements 
  BeforeFormation?
]

;================================
;== Breeds and Breed variables ==
;================================
breed [commanders commander]
breed [soldiers soldier]

commanders-own[
  allegiance      ;which side they fight for
  effectiveness   ;how good at their job they are
  morale          ;how optimistic they are
]

soldiers-own[
  allegiance      ;which side they fight for
  unit            ;what unit they're associated with
  attack          ;damage they do
  defense         ;resistance to damage
  speed           ;amount they move when it's time
  health          ;amount of damage they can take
  state           ;0 at-rest, 1 moving
  moveTargetX     ;x coordinate trying to move to
  moveTargetY     ;y coordinate trying to move to
  faceTarget      ;direction to face when not moving, in degrees
]

;=====================
;== Setup functions ==
;=====================
to setup
  __clear-all-and-reset-ticks  ;clear the screen
  
  setup-globals
  setup-patches
  setup-soldiers
  setup-units
  setup-commanders
  
  ;FIXME testing
  form-hedgehog 1 -91 67 10
  form-hedgehog 2 -53 -23 15
  form-hedgehog 3 89 -39 25
end

to setup-globals
  ; Simulation
  set RandomRunNum random 999999

  ; Model
  set UnitMax 20
  
  set InfPopulation 50
  set InfSize 5
  set InfRange 5
  set InfView 24
  set InfSpeed 5
  set InfAttack 5
  set InfDefense 10
  set InfHealth 50
  set InfVisionAngle 120
  set InfSearchAngle  90
  
  set WaitCount 10  
  set BeforeFormation? true
end

to setup-patches
  ;ask patches  [set pcolor green]         ;NOTE ungodly inefficient
  import-drawing "France.png"
end

to setup-soldiers
  create-soldiers (InfPopulation)[
    set color blue
    set allegiance 1
    set state 0
    set speed (random 2) + InfSpeed        ;FIXME random adjustments should be based on global vars
    set attack (random 2) + InfAttack
    set defense (random 2) + InfDefense
    set health (random 5) + InfHealth
    set moveTargetX "NaN"
    set moveTargetY "NaN"
    set faceTarget "NaN"
    set size 4
  ]
end

to setup-units  
  let thisUnit 1                           ;NOTE units are 1-based
  let numInUnit 0
  ask soldiers [
    ifelse numInUnit < UnitMax [
      set unit thisUnit
      set numInUnit (numInUnit + 1)
    ] [
      set thisUnit (thisUnit + 1)
      set unit thisUnit
      set numInUnit 1
    ]
  ]

  let soldierNum 0
  ask soldiers with [unit = 1] [
    set color yellow
    set heading 90
    setxy 10 (10 + InfSize * soldierNum)
    set soldierNum (soldierNum + 1)
  ]
  
  set soldierNum 0
  ask soldiers with [unit = 2] [
    set color white
    set heading 180
    setxy 30 (10 + InfSize * soldierNum)
    set soldierNum (soldierNum + 1)
  ]
  
  set soldierNum 0
  ask soldiers with [unit = 3] [
    set color red
    set heading 270
    setxy 50 (10 + InfSize * soldierNum)
    set soldierNum (soldierNum + 1)
  ]
end

to setup-commanders
  create-commanders (1)[
    set color blue
    set allegiance 1
    set effectiveness 10
    set morale 100
  ]
end

;================
;== Main Logic ==
;================
to go
  ifelse BeforeFormation? [
    move-soldiers
    orient-soldiers
    if timeUnits = 18[
      set BeforeFormation? false
    ]
  ]
  [attack-soldiers]
  ; for each orderunit move to average x and y of the group as center, with the speed
  set TimeUnits (TimeUnits + 1)
end

to move-soldiers
  ask soldiers with [is-number? moveTargetX] [                  ;NOTE just check X for performance reasons
    facexy moveTargetX moveTargetY
    let distanceToGo (distancexy moveTargetX moveTargetY)
    ifelse ( distanceToGo > speed) [
      forward speed
      set state 1                                               ;FIXME needs to be set somewhere better
    ] [
      forward distanceToGo
      set moveTargetX "NaN"
      set moveTargetY "NaN"
      set state 0
    ]
  ]
end

to orient-soldiers
  ask soldiers with [is-number? faceTarget and state = 0] [
    facexy (cos(faceTarget) + xcor) (sin(faceTarget) + ycor)
    set faceTarget "NaN"
  ]
end

to attack-soldiers
    ask soldiers [ 
    ;wait x ticks between each move so everything is visible
    ifelse (WaitCount <= 0)[
      if(any? soldiers with [color = red] and (any? soldiers with [color = white] or any? soldiers with [color = yellow]) )[
        interact
      ]
      set WaitCount  10; set up to wait for 10 ticks until each unit moves again
    ]
    [
      set WaitCount WaitCount - 1;if we are waiting to move then continue the count down until we do
    ]          
  ]
  ifelse(any? soldiers with [color = red] and (any? soldiers with [color = white] or any? soldiers with [color = yellow]))[;go until all of one army is dead
    set TimeUnits TimeUnits + 1;increase the counter for the total number of ticks that have gone by so far   
  ]
  [
    file-close
    stop
  ]   
end  

to interact     
  let opponent 0
  set opponent nearest other-turtles;opponent always exists because of conditional in integrate function
  set heading towards opponent
  ifelse distance opponent <= InfRange[;if there is an opponent in contact then kill the one with less strength
      ifelse attack > [attack] of opponent[
        die
      ]
      [
        ask opponent[
          die
        ]
      ]
  ]
  [
    forward speed
   ;ask soldiers with [color = red] [forward speed] 
  ]      
end   

to-report nearest [agentset]
  ifelse color = red[
    report min-one-of agentset with [color = white] [distance myself];find nearest agent in a group    
  ]
  [
    report min-one-of agentset with [color = red] [distance myself];find nearest agent in a group
  ]
end

to-report other-turtles
   report turtles with [self != myself] 
end


;=====================
;== Formation Logic ==
;=====================
to form-hedgehog [orderUnit orderCX orderCY orderRadius]
  let soldiersInUnit (count soldiers with [unit = orderUnit])
  let theta (360 / soldiersInUnit)                              ;how many degrees should separate soldiers
  
  let soldierNum 0
  ask soldiers with [unit = orderUnit] [                        ;naive deployment, no accounting for distance
    let thisTheta (theta * soldierNum)
    set moveTargetX (cos(thisTheta) * orderRadius + orderCX)
    set moveTargetY (sin(thisTheta) * orderRadius + orderCY)
    set faceTarget thisTheta
    set soldierNum (soldierNum + 1)
  ]
end
