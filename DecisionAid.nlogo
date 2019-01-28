globals [
  participation         ;; Number of participants for the guest lecture
  history               ;; Participation count in previous guest lectures
  food-in-auditorium-patches  ;; agentset of turquoise patches represents participants in auditorium
  auditorium-corridor-patches  ;; agentset of red patches represents participants outside the auditorium
  Food-Remains-patch    ;; patch where we show  "Not Enough Food Left" label
]

turtles-own [
  strategies      ;; list of strategies
  best-strategy   ;; index of the current best strategy
  attend?         ;; true if the agent currently plans to attend the guest lecture
  prediction      ;; accurate prediction of participant count for the guest lecture
  reward          ;; the amount that each agent has been rewarded
]

to setup
  clear-all
  set-default-shape turtles "face happy"

  ;; create the patch for auditorium
  set food-in-auditorium-patches patches with [pxcor < 0 ];;or (pxcor <  0 and pycor >= 0)]
  ask food-in-auditorium-patches [ set pcolor turquoise ]

  ;; create the patch for corridor
  set auditorium-corridor-patches patches with [pxcor > 0 ];;and pycor > 0]
  ask auditorium-corridor-patches [ set pcolor red ]

  ;; initialize the previous participation randomly so the agents have a history to work with from the start
  set history n-values (Previous-Guest-Lectures * 2) [random 100]
  ;; the history is twice the memory, because we need at least a memory worth of history
  ;; for each point in memory to test how well the strategies would have worked

  set participation first history

  ;; use one of the patch labels to visually indicate whether or not the food is available for the
  ;;  new participants who wants to attend the talk in the auditorium.
  ask patch (0.75 * max-pxcor) (0.5 * max-pycor) [
    set Food-Remains-patch self
    set plabel-color 121
  ]
  ;; create the agents and give them random strategies. These are the only strategies these agents will
  ;; ever have though they can change which of this "bag of strategies"
  ;; they use every tick
  create-turtles 100 [
    set color white
    move-to-empty-one-of food-in-auditorium-patches
    set strategies n-values Strategy-Count [random-strategy]
    set best-strategy first strategies
    update-strategies
  ]
  ;; start the clock
  reset-ticks
end

to go
  ;; update the global variables
  ask Food-Remains-patch[
    set plabel ""
  ]
  ;; each agent predicts their participation into the guest lecture based on the food left
  ask turtles [
    set prediction predict-participation best-strategy sublist history 0 Previous-Guest-Lectures
    set attend? (prediction <= Food-Remains) ;; true or false
    ;; scale the turtle's color a shade of blue depending on its reward level (white for little reward, black for high reward)
    set color scale-color yellow reward  (max [ reward ] of turtles + 1) 0
  ]
  ;; depending on their decision, the agents go to auditorium or stay at their work
  ask turtles [
    ifelse attend?
      [ move-to-empty-one-of auditorium-corridor-patches
        set participation participation + 1 ]
      [ move-to-empty-one-of food-in-auditorium-patches ]
  ]

  ;; if there is no enough food for new participants to attend the guest lecture indicate that in the view
  set participation count turtles-on auditorium-corridor-patches
  ifelse participation > Food-Remains [
    ask Food-Remains-patch [ set plabel "Food-Scarcity"]
  ]
  [
    ask turtles with [ attend? ] [
      set reward reward + 1
      ]
    ]

  ;; update the participation history by removing oldest participation and prepending latest participation
  set history fput participation but-last history
  ;; the agents decide what the new best strategy is
  ask turtles [ update-strategies ]
  ;; advance the clock
  tick
end

;; determines which strategy would have predicted the best results had it been used this round.
;; the best strategy is the one that has the sum of smallest differences between the
;; current participation and the predicted participation for each of the preceding
;; weeks (going back MEMORY-SIZE weeks)
;; this does not change the strategies at all, but it does (potentially) change the one
;; currently being used and updates the performance of all strategies
to update-strategies
  ;; initialize best-score to a maximum, which is the lowest possible score
  let best-score Previous-Guest-Lectures * 100 + 1
  foreach strategies [ the-strategy ->
    let score 0
    let week 1
    repeat Previous-Guest-Lectures [
      set prediction predict-participation the-strategy sublist history week (week + Previous-Guest-Lectures)
      set score score + abs (item (week - 1) history - prediction)
      set week week + 1
    ]
    if (score <= best-score) [
      set best-score score
      set best-strategy the-strategy
    ]
  ]
end

;; this reports a random strategy. a strategy is just a set of weights from -1.0 to 1.0 which
;; determines how much emphasis is put on each previous time period when making
;; an participation prediction for the next time period
to-report random-strategy
  report n-values (Previous-Guest-Lectures + 1) [1.0 - random-float 2.0]
end

;; This reports an agent's prediction of the current participation
;; using a particular strategy and portion of the participation history.
;; More specifically, the strategy is then described by the formula
;; p(t) = x(t - 1) * a(t - 1) + x(t - 2) * a(t -2) +..
;;      ... + x(t - MEMORY-SIZE) * a(t - MEMORY-SIZE) + c * 100,
;; where p(t) is the prediction at time t, x(t) is the participation of the guest lecture at time t,
;; a(t) is the weight for time t, c is a constant, and MEMORY-SIZE is an external parameter.
to-report predict-participation [strategy subhistory]
  ;; the first element of the strategy is the constant, c, in the prediction formula.
  ;; If the agent's prediction on participation based the available food in the absence of
  ;; any other data then we multiply each week in the history by its respective weight.
  report 100 * first strategy + sum (map [ [weight week] -> weight * week ] butfirst strategy subhistory)
end

;; In this model it doesn't really matter exactly which patch a turtle is on, only whether the turtle is
;; in the auditorium or the bar corridor.  Nonetheless, to make a nice visualization
;; this procedure is used to ensure that we only have one turtle per patch.
to move-to-empty-one-of [locations]  ;; turtle procedure
  move-to one-of locations
  while [any? other turtles-here] [
    move-to one-of locations
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
300
15
769
485
-1
-1
6.6812
1
25
1
1
1
0
1
1
1
-34
34
-34
34
0
0
1
ticks
10.0

BUTTON
105
190
171
225
Setup
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

SLIDER
50
20
285
53
Previous-Guest-Lectures
Previous-Guest-Lectures
0
10
8.0
1
1
NIL
HORIZONTAL

PLOT
4
242
294
487
Workshop Participation
Food Availablae
Participants
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"participation" 1.0 0 -6459832 true "" "plot participation"
"threshold" 1.0 0 -8630108 true "" ";; plot a threshold line -- the food quantity above this\n;; line represents that there is enough food for the new\n;; participants who wants to attend the guest lecture in\n;; auditorium, otherwise there is not food left.\n\nplot-pen-reset\nplotxy 0 food-remains\nplotxy plot-x-max food-remains"

BUTTON
50
135
127
175
Go-Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
5
15
38
230
Strategy-Count
Strategy-Count
0
20
18.0
1
1
NIL
VERTICAL

SLIDER
45
75
285
108
Food-Remains
Food-Remains
0
20
15.0
1
1
NIL
HORIZONTAL

BUTTON
155
135
290
175
Go-Recursively
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## ACKNOWLEDGMENT
Based on the feedback I recieved from the peers who reviewed my model description I 
developed this model. This my first model, I got the inspiration from El Farol Bar Problem in IABM-chapter 3-Models library.


## WHAT IS IT?

This is a decision aid model for planning an internal workshops in Grad School. Like many grad schools, our grad school also invites few renowned guest lectures every year. In our department whenever there is a guest speaker for a day workshop, the department arranges complimentary food for all the participants. Often times these guest lectures/workshops are open for all  grad school staff and students, and they are free to join/leave at any time during the workshop. For such events, estimating right amount of food is alway an issue; either there is a lot of food left after the event or the ordered food is too less that not everyone in the hall gets atleast one. So with the help of this model I attempted to understand when and how the participants should enter the auditorium based on the availability of food. I think this scenario is akin to El Farol Bar problem by Brian Arthur (1994) as an example of how one might model economic systems of boundedly rational agents who use inductive reasoning.

## HOW IT WORKS

An agent will go to the auditorium on any given workshop day, assuming there is enough food - this number is given by Food-Remains. To predict the participation, each agent has set of prediction stratergies, while the participation count from previous workshops is noted. I used the prediction strategy form El Farol Model, that is represented as a list of weights that determines how the agent believes that each time period of the historical data affects the attendance prediction for the current week.  One of these weights (the first one) is a constant term which allows the baseline of the prediction to be modified. This definition of a strategy from El Farol Bar Problem is actually based on an implementation of Arthur's model as revised by David Fogel et al. (1999). The agent decides which one of its strategies to use by determining which one would have done the best had they used it in the preceding weeks.

The number of potential strategies an agent has is given by Stratergy-Count, and these potential strategies are distributed randomly to the agents during SETUP. As the model runs, at any one tick each agent will only utilize one strategy, based on its previous ability to predict the attendance at the bar. In this version of the El Farol model, agents are given strategies and do not change them once they have them, however since they can change their strategies at any time based on performance, the ecology of strategies being used by the whole population changes over time. The length of the attendance history the agents can use for a prediction or evaluation of a strategy is given by Previous-Guest-Lectures. This evaluation of performance is carried out in Update-Strategies, which does not change the strategies, but rather updates the performance of each strategy by testing it, and then selecting the strategy that has the best performance given the current data.  In order to test each strategy its performance on Previous-Guest-Lectures past days is computed. To make this work, the model actually records twice the Previous-Guest-Lectures historical data so that a strategy can be tested Previous-Guest-Lectures days into the past still using the full Previous-Guest-Lectures data to make its prediction.

## HOW TO USE IT

The Strategy-Count slider controls how many strategies each agent keeps in its memory. The Food-Remains slider controls when there is enough food left for new participants in the auditorium. The Previous-Guest-Lectures slider controls how far back, in the history of attendance, agents remember. To run the model, set the Strategy-Count, Food-Remains and Previous-Guest-Lectures size, press Setup, and then Go-Recursively (Or Go-to test single time). Workshop Participation plot shows the average attendance at the bar over time.

## THINGS TO NOTICE

The turquoise part of the world represents the participants inside the auditorium, while the red part of the world represents lobby outside the auditorium.  Over time the participation will increase and decrease but its mean value comes close to the Food-Remains. As I increased the Stratergy-Count and history i.e.,Previous-Guest-Lectures model tend to predict better.

## CREDITS AND REFERENCES

This model is adapted from:

Rand, W. and Wilensky, U. (1997). NetLogo El Farol model. http://ccl.northwestern.edu/netlogo/models/ElFarol. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model is inspired by a paper by W. Brian Arthur. "Inductive Reasoning and Bounded Rationality", W. Brian Arthur, The American Economic Review, 1994, v84n2, p406-411.

David Fogel et al. also built a version of this model using a genetic algorithm.  "Inductive reasoning and bounded rationality reconsidered", Fogel, D.B.; Chellapilla, K.; Angeline, P.J., IEEE Transactions on Evolutionary Computation, 1999, v3n2, p142-146.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
1
@#$#@#$#@
