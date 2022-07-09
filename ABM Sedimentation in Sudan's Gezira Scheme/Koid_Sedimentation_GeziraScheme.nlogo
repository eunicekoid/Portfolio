__includes ["canal-scheme.nls" "output-results.nls" "create-sediments.nls" "maintenance.nls"]

globals [
  elevation-min                  ;; minimum elevation above sea level [m]
  elevation-max                  ;; maximum elevation above sea level [m]
  sediment-concentration         ;; sediment concentration [kg/m^3]
  settling-velocity              ;; velocity at which sediments settle [m/s]
  offtake-proportion             ;; proportion of sediments that move from the major canal to the minor canals [-]
  central-maintenance-capacity   ;; capacity of centralized maintenance [%]
  sediment-removal-full-capacity ;; max amount of sediments that can be removed in one time step from all minor canals [m^3]
  n-minors-to-maintain           ;; number of minors to maintain [-]
  adhoc-maintenance-capacity     ;; capacity of adhoc maintenance [%]
  tenant-removal-full-capacity   ;; max amount of sediments that tenants can remove in one time step from all minor canals [m^3]
  max-deposition-flux            ;; maximum deposition flux of sediments in minor canals [kg/m^2/s]
  max-minor-depth                ;; maximum depth of the minor canals [m]
  sediment-depth-threshold       ;; sediment depth at which adhoc maintenance starts (when it is noticed) [percent of max-minor-depth]
  total-sediments-minor          ;; total amount of sediments deposited in minor canals [m^3]
  total-sediments-major          ;; total amount of sediments deposited in major canal [m^3]
  avg-sediment-depth-major       ;; average sediment depth in major canal [m]
  avg-sediment-depth-minor       ;; average sediment depth across all minor canals [m]
  max-minor-volume               ;; maximum volume of the minor canal
  water-inflow                   ;; water inflow for major canal [m^3/s]
  crit-shear-erosion             ;; critical shear stress for erosion [N/m^2]
  crit-shear-deposition          ;; critical shear stress for deposition [N/m^2]
  rate-of-erosion                ;; rate at which sediments are eroded / resuspended [kg/m^2/s]
  density-dry-sediment           ;; dry sediment density [kg/m^3]
  gravity                        ;; gravity acceleration [m/s^2]
  water-density                  ;; density of water [kg/m^3]
  major-canal-patches            ;; agentset of major canal patches
  minor-canal-patches            ;; agentset of minor canal patches
  canal-patches                  ;; agentset of canal network
  drainage-patches               ;; agentset of drainage patches
  n-sediments-major              ;; number of sediment agents on Major Canal
  n-sediments-minor              ;; number of sediment agents on all Minor Canals combines
  n-sediments                    ;; total number of sediments agents

  ;; Parameters determined by model calibration to scale real world to model world
  cell-size                   ;; [m^2] represents the area of each patch
  scale-factor                ;; [-] scales the model parameters to match empirical data

  ;; Agentsets of minor canal patches
  G/Elhosh-minor-patches
  Gimillia-minor-patches
  Ballol-minor-patches
  W/Elmahi-minor-patches
  Toman-minor-patches
  Gemoia-minor-patches
  G/AbuGomri-minor-patches

  ;; Sediments deposited [m^3] in minor canals
  G/Elhosh-minor-sediments
  Gimillia-minor-sediments
  Ballol-minor-sediments
  W/Elmahi-minor-sediments
  Toman-minor-sediments
  Gemoia-minor-sediments
  G/AbuGomri-minor-sediments

  ;; Sediments desilted [m^3] from minor canals
  G/Elhosh-desilted-sediments
  Gimillia-desilted-sediments
  Ballol-desilted-sediments
  W/Elmahi-desilted-sediments
  Toman-desilted-sediments
  Gemoia-desilted-sediments
  G/AbuGomri-desilted-sediments
]

breed [ sediments sediment ]

patches-own [
  canal-type           ;; "Major" or "Minor" canal
  patch-type           ;; "canal" or "land"
  sediment-depth       ;; sediment layer accumulated on the patch [m]
  elevation            ;; elevation of canal patch [m]
  landmark             ;; name of particular landmarks (e.g., "Gimillia weir") CAN REMOVE LATER
  canal-name           ;; name of minor canal (e.g., "G/Elhosh")
]

sediments-own [
  x-area-scaled       ;; scaled cross-sectional area [m^2]
  bed-slope-scaled    ;; scaled bed slope [m/m]
  Q-scaled            ;; scaled water flow rate [m^3/s]
  Qs-scaled           ;; sediment load * scale-factor [kg/s]
  sediment-volume     ;; volume of sediments the agent carries [m^3]
  deposition-flux     ;; [kg/m^2/s]
  erosion-flux        ;; [kg/m^2/s]
]

to setup
  clear-all

  ;; Set up global variables
  set gravity 9.81                                                                                           ;; [m^2/s]
  set water-density 1000                                                                                     ;; [kg/m^3]
  set sediment-concentration ppm  / 1000                                                                     ;; [kg/m^3] Osman, 2016 and Theol et al., 2019 use a sediment concentration of 6000 ppm in the Major canal
  set settling-velocity (2 * 10 ^ -7 * ppm ^ 0.8 )                                                           ;; [m/s] (Equation empirically determined by Osman, 2015)
  set max-deposition-flux sediment-concentration * settling-velocity                                         ;; Equation from Krone, 1962
  set cell-size 50                                                                                           ;; represents area of each patch [m^2], determined empirically with data from Osman, 2015
  set max-minor-volume 6535.2                                                                                ;; [m^3] The total volume of one minor canal is 6,535.2 m^3 (calculated from data by Osman, 2015)
  set water-inflow water-flow-major                                                                          ;; 3.52 m^3/s is the design discharge for Zananda Major Canal (REF: Osman, 2015)
  set offtake-proportion offtake-proportion-max                                                              ;; 0.13 is the design proportion, calculated from water flow data by Osman, 2015 between Major and Minor canal
  set central-maintenance-capacity capacity-central-maintenance                                              ;; % capacity of centralized maintenance
  set sediment-removal-full-capacity 96.57                                                                   ;; [m^3] max amount of sediments that can be removed from all minor canals in one time step (calculated from REF: Osman, 2015; Plusquellec, 1990)
  set adhoc-maintenance-capacity capacity-adhoc-maintenance                                                  ;; % capacity of adhoc maintenance
  set tenant-removal-full-capacity 581.14                                                                    ;; [m^3] max amount of sediments tenants can remove (calculated from REF: Osman, 2015; Goelnitz and Al-Saidi, 2020)
  set sediment-depth-threshold %-max-sediment-depth-for-adhoc-maintenance                                    ;; % of max sediment depth where adhoc maintenance begins
  set crit-shear-erosion critical-shear-erosion                                                              ;; 0.10 N/m^2 is typical (REF: Osman, 2015). Remains constant throughout the simulation (Winterwerp and Van Kesteren, 2004)
  set crit-shear-deposition critical-shear-deposition                                                        ;; 0.078 N/m^2 is typical for sediment concentrations between 300-10,000 ppm (REF: Krone, 1962)
  set rate-of-erosion erosion-rate                                                                           ;; 0.0016 kg/m^2/s is typical (REF: 0sman, 2015)
  set density-dry-sediment dry-sediment-density                                                              ;; 1200 kg/m^3 is typical (REF: Ali, 2014; Osman, 2015)
  set scale-factor 31000                                                                                     ;; scales the model world to match empirical data from Osman, 2015

  ;; Set up canal scheme
  setup-canals
  set canal-patches patches with [patch-type = "canal"]
  set major-canal-patches patches with [canal-type = "Major"]
  set minor-canal-patches patches with [canal-type = "Minor"]
  set drainage-patches patches with [landmark = "drainage"]
  set max-minor-depth (max-minor-volume / (count patches with [canal-name = "G/Elhosh"]) / cell-size)        ;; [m] Max depth of the minor canals (calculated from data by Osman, 2015)

  ;; Set up initial condition by placing sediment agents on the Major canal
  create-sediment-flow

  if (Maintenance-Scenario = "No maintenance") [
    set Maintain-G/Elhosh false
    set Maintain-Gimillia false
    set Maintain-Ballol false
    set Maintain-W/Elmahi false
    set Maintain-Toman false
    set Maintain-Gemoia false
    set Maintain-G/AbuGomri false
  ]

  if (Maintenance-Scenario = "Centralized") [ ;; This code counts the number of minor canals that are to be centrally maintained
    set n-minors-to-maintain 0
    if Maintain-G/Elhosh [ set n-minors-to-maintain n-minors-to-maintain + 1 ]
    if Maintain-Gimillia [ set n-minors-to-maintain n-minors-to-maintain + 1 ]
    if Maintain-Ballol [ set n-minors-to-maintain n-minors-to-maintain + 1 ]
    if Maintain-W/Elmahi [ set n-minors-to-maintain n-minors-to-maintain + 1 ]
    if Maintain-Toman [ set n-minors-to-maintain n-minors-to-maintain + 1 ]
    if Maintain-Gemoia [ set n-minors-to-maintain n-minors-to-maintain + 1 ]
    if Maintain-G/AbuGomri [ set n-minors-to-maintain n-minors-to-maintain + 1]
  ]

  ;; Set up results file
  setup-results-file
  output-print "day total-sediments-major[m^3]  G/Elhosh-minor-sediments[m^3]  Gimillia-minor-sediments[m^3]  Ballol-minor-sediments[m^3]  W/Elmahi-minor-sediments[m^3]  Toman-minor-sediments[m^3]  Gemoia-minor-sediments[m^3]  G/AbuGomri-minor-sediments[m^3]  avg-sediment-depth-major[m]  avg-sediment-depth-minor[m]  G/Elhosh-desilted-sediments[m^3]  Gimillia-desilted-sediments[m^3]  Ballol-desilted-sediments[m^3]  W/Elmahi-desilted-sediments[m^3]  Toman-desilted-sediments[m^3]  Gemoia-desilted-sediments[m^3]  G/AbuGomri-desilted-sediments[m^3]"
  reset-ticks
end

to go
  let julian-day ticks mod 365      ;; one tick is one day
  create-sediment-flow              ;; creating sediment flow at every tick simulates continous flow
  transport-sediments
  deposit-and-maintain-sediments
  output-results
  tick
  if ticks > round (length-of-run * 365) [ stop ]
end

to transport-sediments
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Simulate Sediment Transport ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  let julian-day ticks mod 365
  let year floor ( ticks / 365 )
  ask sediments
  [
    let P 5.51 * Q-scaled ^ 0.5                                           ;; REF: Matthews, 1952; Gismalla, 2009
    let R x-area-scaled / P
    let water-velocity Q-scaled / x-area-scaled
    let chezy water-velocity / ( bed-slope-scaled * R ) ^ 0.5             ;; REF: Mendez, 1998; Winterwerp et al., 2022
    let shear-velocity ( gravity ^ 0.5 * water-velocity / chezy )         ;; REF: Winterwerp et al., 2022
    let shear-stress shear-velocity ^ 2 * water-density                   ;; REF: Winterwerp et al., 2022

    set deposition-flux                                                   ;; REF: Krone, 1962
    ( settling-velocity * sediment-concentration  )
    let resusp-flux                                                       ;; REF: Partheniades, 1962
    ( (rate-of-erosion ) * ((shear-stress / (crit-shear-erosion )) - 1) )
    ifelse resusp-flux < 0 [
      set erosion-flux 0 ][
      set erosion-flux resusp-flux ] ;; if resuspension flux <= 0, there is no erosion of deposited sediments

    ;; Find neighboring canal patch with the lowest elevation
    let target min-one-of neighbors [elevation + (count sediments-here)]
    let target-canal-type [canal-type] of target
    let target-canal-name [canal-name] of target

    ;; If elevation in target canal patch is lower than the patch the sediment is currently on, then move to target patch
    if [elevation + (count sediments-here)] of target < (elevation + (count sediments-here)) and
    member? target canal-patches
    [
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; Movement of sediments within the same canal ;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if (target-canal-type = "Major" and canal-type = "Major")  [
        move-to target
        set Qs-scaled  ;; mass balance sediment budget [kg/s] (REF: Osman, 2015)
        ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled )
      ]

      ;; This code ensures that within the minor canals, there is no movement of sediments if it is already full of sediments
      if (target-canal-name = "G/Elhosh" and canal-name = "G/Elhosh") [
        ifelse G/Elhosh-minor-sediments <= max-minor-volume [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      if (target-canal-name = "Gimillia" and canal-name = "Gimillia") [
        ifelse Gimillia-minor-sediments <= max-minor-volume [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      if (target-canal-name = "Ballol" and canal-name = "Ballol") [
        ifelse Ballol-minor-sediments <= max-minor-volume [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      if (target-canal-name = "W/Elmahi" and canal-name = "W/Elmahi") [
        ifelse W/Elmahi-minor-sediments <= max-minor-volume [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      if (target-canal-name = "Toman" and canal-name = "Toman") [
        ifelse Toman-minor-sediments <= max-minor-volume [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      if (target-canal-name = "Gemoia" and canal-name = "Gemoia") [
        ifelse Gemoia-minor-sediments <= max-minor-volume [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      if (target-canal-name = "G/AbuGomri" and canal-name = "G/AbuGomri") [
        ifelse G/AbuGomri-minor-sediments <= max-minor-volume [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; Movement of sediments from Major to each Minor canal ;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; The amount of sediments flowing into the minors (represented by the offtake-proportion)
      ;; is dependent on how much sediments already exists in the minor canal
      if target-canal-name = "G/Elhosh" and canal-type = "Major" [
        let offtake-proportion-G/Elhosh ( (- offtake-proportion / max-minor-volume ) * G/Elhosh-minor-sediments + offtake-proportion )
        ifelse random 100 < offtake-proportion-G/Elhosh * 100 [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]

      if target-canal-name = "Gimillia" and canal-type = "Major" [
        let offtake-proportion-Gimillia ( (- offtake-proportion / max-minor-volume ) * Gimillia-minor-sediments + offtake-proportion )
        ifelse random 100 < offtake-proportion-Gimillia * 100 [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]
      if target-canal-name = "Ballol" and canal-type = "Major" [
        let offtake-proportion-Ballol ( (- offtake-proportion / max-minor-volume ) * Ballol-minor-sediments + offtake-proportion )
        ifelse random 100 < offtake-proportion-Ballol * 100 [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]
      if target-canal-name = "W/Elmahi" and canal-type = "Major" [
        let offtake-proportion-W/Elmahi ( (- offtake-proportion / max-minor-volume ) * W/Elmahi-minor-sediments + offtake-proportion )
        ifelse random 100 < offtake-proportion-W/Elmahi * 100 [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]
      if target-canal-name = "Toman" and canal-type = "Major" [
        let offtake-proportion-Toman ( (- offtake-proportion / max-minor-volume ) * Toman-minor-sediments + offtake-proportion )
        ifelse random 100 < offtake-proportion-Toman * 100 [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]
      if target-canal-name = "Gemoia" and canal-type = "Major" [
        let offtake-proportion-Gemoia ( (- offtake-proportion / max-minor-volume ) * Gemoia-minor-sediments + offtake-proportion )
        ifelse random 100 < offtake-proportion-Gemoia * 100 [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]
      if target-canal-name = "G/AbuGomri" and canal-type = "Major" [
        let offtake-proportion-G/AbuGomri ( (- offtake-proportion / max-minor-volume ) * G/AbuGomri-minor-sediments + offtake-proportion )
        ifelse random 100 < offtake-proportion-G/AbuGomri * 100 [
          move-to target
          set Qs-scaled
          ( Q-scaled * sediment-concentration - deposition-flux * x-area-scaled + erosion-flux * x-area-scaled ) ][]
      ]
    ]
  ]

  ask drainage-patches [
    ask sediments-here [ die ]
    set pcolor green - 3
  ]

  set n-sediments-major (count sediments-on major-canal-patches)
  set n-sediments-minor (count sediments-on minor-canal-patches)
  set n-sediments (count sediments)
end

to deposit-and-maintain-sediments
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Simulate Sediment Deposition & Accumulation ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  print "calculating total sediment deposition"
  let julian-day ticks mod 365
  let year floor ( ticks / 365 )

  ;; This code allows sediment agents to deposit sediments based on how much is already in each minor canal
  ask sediments-on G/Elhosh-minor-patches [
    set deposition-flux (- (max-deposition-flux / max-minor-volume) * G/Elhosh-minor-sediments + max-deposition-flux )
    if deposition-flux < 0 [ set deposition-flux 0 ]
    ifelse G/Elhosh-minor-sediments + count sediments-on G/Elhosh-minor-patches * (max-deposition-flux * x-area-scaled / density-dry-sediment) < max-minor-volume [
      set sediment-volume (
        sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s] (REF: Osman, 2015)
      ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
    ][]
    ;; This code simulates that during routine maintenance, the canal system is closed
    if Maintenance-Scenario = "Centralized" and year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-G/Elhosh [
      set sediment-volume sediment-volume + 0
      ask patch-here [ set sediment-depth sediment-depth + 0 ]
    ]
  ]
  ask sediments-on Gimillia-minor-patches [
    set deposition-flux (- (max-deposition-flux / max-minor-volume) * Gimillia-minor-sediments + max-deposition-flux )
    if deposition-flux < 0 [ set deposition-flux 0 ]
    ifelse Gimillia-minor-sediments + count sediments-on Gimillia-minor-patches * (max-deposition-flux * x-area-scaled / density-dry-sediment) < max-minor-volume [
      set sediment-volume (
        sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s]
      ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
    ][]
    ;; This code simulates that during routine maintenance, the canal system is closed
    if Maintenance-Scenario = "Centralized" and year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Gimillia [
      set sediment-volume sediment-volume + 0
      ask patch-here [ set sediment-depth sediment-depth + 0 ]
    ]
  ]
  ask sediments-on Ballol-minor-patches [
    set deposition-flux (- (max-deposition-flux / max-minor-volume) * Ballol-minor-sediments + max-deposition-flux )
    if deposition-flux < 0 [ set deposition-flux 0 ]
    ifelse Ballol-minor-sediments + count sediments-on Ballol-minor-patches * (max-deposition-flux * x-area-scaled / density-dry-sediment) < max-minor-volume [
      set sediment-volume (
        sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s]
      ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
    ][]
    ;; This code simulates that during routine maintenance, the canal system is closed
    if Maintenance-Scenario = "Centralized" and year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Ballol [
      set sediment-volume sediment-volume + 0
      ask patch-here [ set sediment-depth sediment-depth + 0 ]
    ]
  ]
  ask sediments-on W/Elmahi-minor-patches [
    set deposition-flux (- (max-deposition-flux / max-minor-volume) * W/Elmahi-minor-sediments + max-deposition-flux )
    if deposition-flux < 0 [ set deposition-flux 0 ]
    ifelse W/Elmahi-minor-sediments + count sediments-on W/Elmahi-minor-patches * (max-deposition-flux * x-area-scaled / density-dry-sediment) < max-minor-volume [
      set sediment-volume (
        sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s]
      ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
    ][]
    ;; This code simulates that during routine maintenance, the canal system is closed
    if Maintenance-Scenario = "Centralized" and year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-W/Elmahi [
      set sediment-volume sediment-volume + 0
      ask patch-here [ set sediment-depth sediment-depth + 0 ]
    ]
  ]
  ask sediments-on Toman-minor-patches [
    set deposition-flux (- (max-deposition-flux / max-minor-volume) * Toman-minor-sediments + max-deposition-flux )
    if deposition-flux < 0 [ set deposition-flux 0 ]
    ifelse Toman-minor-sediments + count sediments-on Toman-minor-patches * (max-deposition-flux * x-area-scaled / density-dry-sediment) < max-minor-volume [
      set sediment-volume (
        sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s]
      ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
    ][]
    ;; This code simulates that during routine maintenance, the canal system is closed
    if Maintenance-Scenario = "Centralized" and year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Toman [
      set sediment-volume sediment-volume + 0
      ask patch-here [ set sediment-depth sediment-depth + 0 ]
    ]
  ]
  ask sediments-on Gemoia-minor-patches [
    set deposition-flux (- (max-deposition-flux / max-minor-volume) * Gemoia-minor-sediments + max-deposition-flux )
    if deposition-flux < 0 [ set deposition-flux 0 ]
    ifelse Gemoia-minor-sediments + count sediments-on Gemoia-minor-patches * (max-deposition-flux * x-area-scaled / density-dry-sediment) < max-minor-volume [
      set sediment-volume (
        sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s]
      ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
    ][]
    ;; This code simulates that during routine maintenance, the canal system is closed
    if Maintenance-Scenario = "Centralized" and year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Gemoia [
      set sediment-volume sediment-volume + 0
      ask patch-here [ set sediment-depth sediment-depth + 0 ]
    ]
  ]
  ask sediments-on G/AbuGomri-minor-patches [
    set deposition-flux (- (max-deposition-flux / max-minor-volume) * G/AbuGomri-minor-sediments + max-deposition-flux )
    if deposition-flux < 0 [ set deposition-flux 0 ]
    ifelse G/AbuGomri-minor-sediments + count sediments-on G/AbuGomri-minor-patches * (max-deposition-flux * x-area-scaled / density-dry-sediment) < max-minor-volume [
      set sediment-volume (
        sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s]
      ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
    ][]
    ;; This code simulates that during routine maintenance, the canal system is closed
    if Maintenance-Scenario = "Centralized" and year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-G/AbuGomri [
      set sediment-volume sediment-volume + 0
      ask patch-here [ set sediment-depth sediment-depth + 0 ]
    ]
  ]

  ask sediments-on major-canal-patches [
    set sediment-volume (
      sediment-volume + (deposition-flux * x-area-scaled / density-dry-sediment) ) ;; [m^3/s]
    ask patch-here [ set sediment-depth (sediment-depth + [sediment-volume] of myself) / (cell-size ) ]  ;; [m]
  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Maintenance Scenarios ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Routine scenario is regular maintenance conducted every two years between
  ;; April through June when the canal is closed (REF: Osman, 2015)
  if (Maintenance-Scenario = "Centralized")
  [
    ifelse year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-G/Elhosh [ ask sediments-on G/Elhosh-minor-patches [routine-desilt-g/elhosh] ][ set G/Elhosh-desilted-sediments 0 ]
    ifelse year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Gimillia [ ask sediments-on Gimillia-minor-patches [routine-desilt-gimillia] ][ set Gimillia-desilted-sediments 0 ]
    ifelse year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Ballol [ ask sediments-on Ballol-minor-patches [routine-desilt-ballol] ][ set Ballol-desilted-sediments 0 ]
    ifelse year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-W/Elmahi [ ask sediments-on W/Elmahi-minor-patches [routine-desilt-w/elmahi] ][ set W/Elmahi-desilted-sediments 0 ]
    ifelse year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Toman [ ask sediments-on Toman-minor-patches [routine-desilt-toman] ][ set Toman-desilted-sediments 0 ]
    ifelse year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-Gemoia [ ask sediments-on Gemoia-minor-patches [routine-desilt-gemoia] ][ set Gemoia-desilted-sediments 0 ]
    ifelse year mod 2 = 1 and julian-day >= 90 and julian-day < 180 and Maintain-G/AbuGomri [ ask sediments-on G/AbuGomri-minor-patches [routine-desilt-g/abugomri] ][ set G/AbuGomri-desilted-sediments 0 ]
  ]

  ;; Ad hoc scenario is desilting when sediment-depth is noticed (sediment-depth-threshold)
  if (Maintenance-Scenario = "Ad hoc") [
    if Maintain-G/Elhosh [
      ask sediments-on G/Elhosh-minor-patches [
        if sediment-volume >= cell-size * max-minor-depth * sediment-depth-threshold [ adhoc-desilt-g/elhosh ]
      ]
    ]
    if Maintain-Gimillia [
      ask sediments-on Gimillia-minor-patches [
        if sediment-volume >= cell-size * max-minor-depth * sediment-depth-threshold [ adhoc-desilt-gimillia ]
      ]
    ]
    if Maintain-Ballol [
      ask sediments-on Ballol-minor-patches [
        if sediment-volume >= cell-size * max-minor-depth * sediment-depth-threshold [ adhoc-desilt-ballol ]
      ]
    ]
    if Maintain-W/Elmahi [
      ask sediments-on W/Elmahi-minor-patches [
        if sediment-volume >= cell-size * max-minor-depth * sediment-depth-threshold [ adhoc-desilt-w/elmahi ]
      ]
    ]
    if Maintain-Toman [
      ask sediments-on Toman-minor-patches [
        if sediment-volume >= cell-size * max-minor-depth * sediment-depth-threshold [ adhoc-desilt-toman ]
      ]
    ]
    if Maintain-Gemoia [
      ask sediments-on Gemoia-minor-patches [
        if sediment-volume >= cell-size * max-minor-depth * sediment-depth-threshold [ adhoc-desilt-gemoia ]
      ]
    ]
    if Maintain-G/AbuGomri [
      ask sediments-on G/AbuGomri-minor-patches [
        if sediment-volume >= cell-size * max-minor-depth * sediment-depth-threshold [ adhoc-desilt-g/abugomri ]
      ]
    ]
  ]

  set total-sediments-major ( (sum [sediment-depth] of major-canal-patches) * cell-size )

  set G/Elhosh-minor-sediments ( (sum [sediment-depth] of G/Elhosh-minor-patches) * cell-size )
  set Gimillia-minor-sediments ( (sum [sediment-depth] of Gimillia-minor-patches) * cell-size )
  set Ballol-minor-sediments ( (sum [sediment-depth] of Ballol-minor-patches) * cell-size )
  set W/Elmahi-minor-sediments ( (sum [sediment-depth] of W/Elmahi-minor-patches) * cell-size )
  set Toman-minor-sediments ( (sum [sediment-depth] of Toman-minor-patches) * cell-size )
  set Gemoia-minor-sediments ( (sum [sediment-depth] of Gemoia-minor-patches) * cell-size )
  set G/AbuGomri-minor-sediments ( (sum [sediment-depth] of G/AbuGomri-minor-patches) * cell-size )

  set total-sediments-minor ( G/Elhosh-minor-sediments + Gimillia-minor-sediments + Ballol-minor-sediments + W/Elmahi-minor-sediments + Toman-minor-sediments + Gemoia-minor-sediments + G/AbuGomri-minor-sediments )

  set avg-sediment-depth-major mean [sediment-depth] of major-canal-patches
  set avg-sediment-depth-minor mean [sediment-depth] of minor-canal-patches

  output-type ticks mod 365
  output-type "         "
  output-type total-sediments-major
  output-type "         "
  ;output-type total-sediments-minor
  ;output-type "         "
  output-type G/Elhosh-minor-sediments
  output-type "         "
  output-type Gimillia-minor-sediments
  output-type "         "
  output-type Ballol-minor-sediments
  output-type "         "
  output-type W/Elmahi-minor-sediments
  output-type "         "
  output-type Toman-minor-sediments
  output-type "         "
  output-type Gemoia-minor-sediments
  output-type "         "
  output-type G/AbuGomri-minor-sediments
  output-type "         "
  output-type avg-sediment-depth-major
  output-type "         "
  output-type avg-sediment-depth-minor
  output-type "         "
  output-type G/Elhosh-desilted-sediments
  output-type "         "
  output-type Gimillia-desilted-sediments
  output-type "         "
  output-type Ballol-desilted-sediments
  output-type "         "
  output-type W/Elmahi-desilted-sediments
  output-type "         "
  output-type Toman-desilted-sediments
  output-type "         "
  output-type Gemoia-desilted-sediments
  output-type "         "
  output-type G/AbuGomri-desilted-sediments
  output-type "         "

  print "  calculated total sediment deposition"


  ;; Visually show sedimentation on interface tab
  ask sediments [
    ask patch-here [
      let min-sediment min [sediment-depth] of canal-patches
      let max-sediment max [sediment-depth] of canal-patches
      set pcolor scale-color brown sediment-depth max-sediment min-sediment
      ask sediments-here [ set color scale-color brown sediment-volume max-sediment min-sediment ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
225
10
1040
477
-1
-1
3.79
1
10
1
1
1
0
0
0
1
-212
0
0
120
1
1
1
ticks
30.0

BUTTON
8
10
85
43
setup
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
93
10
167
43
go
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

CHOOSER
11
433
207
478
Maintenance-Scenario
Maintenance-Scenario
"No maintenance" "Centralized" "Ad hoc"
0

SLIDER
7
155
166
188
water-flow-major
water-flow-major
0
10
3.52
.01
1
m^3/s
HORIZONTAL

SLIDER
7
53
159
86
length-of-run
length-of-run
0
100
100.0
0.01
1
years
HORIZONTAL

SLIDER
7
116
165
149
ppm
ppm
0
10000
6000.0
1
1
ppm
HORIZONTAL

SLIDER
6
374
210
407
dry-sediment-density
dry-sediment-density
0
2000
1200.0
1
1
kg/m^3
HORIZONTAL

SLIDER
7
297
211
330
critical-shear-deposition
critical-shear-deposition
0
5
0.078
.01
1
N/m^2
HORIZONTAL

SLIDER
7
335
211
368
erosion-rate
erosion-rate
0
.1
0.0016
.0001
1
kg/m^2/s
HORIZONTAL

SLIDER
7
258
210
291
critical-shear-erosion
critical-shear-erosion
0
5
0.1
.01
1
N/m^2
HORIZONTAL

SLIDER
8
193
166
226
offtake-proportion-max
offtake-proportion-max
0
1
0.065
.01
1
NIL
HORIZONTAL

TEXTBOX
12
239
177
257
Parameters\n
12
0.0
1

TEXTBOX
13
95
176
113
Characteristics of Canals\n
12
0.0
1

PLOT
1049
11
1512
302
Sediment Accumulation
time (days)
Sediment Volume (m^3)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"G/Elhosh" 1.0 0 -16777216 true "" "plot G/Elhosh-minor-sediments"
"Gimillia" 1.0 0 -7500403 true "" "plot Gimillia-minor-sediments"
"Ballol" 1.0 0 -2674135 true "" "plot Ballol-minor-sediments"
"W/Elmahi" 1.0 0 -955883 true "" "plot W/Elmahi-minor-sediments"
"Toman" 1.0 0 -6459832 true "" "plot Toman-minor-sediments"
"Gemoia" 1.0 0 -1184463 true "" "plot Gemoia-minor-sediments"
"G/AbuGomri" 1.0 0 -10899396 true "" "plot G/AbuGomri-minor-sediments"

TEXTBOX
635
23
680
41
G/Elhosh
11
9.9
1

TEXTBOX
432
23
496
41
G/Abu Gomri 
11
9.9
1

TEXTBOX
402
431
441
449
Gemoia
11
9.9
1

TEXTBOX
458
448
498
466
Toman\n
11
9.9
1

TEXTBOX
520
431
569
449
W/Elmahi
11
9.9
1

TEXTBOX
585
450
628
468
Ballol\n
11
9.9
1

TEXTBOX
642
450
678
468
Gimillia\n
11
9.9
1

TEXTBOX
793
265
943
283
Zananda Major Canal
11
9.9
1

TEXTBOX
938
227
1010
258
Source of flow (K57)
11
9.9
1

TEXTBOX
237
232
300
260
Downstream (K16.7)
11
9.9
1

PLOT
1518
11
1979
302
Sediment Accumulation (Major Canal)
time (days)
Sediment volume (m^3)
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"sediments in major canal" 1.0 0 -16777216 true "" "plot total-sediments-major"

SWITCH
868
482
1040
515
show-elevation-gradient
show-elevation-gradient
1
1
-1000

TEXTBOX
645
238
700
256
K7.4
11
9.9
1

TEXTBOX
572
237
626
255
K9.1
11
9.9
1

TEXTBOX
450
237
529
255
K12.5
11
9.9
1

SLIDER
11
482
207
515
capacity-central-maintenance
capacity-central-maintenance
0
1
0.0
.01
1
NIL
HORIZONTAL

TEXTBOX
13
414
163
432
Maintenance Parameters
13
0.0
1

SWITCH
12
520
153
553
Maintain-G/Elhosh
Maintain-G/Elhosh
1
1
-1000

SWITCH
12
557
154
590
Maintain-Gimillia
Maintain-Gimillia
1
1
-1000

SWITCH
159
520
293
553
Maintain-Ballol
Maintain-Ballol
1
1
-1000

SWITCH
157
557
294
590
Maintain-W/Elmahi
Maintain-W/Elmahi
1
1
-1000

SWITCH
299
520
426
553
Maintain-Toman
Maintain-Toman
1
1
-1000

SWITCH
299
557
427
590
Maintain-Gemoia
Maintain-Gemoia
1
1
-1000

SWITCH
432
520
580
553
Maintain-G/AbuGomri
Maintain-G/AbuGomri
1
1
-1000

SLIDER
401
482
677
515
%-max-sediment-depth-for-adhoc-maintenance
%-max-sediment-depth-for-adhoc-maintenance
0
1
0.7
.01
1
NIL
HORIZONTAL

PLOT
1049
309
1513
595
Sediment Desilted
time (days)
Sediments Removed (m^3)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"G/Elhosh" 1.0 0 -16777216 true "" "plot G/Elhosh-desilted-sediments"
"Gimillia" 1.0 0 -7500403 true "" "plot Gimillia-desilted-sediments"
"Ballol" 1.0 0 -2674135 true "" "plot Ballol-desilted-sediments"
"W/Elmahi" 1.0 0 -955883 true "" "plot W/Elmahi-desilted-sediments"
"Toman" 1.0 0 -6459832 true "" "plot Toman-desilted-sediments"
"Gemoia" 1.0 0 -1184463 true "" "plot Gemoia-desilted-sediments"
"G/AbuGomri" 1.0 0 -10899396 true "" "plot G/AbuGomri-desilted-sediments"

SLIDER
210
482
396
515
capacity-adhoc-maintenance
capacity-adhoc-maintenance
0
1
0.8
.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?


## HOW IT WORKS



## HOW TO USE IT



## THINGS TO NOTICE



## THINGS TO TRY



## EXTENDING THE MODEL



## NETLOGO FEATURES

The model makes use of `dx` and `dy` to help replicate vector addition while still using the turtles' own "heading" property. This allows for modification of a turtle's motion with both NetLogo heading-related commands as well as with vector addition.
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Vary ppm" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="3000"/>
      <value value="4000"/>
      <value value="5000"/>
      <value value="6000"/>
      <value value="7000"/>
      <value value="8000"/>
      <value value="9000"/>
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Centralized&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vary central capacity" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Centralized&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vary adhoc capacity" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Ad hoc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="vary ppm and water inflow" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="3000"/>
      <value value="4000"/>
      <value value="5000"/>
      <value value="6000"/>
      <value value="7000"/>
      <value value="8000"/>
      <value value="9000"/>
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;No maintenance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="1.5"/>
      <value value="2"/>
      <value value="2.5"/>
      <value value="3"/>
      <value value="3.5"/>
      <value value="4"/>
      <value value="4.5"/>
      <value value="5"/>
      <value value="5.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vary Adhoc Capacity and Trigger" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Ad hoc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SIM-1 Ideal" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>n-sediments-major</metric>
    <metric>n-sediments-minor</metric>
    <metric>n-sediments</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Centralized&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SIM-5 Major Disruption, Offtake 6.5, Centralized" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Centralized&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.065"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SIM-3 Increased ppm, Centralized" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>n-sediments-major</metric>
    <metric>n-sediments-minor</metric>
    <metric>n-sediments</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Centralized&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SIM-4 Increased ppm, Adhoc (0.7threshold, 0.8capacity)" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>n-sediments-major</metric>
    <metric>n-sediments-minor</metric>
    <metric>n-sediments</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Ad hoc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SIM-6 Major Disruption, Offtake 6.5, Ad hoc (0.7threshold, 0.8capacity)" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>n-sediments-major</metric>
    <metric>n-sediments-minor</metric>
    <metric>n-sediments</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;Ad hoc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.065"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Maintenance" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>n-sediments-major</metric>
    <metric>n-sediments-minor</metric>
    <metric>n-sediments</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;No maintenance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SIM3-4 No Maintenance" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>n-sediments-major</metric>
    <metric>n-sediments-minor</metric>
    <metric>n-sediments</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;No maintenance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SIM5-6 No Maintenance" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sediments-major</metric>
    <metric>n-sediments-major</metric>
    <metric>n-sediments-minor</metric>
    <metric>n-sediments</metric>
    <metric>total-sediments-minor</metric>
    <metric>G/Elhosh-minor-sediments</metric>
    <metric>Gimillia-minor-sediments</metric>
    <metric>Ballol-minor-sediments</metric>
    <metric>W/Elmahi-minor-sediments</metric>
    <metric>Toman-minor-sediments</metric>
    <metric>Gemoia-minor-sediments</metric>
    <metric>G/AbuGomri-minor-sediments</metric>
    <metric>G/Elhosh-desilted-sediments</metric>
    <metric>Gimillia-desilted-sediments</metric>
    <metric>Ballol-desilted-sediments</metric>
    <metric>W/Elmahi-desilted-sediments</metric>
    <metric>Toman-desilted-sediments</metric>
    <metric>Gemoia-desilted-sediments</metric>
    <metric>G/AbuGomri-desilted-sediments</metric>
    <enumeratedValueSet variable="capacity-adhoc-maintenance">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-elevation-gradient">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ppm">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capacity-central-maintenance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-max-sediment-depth-for-adhoc-maintenance">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Ballol">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-W/Elmahi">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/Elhosh">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gemoia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-deposition">
      <value value="0.078"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="erosion-rate">
      <value value="0.0016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-G/AbuGomri">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintenance-Scenario">
      <value value="&quot;No maintenance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offtake-proportion-max">
      <value value="0.065"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry-sediment-density">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="critical-shear-erosion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-run">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-flow-major">
      <value value="3.52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Gimillia">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maintain-Toman">
      <value value="false"/>
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
