  global ScenarioWindows
  set n [Unique]
  set win .scenario$n
  set ScenarioWindows [linsert $ScenarioWindows 0 $win]

  LinkWindow $head.scenario $win
  LinkWindow $win.head $head

  global CityName GameLevel
  if {![info exists CityName] || [string trim "$CityName"] == "" || "$CityName" == "NowHere"} {
    set CityName "New City"
  }
  if {![info exists GameLevel] || $GameLevel == -1} {
    set GameLevel 0
  }

  catch "destroy $win"
  toplevel $win -screen $display -borderwidth 2 -relief raised

  SetHelp $win Window

  wm title $win {Welcome to SimCity}
  wm iconname $win {SimCity}
  wm geometry $win +440+5
  wm withdraw $win
  wm maxsize $win 2000 2000
  wm minsize $win 400 1
  # closing the welcome screen quits the game (it is the start screen)
  wm protocol $win delete "sim ReallyQuit"

  # ---- the (enlarged) SimCity logo ----
  frame $win.top\
    -borderwidth 8 -relief flat
  label $win.top.simcity\
    -bitmap "@images/simcitybig.xpm"
  pack append $win.top\
    $win.top.simcity	{top frame center}

  # ---- about / credits (original + our 2026 contribution) ----
  message $win.about\
    -aspect 900 -justify center\
    -font [Font $win Small]\
    -text {Micropolis (SimCity) version 4.0
Designed by Will Wright - Maxis, 1989
X11 Multi-Player port by Don Hopkins
(C) 1989-2002 Electronic Arts / Maxis - GPL Micropolis
A/UX X11R6 revival by @SiliconForested - C89 Summer 2026}

  # ---- actions (difficulty lives on the New City dialog) ----
  frame $win.actions\
    -borderwidth 8 -relief flat
  button $win.actions.new\
    -text {Start New City}\
    -font [Font $win Large] -relief raised -borderwidth 2\
    -command "UINewCityDialog $head"
  button $win.actions.load\
    -text {Load City...}\
    -font [Font $win Large] -relief raised -borderwidth 2\
    -command "UILoadCity $head"
  pack append $win.actions\
    $win.actions.new	{left frame center expand fillx}\
    $win.actions.load	{left frame center expand fillx}

  pack append $win\
    $win.top		{top frame center fillx}\
    $win.about		{top frame center fillx}\
    $win.actions	{top frame center fillx}

  InitScenario $win

  update idletasks
  return $win
