########################################################################
# SimCity.tcl, by Don Hopkins.
# Copyright (C) 1993 by DUX Software Corporation.
# This file defines the user interface of SimCity. 
# Modify at your own risk!
########################################################################


########################################################################
# Libraries
########################################################################


set errorInfo {}
set auto_noexec 1

source $tk_library/wish.tcl


########################################################################
# Globals
########################################################################


set UniqueID 0
set State uninitialized
set CityName "SimCity"
set GameLevel 0
set SimHome [pwd]
set CityLibDir $SimHome/cities
set CityDir $CityLibDir
set OldBudget 0
set BudgetRoadFund 0
set BudgetFireFund 0
set BudgetPoliceFund 0
set BudgetTaxRate 0
set Priority 6
set Time 3
set AutoGoto 1
set AutoBudget 1
set Disasters 1
set AutoBulldoze 1
set Sound 1
set DoAnimation 1
set ShapePies 1
set SoundServers {}
set AudioChannels {mode edit fancy warning intercom}
set KindOfLicense 0
set BudgetTimeout 30
set BudgetTimer 0
set BudgetTimerActive 0
set Scenario -1
set HomeDir ""
set ResourceDir ""
set KeyDir ""
set HostName ""
set SaveCityWin ""
set MapHistory {}
set MapHistoryNum -1
set QueryX 0
set QueryY 0
set FreeVotes 0
set ShowingPicture 300
set ShowingParms {}
set VoteNames {UseThisMap Ask Zone}
set VotesForUseThisMap {}
set VotesForAsk {}
set VotesForZone {}
set VotesForBudget {}


set HeadWindows {}
set EditorWindows {}
set MapWindows {}
set GraphWindows {}
set BudgetWindows {}
set EvaluationWindows {}
set ScenarioWindows {}
set FileWindows {}
set ConfigWindows {}
set KeyWindows {}
set AskWindows {}
set PlayerWindows {}
set NoticeWindows {}


set SubWindows {
  {editor EditorWindows}
  {map MapWindows}
  {graph GraphWindows}
  {budget BudgetWindows}
  {evaluation EvaluationWindows}
  {scenario ScenarioWindows}
  {file FileWindows}
  {config ConfigWindows}
  {key KeyWindows}
  {ask AskWindows}
  {player PlayerWindows}
  {notice NoticeWindows}
  {head HeadWindows}
}


set FontInfo {
  {Big {
	{-Adobe-Helvetica-Bold-R-Normal-*-140-100-100-*}
	{-Adobe-Helvetica-Bold-R-Normal-*-180-75-75-*}
  }}
  {Large {
	{-Adobe-Helvetica-Bold-R-Normal-*-100-100-100-*}
	{-Adobe-Helvetica-Bold-R-Normal-*-140-75-75-*}
  }}
  {Medium {
	{-Adobe-Helvetica-Bold-R-Normal-*-90-100-100-*}
	{-Adobe-Helvetica-Bold-R-Normal-*-120-75-75-*}
  }}
  {Small {
	{-Adobe-Helvetica-Bold-R-Normal-*-80-100-100-*}
	{-Adobe-Helvetica-Bold-R-Normal-*-100-75-75-*}
  }}
  {Narrow {
	{-Adobe-Helvetica-Medium-R-Normal-*-80-100-100-*}
	{-Adobe-Helvetica-Medium-R-Normal-*-100-75-75-*}
  }}
  {Tiny {
	{-Adobe-Helvetica-Bold-R-Normal-*-80-100-100-*}
	{-Adobe-Helvetica-Bold-R-Normal-*-80-75-75-*}
  }}
  {Text {
	{-Adobe-Helvetica-Medium-R-Normal-*-100-100-100-*}
	{-Adobe-Helvetica-Medium-R-Normal-*-140-75-75-*}
  }}
  {Message {
	{-Adobe-Helvetica-Bold-R-Normal-*-100-100-100-*}
	{-Adobe-Helvetica-Bold-R-Normal-*-140-75-75-*}
  }}
  {Alert {
	{-Adobe-Helvetica-Bold-O-Normal-*-100-100-100-*}
	{-Adobe-Helvetica-Bold-O-Normal-*-140-75-75-*}
  }}
}


set MapTitles {
  {SimCity Overall Map}
  {Residential Zone Map}
  {Commercial Zone Map}
  {Industrial Zone Map}
  {Power Grid Map}
  {Transportation Map}
  {Population Density Map}
  {Rate of Growth Map}
  {Traffic Density Map}
  {Pollution Desity Map}
  {Crime Rate Map}
  {Land Value Map}
  {Fire Coverage Map}
  {Police Coverage Map}
}


set EditorPallets {
  leftframe.tools.r0.palletres
  leftframe.tools.r0.palletcom
  leftframe.tools.r1.palletind
  leftframe.tools.r2.palletfire
  leftframe.tools.r2.palletquery
  leftframe.tools.r1.palletpolice
  leftframe.tools.r4.palletwire
  leftframe.tools.r7.palletbulldozer
  leftframe.tools.r3.palletrail
  leftframe.tools.r3.palletroad
  leftframe.tools.r8.palletchalk
  leftframe.tools.r8.palleteraser
  leftframe.tools.r6.palletstadium
  leftframe.tools.r5.palletpark
  leftframe.tools.r6.palletseaport
  leftframe.tools.r4.palletcoal
  leftframe.tools.r5.palletnuclear
  leftframe.tools.r7.palletairport
}


set EditorPalletImages { 
  res com ind fire qry pol
  wire dozr rail road chlk ersr
  stad park seap coal nuc airp
}


set EditorPalletSounds { 
  Res Com Ind Fire Query Police
  Wire Bulldozer Rail Road Chalk Eraser
  Stadium Park Seaport Coal Nuclear Airport
}


set GraphPallets {
  leftframe.left.res
  leftframe.left.com
  leftframe.left.ind
  leftframe.right.money
  leftframe.right.crime
  leftframe.right.pollution
}


set GraphPalletImages { 
  res com ind mony crim poll
}


set GraphYearPallets {
  leftframe.year.year10
  leftframe.year.year120
}


set GraphYearPalletImages { 10 120 }


set ToolInfo {
  {     {a}	{Residential Zone}	{$100}}
  {     {a}	{Commercial Zone}	{$100}}
  {     {an}	{Industrial Zone}	{$100}}
  {     {a}	{Fire Station}		{$500}}
  {     {a}	{Query}			{free}}
  {     {a}	{Police Station}	{$500}}
  {     {a}	{Wire}			{$5}}
  {     {a}	{Bulldozer}		{$1}}
  {     {a}	{Rail}			{$20}}
  {     {a}	{Road}			{$10}}
  {     {a}	{Chalk}			{free}}
  {     {an}	{Eraser}		{free}}
  {     {a}	{Stadium}		{$5,000}}
  {     {a}	{Park}			{$20}}
  {     {a}	{Seaport}		{$3,000}}
  {     {a}	{Coal Power Plant}	{$3,000}}
  {     {a}	{Nuclear Power Plant}	{$5,000}}
  {     {an}	{Airport}		{$10,000}}
  {     {a}	{Network}		{$1,000}}
}


########################################################################
# Initialization
########################################################################


wm title . {SimCity Root}


if {"[sim Platform]" == "msdos"} {
  sim DoAnimation 0
  set DoAnimation 0
  set ShapePies 0
} else {
  sim DoAnimation 1
  set DoAnimation 1
  set ShapePies 1
}


########################################################################
# Messages
########################################################################


proc Message {id color title msg {props {}}} {
  global Messages
  set Messages($id) [list $color $title $msg $props]
}


Message 1 #7f7fff {DULLSVILLE, USA  1900} \
{Things haven't changed much around here in the last hundred years or so and the residents are beginning to get bored.  They think Dullsville could be the next great city with the right leader. 

It is your job to attract new growth and development, turning Dullsville into a Metropolis within 30 years.}

Message 2 #7f7fff {SAN FRANCISCO, CA.  1906} \
{Damage from the earthquake was minor compared to that of the ensuing fires, which took days to control.  1500 people died.

Controlling the fires should be your initial concern.  Then clear the rubble and start rebuilding.  You have 5 years.}
	
Message 3 #7f7fff {HAMBURG, GERMANY  1944} \
{Allied fire-bombing of German cities in WWII caused tremendous damage and loss of life.  People living in the inner cities were at greatest risk.

You must control the firestorms during the bombing and then rebuild the city after the war.  You have 5 years.}

Message 4 #7f7fff {BERN, SWITZERLAND  1965} \
{The roads here are becoming more congested every day, and the residents are upset.  They demand that you do something about it.

Some have suggested a mass transit system as the answer, but this would require major rezoning in the downtown area.  You have 10 years.}

Message 5 #7f7fff {TOKYO, JAPAN  1957} \
{A large reptilian creature has been spotted heading for Tokyo bay.  It seems to be attracted to the heavy levels of industrial pollution there.

Try to control the fires, then rebuild the industrial center.  You have 5 years.}

Message 6 #7f7fff {DETROIT, MI.  1972} \
{By 1970, competition from overseas and other economic factors pushed the once "automobile capital of the world" into recession.  Plummeting land values and unemployment then increased crime in the inner-city to chronic levels.

You have 10 years to reduce crime and rebuild the industrial base of the city.}

Message 7 #7f7fff {BOSTON, MA.  2010} \
{A major meltdown is about to occur at one of the new downtown nuclear reactors.  The area in the vicinity of the reactor will be severly contaminated by radiation, forcing you to restructure the city around it.

You have 5 years to get the situation under control.}

Message 8 #7f7fff {RIO DE JANEIRO, BRAZIL  2047} \
{In the mid-21st century, the greenhouse effect raised global temperatures 6 degrees F.  Polar icecaps melted and raised sea levels worldwide.  Coastal areas were devastated by flood and erosion.

You have 10 years to turn this swamp back into a city again.}

Message 9 #ffa500 {Query Zone Status} \
{
Zone:	    %s
Density:    %s
Value:	    %s
Crime:	    %s
Pollution:  %s
Growth:	    %s} \
{{view {PanView $v $QueryX $QueryY}}}

Message 10 #ff4f4f {POLLUTION ALERT!} \
{Pollution in your city has exceeded the maximum allowable amounts established by the SimCity Pollution Agency.  You are running the risk of grave ecological consequences.

Either clean up your act or open a gas mask concession at city hall.} \
{{view {PanView $v [sim PolMaxX] [sim PolMaxY]}}}

Message 11 #ff4f4f {CRIME ALERT!} \
{Crime in your city is our of hand.  Angry mobs are looting and vandalizing the central city.  The president will send in the national guard soon if you cannot control the problem.} \
{{view {PanView $v [sim CrimeMaxX] [sim CrimeMaxY]}}}

Message 12 #ff4f4f {TRAFFIC WARNING!} \
{Traffic in this city is horrible.  The city gridlock is expanding.  The commuters are getting militant.

Either build more roads and rails or get a bulletproof limo.} \
{{view {PanView $v [sim TrafMaxX] [sim TrafMaxY]}}}

Message 21 #ff4f4f {MONSTER ATTACK!} \
"A large reptilian creature has been spotted in the water.  It seems to be attracted to areas of high pollution.  There is a trail of destruction wherever it goes.  \
All you can do is wait till he leaves, then rebuild from the rubble." \
{{view {FollowView $v 5}}}

# XXX: write more text
Message 22 #ff4f4f {TORNADO ALERT!} \
{A tornado has been reported!  There's nothing you can do to stop it, so you'd better prepare to clean up after the disaster!} \
{{view {FollowView $v 6}}}

# XXX: write more text
Message 23 #ff4f4f {EARTHQUAKE!} \
{A major earthquake has occurred!  Put out the fires as quickly as possible, before they spread, then reconnect the power grid and rebuild the city.} \
{{view {PanView $v [sim CenterX] [sim CenterY]}}}

# XXX: write more text
Message 24 #ff4f4f {PLANE CRASH!} \
{A plane has crashed!} \
{{view {PanView $v [sim CrashX] [sim CrashY]}}}

Message 25 #7f7fff {Start a New City} \
{Build your very own city from the ground up, starting with this map of uninhabited land.}

Message 26 #7f7fff {Restore a Saved City} \
{This city was saved in the file named: %s}

Message 35 #7fff7f {TOWN} \
{Congratulations, your village has grown to town status.  You now have 2,000 citizens.} \
{{view {PanView $v [sim CenterX] [sim CenterY]}}}

Message 36 #7fff7f {CITY} \
{Your town has grown into a full sized city, with a current population of 10,000.  Keep up the good work!} \
{{view {PanView $v [sim CenterX] [sim CenterY]}}}

Message 37 #7fff7f {CAPITAL} \
{Your city has become a capital.  The current population here is 50,000.  Your political future looks bright.} \
{{view {PanView $v [sim CenterX] [sim CenterY]}}}

Message 38 #7fff7f {METROPOLIS} \
{Your capital city has now achieved the status of metropolis.  The current population is 100,000.  With your management skills, you should seriously consider running for governor.} \
{{view {PanView $v [sim CenterX] [sim CenterY]}}}

Message 39 #7fff7f {MEGALOPOLIS} \
{Congratulation, you have reached the highest category of urban development, the megalopolis.

If you manage to reach this level, give us a call at Maxis or send us a copy of your city.  We might do something interesting with it.} \
{{view {PanView $v [sim CenterX] [sim CenterY]}}}

Message 43 #ff4f4f {NUCLEAR MELTDOWN!} \
{A nuclear meltdown has occured at your power plant.  You are advised to avoid the area until the radioactive isotopes decay.

Many generations will confront this problem before it goes away, so don't hold your breath.} \
{{view {PanView $v [sim MeltX] [sim MeltY]}}}


# XXX: write more text
Message 41 #ff4f4f {HEAVY TRAFFIC!} \
{Sky Watch One
reporting heavy traffic!} \
{{view {FollowView $v 2}}}

# XXX: write more text
Message 42 #ff4f4f {FLOODING REPORTED!} \
{Flooding has been been reported along the water's edge!} \
{{view {PanView $v [sim FloodX] [sim FloodY]}}}

Message 44 #ff4f4f {RIOTS!} \
{The citizens are rioting in the streets, setting cars and houses on fire, and bombing government buildings and businesses!

All media coverage is blacked out, while the fascist pigs beat the poor citizens into submission.}

Message 45 #ff4f4f {END OF DEMO!} \
{This computer does not have a license to play SimCity!  Please call DUX Software and get a key, to keep your city from melting all the time! The phone numbers are:

Voice: +1 (800) 543-4999, +1 (415) 967-1500
Fax: +1 (415) 967-5528, EMail: simcity@dux.com}

Message 46 #ff4f4f {NO SOUND SERVER!} \
{There is no sound server running on your X11 display "%s".  You won't hear any noise unless you run a sound server, and turn the sound back on in the "Options" menu.}

Message 47 #ff4f4f {NO MULTI PLAYER LICENSE!} \
{This computer does not have a license for Multi Player SimCity!  Please call DUX Software and get a key, so several people can play on different X11 displays!  The phone numbers are:

Voice: +1 (800) 543-4999, +1 (415) 967-1500
Fax: +1 (415) 967-5528, EMail: simcity@dux.com}

Message 100 #7fff7f {YOU'RE A WINNER!} \
{Your mayorial skill and city planning expertise have earned you the KEY TO THE CITY.  Local residents will erect monuments to your glory and name their first-born children after you.  Why not run for governor?} \
{{middle {@images/key2city.xpm}}}

Message 200 #ff4f4f {IMPEACHMENT NOTICE!} \
{The entire population of this city has finally had enough of your inept planning and incompetant management.  An angry mob -- led by your mother -- has been spotted in the vicinity of city hall.

You should seriously consider taking an extended vacation -- NOW.  (Or read the manual and try again.)}

Message 300 #ffd700 {About SimCity} \
"X11 SimCity for Unix Copyright (C) 1993
    by DUX Software Corporation.
Multi-Player Interface Designed and Created
    by Don Hopkins, DUX Software.
Based on the Original SimCity Concept and Design
    by Will Wright, MAXIS Software.
Implemented using the TCL/Tk Toolkit!
\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
Hey!  What are you doing here? 
\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
Scroll that window back!
\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
What did you expect to find down here anyway,
a rotten easter egg?  This is family software!" \
{{left {@images/maxis.xpm}}
 {middle {@images/simcityl.xpm}}
 {right {@images/duck.xpm}}}


########################################################################
# Help Messages
########################################################################


Message Window #7f7fff {SimCity Window} \
{This is one of SimCity's windows.
Press Help or Meta-Click on the other controls and graphics for more information about them.
[This is the only help message implemented yet -- more to come in a later version!  Sorry!]}


# Help messages to do:
# SimCityMenu
# SelectCity.KeepPlaying
# SelectCity.Yes
# Quit.KeepPlaying
# Quit.IQuit
# Quit.IResign
# Quit.AllQuit
# Plan.Dismiss


########################################################################
# Options
########################################################################


option add *CheckButton.relief		flat
option add *Dialog.cursor		top_left_arrow
option add *Entry.relief		sunken
option add *Frame.borderWidth		0
option add *Listbox.relief		sunken
option add *Scrollbar.relief		sunken
option add *RadioButton.anchor		w
option add *RadioButton.relief		flat

option add *background			#b0b0b0
option add *foreground			#000000
option add *activeBackground		#d0d0d0
option add *activeForeground		#000000
option add *disabledForeground		""
option add *selectBackground		#d0d0d0
option add *selectForeground		#000000
#option add *selector			#ffff80
option add *selector			#bf0000

option add *Scrollbar.Background 	#b0b0b0
option add *Scrollbar.Foreground	#d0d0d0
option add *Scale.activeForeground	#d0d0d0
option add *Scale.sliderForeground	#b0b0b0
option add *PieMenu.activeBackground	#b0b0b0


########################################################################
# Global Bindings
########################################################################


bind all <Meta-ButtonPress> {HandleHelp %W %x %y %X %Y}
bind all <Help> {HandleHelp %W %x %y %X %Y}


########################################################################
# Utilities
########################################################################


proc echo {args} {
  puts stdout $args
  flush stdout
} 


proc Unique {} {
  global UniqueID
  set id $UniqueID
  incr UniqueID
  return $id
}


proc tkerror {err} {
    global errorInfo
    puts stderr "$errorInfo"
}


proc ident {i} {
  return "$i"
}

proc NoFunction {args} {}


proc LinkWindow {fromname to} {
  global WindowLinks
  set WindowLinks($fromname) $to
}


proc WindowLink {fromname} {
  global WindowLinks
  set to ""
  catch {set to $WindowLinks($fromname)}
  return $to
}


proc DeleteWindow {sym name win} {
  set head [WindowLink $win.head]
  LinkWindow $head.$sym {}
  global $name
  set wins [eval ident "\$$name"]
  set i [lsearch $wins $win]
  if {$i != -1} {
    set $name [lreplace $wins $i $i]
  }
  destroy $win
}


proc Font {win name} {
  global FontInfo FontCache HeadWindows
  set scr [winfo screen $win]
  set font ""
  catch {
    set font $FontCache($scr,$name)
  }
  if {"$font" == ""} {
    set label ""
    catch {
      set label $FontCache($scr)
    }
    if {"$label" == ""} {
      foreach head $HeadWindows {
	if {"[winfo screen $head]" == "$scr"} {
	  set label $head.fontlabel
	  label $label
	  set FontCache($scr) $label
	}
      }
    }

    set fonts [keylget FontInfo $name]
    foreach font $fonts {
      if {[catch "$label config -font $font"] == 0} {
	break
      }
    }
    if {"$font" == ""} {
      set font screen16
    }
    set FontCache($scr,$name) $font
  }
  return $font
}


proc Color {win color mono} {
  if {[winfo screendepth $win] == 1} {
    return $mono
  } else {
    return $color
  }
}


########################################################################
# Window Definition Functions
########################################################################


proc MakeWindow.head {{display ":0"}} {
  global ResourceDir
  source $ResourceDir/whead.tcl
  return $win
}


proc MakeWindow.editor {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/weditor.tcl
  return $win
}


proc MakeWindow.map {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wmap.tcl
  return $win
}


proc MakeWindow.graph {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wgraph.tcl
  return $win
}


proc MakeWindow.budget {head {display ":0"}} {
  global ResourceDir
  source $ResourceDir/wbudget.tcl
  return $win
}


proc MakeWindow.evaluation {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/weval.tcl
  return $win
}


proc MakeWindow.scenario {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wscen.tcl
  return $win
}


proc MakeWindow.file {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wfile.tcl
  return $win
}


proc MakeWindow.config {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wconfig.tcl
  return $win
}


proc MakeWindow.key {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wkey.tcl
  return $win
}


proc MakeWindow.ask {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wask.tcl
  return $win
}


proc MakeWindow.player {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wplayer.tcl
  return $win
}


proc MakeWindow.notice {head {display "unix:0"}} {
  global ResourceDir
  source $ResourceDir/wnotice.tcl
  return $win
}


########################################################################
# Sound Support
########################################################################


proc UIInitializeSound {} {
}


proc UIShutDownSound {} {
}


proc UIDoSoundOn {win cmd} {
  global Sound SoundServers
  if {$Sound} {
    set win [WindowLink [winfo toplevel $win].head]
    if {[lsearch $SoundServers $win] != -1} {
      set cmd "send -quick -server $win Sound sound $cmd"
      if {[catch $cmd]} {
	# XXX: Lost a sound server...
	LostSoundServer $win
      }
    }
  }
}


proc UIDoSound {cmd} {
  global Sound SoundServers
  if {$Sound} {
    foreach win $SoundServers {
      set foo "send -quick -server $win Sound $cmd"
      if {[catch $foo]} {
	# XXX: Lost a sound server...
        LostSoundServer $win
      }
    }
  }
}


proc KillSoundServers {} {
  global SoundServers
  foreach win $SoundServers {
    set foo "send -quick -server $win Sound KillSoundServer"
    catch $foo
  }
  set SoundServers {}
}


proc UISetChannelVolume {win chan vol} {
  UIDoSoundOn $win "channel $chan -volume $vol"
}


proc UIMakeSoundOn {win chan sound {opts ""}} {
  UIDoSoundOn $win "play $sound -replay -channel $chan $opts"
}


proc UIStartSoundOn {win chan sound {opts ""}} {
  UIDoSoundOn $win "play $sound -replay -channel $chan -repeat 100 $opts"
}


proc UIStopSoundOn {win chan sound {opts ""}} {
  UIDoSoundOn $win "stop $sound"
}


proc UIMakeSound {chan sound {opts ""}} {
  UIDoSound "sound play $sound -replay -channel $chan $opts"
}


proc UIStartSound {chan sound {opts ""}} {
  UIDoSound "sound play $sound -channel $chan -repeat 100 $opts"
}


proc UIStopSound {chan sound {opts ""}} {
  UIDoSound "sound stop $sound"
}


proc SetupSoundServer {win} {
  AddSoundServer $win
}


proc AddSoundServer {win} {
  global SoundServers
  set i [lsearch $SoundServers $win]
  if {$i < 0} {
    set SoundServers [linsert $SoundServers 0 $win]
  }
}


proc LostSoundServer {win} {
  DeleteSoundServer $win
#  UIShowPictureOn [WindowLink $win.head] 46 [winfo server $win]
}


proc DeleteSoundServer {win} {
  global SoundServers
  set i [lsearch $SoundServers $win]
  if {$i >= 0} {
    set SoundServers [lreplace $SoundServers $i $i]
  }
}


proc UISoundOff {} {
}


proc MonsterSpeed {} {
  return [expr "[sim Rand 40] + 70"]
}


proc ExplosionPitch {} {
  return [expr "[sim Rand 20] + 90"]
}


proc HonkPitch {} {
  return [expr "[sim Rand 20] + 90"]
}


########################################################################
# Global Window Handlers


proc WithdrawAll {} {
  WithdrawHeads
  WithdrawEditors
  WithdrawMaps
  WithdrawGraphs
  WithdrawBudgets
  WithdrawEvaluations
  WithdrawScenarios
  WithdrawFiles
  WithdrawConfigs
  WithdrawKeys
  WithdrawAsks
  WithdrawPlayers
  WithdrawNotices
}


proc ShowInitial {} {
  ShowHeads
  ShowEditors
  ShowMaps
  EnableMaps
}


########################################################################
# Head Window Handlers


proc PrepHead {head} {
  global State
  InitHeadMenus $head
  case $State {
    uninitialized {
    }
    scenario {
      ShowHeadOf $head
      ShowScenarioOf $head
      ShowMapOf $head
      DisableMaps
      ReShowPictureOn $head
      sim UpdateEditors
      sim UpdateMaps
    }
    play {
      ShowHeadOf $head
      ShowEditorOf $head
      ShowMapOf $head
      EnableMaps
      ReShowPictureOn $head
      InitHead $head
      InitHeadMenus $head
      ShowHeadOf $head
      ShowEditorOf $head
      ShowMapOf $head
    }
  }
}


proc ShowHeadOf {head} {
  wm deiconify $head
}


proc ShowHeads {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowHeadOf $win
  }
}


proc WithdrawHeads {} {
  global HeadWindows
  foreach win $HeadWindows {
    wm withdraw $win
  }
}


proc DeleteHeadWindow {head} {
  UIQuit $head
}


proc InitHeads {} {
  global HeadWindows
  foreach win $HeadWindows {
    InitHead $win
  }
}


proc InitHead {win} {
  set w [WindowLink $win.text]
  $w configure -state normal
  $w delete 0.0 end
  $w insert end "\n"
  $w configure -state disabled
  set w [WindowLink $win.entry]
  $w delete 0 end
  global ${w}.value
  set ${w}.value ""
  sim UpdateHeads
}


proc InitAllHeadMenus {} {
  global HeadWindows

  foreach win $HeadWindows {
    InitHeadMenus $win
  }
}


proc InitHeadMenus {win} {
  global State
  set m0 [WindowLink $win.m0]
  set m1 [WindowLink $win.m1]
  set m2 [WindowLink $win.m2]
  set m3 [WindowLink $win.m3]
  set m4 [WindowLink $win.m4]
  set m5 [WindowLink $win.m5]
  set b0 [WindowLink $win.b0]
  set b1 [WindowLink $win.b1]
  set b2 [WindowLink $win.b2]
  set b3 [WindowLink $win.b3]
  set b4 [WindowLink $win.b4]
  set b5 [WindowLink $win.b5]
  case $State {
    uninitialized {
    }
    scenario {
      $m0 unpost
      $m1 unpost
      $m2 unpost
      $m3 unpost
      $m4 unpost
      $m5 unpost
      $m0 disable 1
      $m0 disable 2
      $m0 disable 5
      $b0 config -state normal
      $b1 config -state disabled
      $b2 config -state disabled
      $b3 config -state disabled
      $b4 config -state disabled
      $b5 config -state disabled
    }
    play {
      $m0 enable 1
      $m0 enable 2
      $m0 enable 5
      $b0 config -state normal
      $b1 config -state normal
      $b2 config -state normal
      $b3 config -state normal
      $b4 config -state normal
      $b5 config -state normal
    }
  }
}


proc CrushHead {head} {
  global SubWindows VoteNames

  foreach foo $VoteNames {
    global VotesFor$foo
    set votes [eval ident \$VotesFor$foo]
    set i [lsearch $votes $head]
    if {$i != -1} {
      set VotesFor$foo [lreplace $votes $i $i]
    }
  }

  foreach foo $SubWindows {
    set sym [lindex $foo 0]
    set name [lindex $foo 1]
    global $name
    set wins [eval ident "\$$name"]
    foreach win $wins {
      if {[WindowLink $win.head] == $head} {
	DeleteWindow $sym $name $win
      }
    }
  }
}


proc TalkDown {win} {
  tk_butDown $win
}


proc TalkUp {win} {
  tk_butUp $win
}


proc DoEnterMessage {win var} {
  global $var
  set msg [eval ident "\$\{$var\}"]
  DoSendMessage $msg
  $win delete 0 end
}


proc DoEvalMessage {win var} {
  global $var
  set command [eval ident "\$\{$var\}"]
  $win delete 0 end
  DoSendMessage "Evaluating TCL: $command"
  catch {uplevel #0 $command} result
  DoSendMessage "Result: $result"
}


proc DoSendMessage {msg {tag message}} {
  global HeadWindows
  foreach win $HeadWindows {
    appendWithTag [WindowLink $win.text] $tag "$msg"
  }
}


proc UISetMessage {msg {tag status}} {
  global EditorWindows
  global HeadWindows
  foreach win $EditorWindows {
    [WindowLink $win.message] configure -text "$msg"
  }
  foreach win $HeadWindows {
    appendWithTag [WindowLink $win.text] $tag "$msg"
  }
}


proc appendWithTag {w tag text} {
    set start [$w index end]
    $w configure -state normal
    $w insert end "${text}\n"
    $w tag add $tag $start {end - 1 char}
    $w configure -state disabled
    $w yview -pickplace {end - 1 char}
}


########################################################################
# Budget Window Handlers


proc ShowBudgetOf {head} {
  set win [WindowLink $head.budget]
  if {$win == {}} {
    set win [MakeWindow.budget $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
  update idletasks
  sim UpdateBudgets
}


proc ShowBudgets {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowBudgetOf $win
  }
}


proc WithdrawBudgets {} {
  global BudgetWindows
  foreach win $BudgetWindows {
    wm withdraw $win
  }
  StopBudgetTimer
}


proc BudgetContinue {{win ""}} {
  global OldBudget BudgetRoadFund BudgetFireFund BudgetPoliceFund BudgetTaxRate
  set OldBudget 0
  if {([sim RoadFund] != $BudgetRoadFund) ||
      ([sim FireFund] != $BudgetFireFund) ||
      ([sim PoliceFund] != $BudgetPoliceFund) ||
      ([sim TaxRate] != $BudgetTaxRate)} {
    UISetMessage "The budget was changed."
  } else {
    UISetMessage "The budget wasn't changed."
  }
  WithdrawBudgets
  sim Resume
}


proc BudgetReset {{win ""}} {
  global OldBudget BudgetRoadFund BudgetFireFund BudgetPoliceFund BudgetTaxRate
  if {([sim RoadFund] != $BudgetRoadFund) ||
      ([sim FireFund] != $BudgetFireFund) ||
      ([sim PoliceFund] != $BudgetPoliceFund) ||
      ([sim TaxRate] != $BudgetTaxRate)} {
    UISetMessage "The budget was reset."
    if {[sim Players] > 1} {
      UIMakeSound edit Sorry
    }
  } else {
    UISetMessage "The budget was reset."
  }
  sim RoadFund $BudgetRoadFund
  sim FireFund $BudgetFireFund
  sim PoliceFund $BudgetPoliceFund 
  sim TaxRate $BudgetTaxRate
  set OldBudget 0
  ChangeBudget
}


proc BudgetCancel {{win ""}} {
  BudgetReset
  WithdrawBudgets
  sim Resume
}


proc BudgetSetTaxRate {rate} {
  sim TaxRate $rate
  ChangeBudget
}


proc BudgetSetRoadFund {percent} {
  sim RoadFund $percent
  ChangeBudget
}


proc BudgetSetFireFund {percent} {
  sim FireFund $percent
  ChangeBudget
}


proc BudgetSetPoliceFund {percent} {
  sim PoliceFund $percent
  ChangeBudget
}


proc BudgetVisible {w v} {
}


proc UIShowBudgetAndWait {} {
  global OldBudget BudgetRoadFund BudgetFireFund BudgetPoliceFund BudgetTaxRate
  if {$OldBudget == 0} {
    set BudgetRoadFund [sim RoadFund]
    set BudgetFireFund [sim FireFund]
    set BudgetPoliceFund [sim PoliceFund]
    set BudgetTaxRate [sim TaxRate]
    set OldBudget 1
  }
  ShowBudgets
  UISetMessage "Pausing to set the budget ..."
  sim Pause
  StartBudgetTimer
  InitVotesForBudget
}


proc ToggleBudgetTimer {} {
  global BudgetTimerActive
  if {$BudgetTimerActive} {
    StopBudgetTimer
  } else {
    StartBudgetTimer
  }
}


proc StopBudgetTimer {} {
  global BudgetTimerActive
  set BudgetTimerActive 0
  UpdateBudgetTimer
}


proc StartBudgetTimer {} {
  global BudgetTimerActive BudgetTimer BudgetTimeout
  set me [Unique]
  set BudgetTimerActive $me
  set BudgetTimer $BudgetTimeout
  UpdateBudgetTimer
  after 1000 TickBudgetTimer $me
}


proc RestartBudgetTimer {} {
  global BudgetTimerActive
  if {$BudgetTimerActive} {
    StopBudgetTimer
    StartBudgetTimer
  }
}


proc UpdateBudgetTimer {} {
  global BudgetWindows BudgetTimerActive BudgetTimer
  if {$BudgetTimerActive} {
    set text [format "Auto Cancel in %d seconds ..." $BudgetTimer]
  } else {
    set text [format "Auto Cancel"]
  }
  foreach win $BudgetWindows {
    set t [WindowLink $win.timer]
    $t config -text "$text"
  }
}


proc TickBudgetTimer {me} {
  global BudgetTimerActive BudgetTimer BudgetTimeout
  if {$BudgetTimerActive == $me} {
    incr BudgetTimer -1
    if {$BudgetTimer < 0} {
      StopBudgetTimer
      UpdateBudgetTimer
      FireBudgetTimer
    } else {
      UpdateBudgetTimer
      after 1000 TickBudgetTimer $me
    }
  }
}


proc FireBudgetTimer {} {
  BudgetCancel
}


proc funds {n} {
  sim Funds $n
}


proc UISetBudget {cashflow previous current collected taxrate} {
  global BudgetWindows
  foreach win $BudgetWindows {
    [WindowLink $win.cashflow] configure -text $cashflow
    [WindowLink $win.previous] configure -text $previous
    [WindowLink $win.current] configure -text $current
    [WindowLink $win.collected] configure -text $collected
    [WindowLink $win.taxrate] set $taxrate
    [WindowLink $win.taxlabel] configure -text "$taxrate%"
  }
}


proc UISetBudgetValues {roadgot roadwant roadpercent policegot policewant policepercent firegot firewant firepercent} {
  global BudgetWindows
  foreach win $BudgetWindows {
    [WindowLink $win.fire].request configure -text "$firepercent% of $firewant = $firegot"
    [WindowLink $win.fire].fund set $firepercent
    [WindowLink $win.police].request configure -text "$policepercent% of $policewant = $policegot"
    [WindowLink $win.police].fund set $policepercent
    [WindowLink $win.road].request configure -text "$roadpercent% of $roadwant = $roadgot"
    [WindowLink $win.road].fund set $roadpercent
  }
}


########################################################################
# Evaluation Window Handlers


proc ShowEvaluationOf {head} {
  set win [WindowLink $head.evaluation]
  if {$win == {}} {
    set win [MakeWindow.evaluation $head [winfo server $head]]
  }
  wm raise $win
  wm deiconify $win
  update idletasks
  sim UpdateEvaluations
}


proc WithdrawEvaluations {} {
  global EvaluationWindows
  foreach win $EvaluationWindows {
    wm withdraw $win
  }
}


proc EvaluationVisible {w v} {
}


proc UISetEvaluation {changed score ps0 ps1 ps2 ps3 pv0 pv1 pv2 pv3 pop delta assessed cityclass citylevel goodyes goodno title} {
  set class [string tolower $cityclass]
  UISetMessage "Score $score, $class population $pop."
  global EvaluationWindows
  foreach win $EvaluationWindows {
    wm title $win "$title"
    wm iconname $win "$title"
    [WindowLink $win.goodjob] configure -text \
	"$goodyes\n$goodno"
    [WindowLink $win.problemnames] configure -text \
	"$ps0\n$ps1\n$ps2\n$ps3"
    [WindowLink $win.problempercents] configure -text \
	"$pv0\n$pv1\n$pv2\n$pv3"
    [WindowLink $win.stats] configure -text \
	"$pop\n$delta\n\n$assessed\n$cityclass\n$citylevel"
    [WindowLink $win.score] configure -text \
	"$score\n$changed"
  }
}


########################################################################
# File Window Handlers


proc ShowFileOf {head} {
  set win [WindowLink $head.file]
  if {$win == {}} {
    set win [MakeWindow.file $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
  return $win
}


proc ShowFiles {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowFileOf $win
  }
}


proc WithdrawFiles {} {
  global FileWindows
  foreach win $FileWindows {
    wm withdraw $win
  }
}


proc DoFileDialog {win Message Path Pattern FileName ActionOk ActionCancel} {
  ShowFileDialog $win "$Path" "$Pattern"
  $win.message1 configure -text "$Message"
  $win.path.path delete 0 end
  $win.path.path insert 0 $Path
  $win.file.file delete 0 end
  $win.file.file insert 0 "$FileName"
  $win.frame1.ok config -command "
      $ActionOk \[$win.file.file get\] \[$win.path.path get\]
      wm withdraw $win"
  $win.frame1.rescan config -command "
      ShowFileDialog $win \[$win.path.path get\] $Pattern"
  $win.frame1.cancel config -command "
      $ActionCancel
      wm withdraw $win"
  bind $win.files.files "<Double-Button-1>" "\
    FileSelectDouble $win %W %y $Pattern \"
	$ActionOk \[$win.file.file get\] \[$win.path.path get\]\""
  bind $win.path.path <Return> "
    ShowFileDialog $win \[$win.path.path get\] $Pattern
    $win.file.file cursor 0
    focus $win.file.file"
  bind $win.file.file <Return> "\
    $ActionOk \[$win.file.file get\] \[$win.path.path get]
    wm withdraw $win"
}


proc BindSelectOne {win Y} {
  set Nearest [$win nearest $Y]
  if {$Nearest >= 0} {
    $win select from $Nearest
    $win select to $Nearest
  }
}


proc FileSelect {win widget Y} {
  BindSelectOne $widget $Y
  set Nearest [$widget nearest $Y]
  if {$Nearest >= 0} {
    set Path [$win.path.path get]
    set TmpEntry [$widget get $Nearest]
    if {[string compare "/" [string index $TmpEntry \
          [expr [string length $TmpEntry]-1]]] == 0 || \
        [string compare "@" [string index $TmpEntry \
          [expr [string length $TmpEntry]-1]]] == 0} {
      # handle directories, and symbolic links to directories
      set FileName [string range $TmpEntry 0 \
            [expr [string length $TmpEntry]-2]]
      # whoops / or @ is part of the name
      if {[MiscIsDir $Path/$FileName] != 1} {
        set FileName $TmpEntry
      }
    } {
      if {[string compare "*" [string index $TmpEntry \
            [expr [string length $TmpEntry]-1]]] == 0} {
        # handle executable filenames
        set FileName [string range $TmpEntry 0 \
              [expr [string length $TmpEntry]-2]]
        # whoops * is part of the name
        if {[file executable $Path/$FileName] != 1} {
          set FileName $TmpEntry
        }
      } {
        # a ordinary filename
        set FileName $TmpEntry
      }
    }
    # enter the selected filename into the filename field
    if {[MiscIsDir $Path/$FileName] != 1} {
      $win.file.file delete 0 end
      $win.file.file insert 0 $FileName
    }
  }
}


proc FileSelectDouble {win widget Y Pattern Action} {
  BindSelectOne $widget $Y
  set Nearest [$widget nearest $Y]
  if {$Nearest >= 0} {
    set Path [$win.path.path get]
    set TmpEntry [$widget get $Nearest]
    if {[string compare $TmpEntry "../"] == 0} {
      # go up one directory
      set TmpEntry \
        [string trimright [string trimright [string trim $Path] /] @]
      if {[string length $TmpEntry] <= 0} {
        return
      }
      set Path [file dirname $TmpEntry]
      $win.path.path delete 0 end
      $win.path.path insert 0 $Path
      ShowFileDialog $win $Path $Pattern
    } {
      if {[string compare "/" [string index $TmpEntry \
            [expr [string length $TmpEntry]-1]]] == 0 || \
          [string compare "@" [string index $TmpEntry \
            [expr [string length $TmpEntry]-1]]] == 0} {
        # handle directorys, and symbolic links to directorys
        set FileName [string range $TmpEntry 0 \
              [expr [string length $TmpEntry]-2]]
        # whoops / or @ is part of the name
        if {[MiscIsDir $Path/$FileName] != 1} {
          set FileName $TmpEntry
        }
      } {
        if {[string compare "*" [string index $TmpEntry \
              [expr [string length $TmpEntry]-1]]] == 0} {
          # handle executable filenames
          set FileName [string range $TmpEntry 0 \
                [expr [string length $TmpEntry]-2]]
          # whoops * is part of the name
          if {[file executable $Path/$FileName] != 1} {
            set FileName $TmpEntry
          }
        } {
          # a ordinary filename
          set FileName $TmpEntry
        }
      }
      # change directory
      if {[MiscIsDir $Path/$FileName] == 1} {
        if {[string compare "/" [string index $Path \
              [expr [string length $Path]-1]]] == 0} {
           append Path $FileName
        } {
          append Path / $FileName
        }
        $win.path.path delete 0 end
        $win.path.path insert 0 $Path
        ShowFileDialog $win $Path $Pattern
      } {
        # enter the selected filename into the filename field
	$win.file.file delete 0 end
	$win.file.file insert 0 "$FileName"
        if {[string length $Action] > 0} {
          eval $Action
        }
        wm withdraw $win
      }
    }
  }
}


proc NameComplete {win Type} {

  set NewFile ""
  set Matched ""

  if {[string compare $Type path] == 0} {
    set DirName [file dirname [$win.path.path get]]
    set FileName [file tail [$win.path.path get]]
  } {
    set DirName [file dirname [$win.path.path get]/]
    set FileName [file tail [$win.file.file get]]
  }

  set FoundCounter 0
  if {[MiscIsDir $DirName] == 1} {
    catch "exec ls $DirName/" Result
    set Counter 0
    set ListLength [llength $Result]
    # go through list
    while {$Counter < $ListLength} {
      if {[string length $FileName] == 0} {
        if {$FoundCounter == 0} {
          set NewFile [lindex $Result $Counter]
        } {
          set Counter1 0
          set TmpFile1 $NewFile
          set TmpFile2 [lindex $Result $Counter]
          set Length1 [string length $TmpFile1]
          set Length2 [string length $TmpFile2]
          set NewFile ""
          if {$Length1 > $Length2} {
            set Length1 $Length2
          }
          while {$Counter1 < $Length1} {
            if {[string compare [string index $TmpFile1 $Counter1] \
                  [string index $TmpFile2 $Counter1]] == 0} {
              append NewFile [string index $TmpFile1 $Counter1]
            } {
              break
            }
            incr Counter1 1
          }
        }
        incr FoundCounter 1
      } {
        if {[regexp "^$FileName" [lindex $Result $Counter] \
              Matched] == 1} {
          if {$FoundCounter == 0} {
            set NewFile [lindex $Result $Counter]
          } {
            set Counter1 0
            set TmpFile1 $NewFile
            set TmpFile2 [lindex $Result $Counter]
            set Length1 [string length $TmpFile1]
            set Length2 [string length $TmpFile2]
            set NewFile ""
            if {$Length1 > $Length2} {
              set Length1 $Length2
            }
            while {$Counter1 < $Length1} {
              if {[string compare [string index $TmpFile1 $Counter1] \
                    [string index $TmpFile2 $Counter1]] == 0} {
                append NewFile [string index $TmpFile1 $Counter1]
              } {
                break
              }
              incr Counter1 1
            }
          }
          incr FoundCounter 1
        }
      }
      incr Counter 1
    }
  }

  if {$FoundCounter == 1} {
    if {[MiscIsDir $DirName/$NewFile] == 1} {
      if {[string compare $DirName "/"] == 0} {
        $win.path.path delete 0 end
        $win.path.path insert 0 "/[string trim [string trim $NewFile /] @]/"
      } {
        $win.path.path delete 0 end
        $win.path.path insert 0 "[string trimright $DirName /]/[string trim [string trim $NewFile /] @]/"
      }
    } {
      $win.path.path delete 0 end
      $win.path.path insert 0 \
        "[string trim [string trimright $DirName /] @]/"
      $win.file.file delete 0 end
      $win.file.file insert 0 "$NewFile"
    }
  } {
    if {[MiscIsDir $DirName/$NewFile] == 1 ||
        [string compare $Type path] == 0} {
      $win.path.path delete 0 end
      $win.path.path insert 0 \
        "[string trimright $DirName /]/[string trim [string trim $NewFile /] @]"
    } {
      $win.path.path delete 0 end
      $win.path.path insert 0 "$DirName"
      if {[string length $NewFile] > 0} {
        $win.file.file delete 0 end
        $win.file.file insert 0 "$NewFile"
      }
    }
  }
}


proc ShowFileDialog {win Path Pattern} {
  busy $win {
    set Path [lindex [split $Path] 0]
    if {[$win.files.files size] > 0} {
      $win.files.files delete 0 end
    }
    # read directory
    if {[catch "exec ls -F $Path" Result] != 0} {
      set ElementList {}
    }
    if {[string match $Result "* not found"]} {
      set ElementList {}
    }
    set ElementList [lsort $Result]

    # insert ..
    if {[string compare $Path "/"] != 0} {
      $win.files.files insert end "../"
    }

    # walk through list
    foreach Counter $ElementList {
      # insert filename
      if {[string match $Pattern $Counter] == 1} {
	if {[string compare $Counter "../"] != 0 &&
	    [string compare $Counter "./"] != 0} {
	  $win.files.files insert end $Counter
	}
      } else {
        set fn $Path/[string trim [string trim [string trim $Counter /] @] *]
	if {[MiscIsDir $fn]} {
	  $win.files.files insert end $Counter
	}
      }
    }
  }
}


proc MiscIsDir {PathName} {

  if {[file isdirectory $PathName] == 1} {
    return 1
  } {
    catch "file type $PathName" Type
    if {[string compare $Type link] == 0} {
      set LinkName [file readlink $PathName]
      catch "file type $LinkName" Type
      while {[string compare $Type link] == 0} {
        set LinkName [file readlink $LinkName]
      }
      return [file isdirectory $LinkName]
    }
  }
  return 0
}


proc busy {win cmds} {
    set busy {}
    set list [winfo children $win]
    set busy $list
    while {$list != ""} {
	set next {}
	foreach w $list {
	    set class [winfo class $w]
	    set cursor [lindex [$w config -cursor] 4]
	    if {[winfo toplevel $w] == $w} {
		lappend busy [list $w $cursor]
	    }
	    set next [concat $next [winfo children $w]]
	}
	set list $next
    }

    foreach w $busy {
	catch {[lindex $w 0] config -cursor watch}
    }

    update idletasks

    set error [catch {uplevel eval [list $cmds]} result]

    foreach w $busy {
	catch {[lindex $w 0] config -cursor [lindex $w 1]}
    }

    if $error {
	error $result
    } else {
	return $result
    }
}


########################################################################
# Editor Window Handlers

proc ShowEditorOf {head} {
  global EditorWindows
  set found 0
  foreach win $EditorWindows {
    if {[WindowLink $win.head] == $head} {
      wm deiconify $win
      wm raise $win
      set found 1
    }
  }
  if {$found == 0} {
    NewEditorOf $head
  } else {
    update idletasks
    sim UpdateEditors
    sim UpdateMaps
  }
}


proc NewEditorOf {head} {
  set win [MakeWindow.editor $head [winfo server $head]]
  wm deiconify $win
  update idletasks
  sim UpdateEditors
  sim UpdateMaps
}


proc ShowEditors {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowEditorOf $win
  }
}


proc WithdrawEditors {} {
  global EditorWindows
  foreach win $EditorWindows {
    wm withdraw $win
  }
}


proc InitEditors {} {
  global EditorWindows
  foreach win $EditorWindows {
    InitEditor $win
  }
}


proc InitEditor {win} {
  set e [WindowLink $win.view]
  UISetToolState $win 7
  $e ToolState 7
  set size [$e size]
  $e Pan 960 800
  $e AutoGoing 0
  global $e.TrackState
  set $e.TrackState {}
}


proc SetEditorAutoGoto {win val} {
  global AutoGoto.$win
  set AutoGoto.$win $val
  set e [WindowLink $win.view]
  $e AutoGoto $val
}


proc SetEditorControls {win val} {
  global Controls.$win
  set Controls.$win $val
  if {$val} {
    pack append $win $win.leftframe {left frame center filly} 
  } else {
    pack unpack $win.leftframe
  }
}


proc SetEditorOverlay {win val} {
  global Overlay.$win
  set Overlay.$win $val
  set e [WindowLink $win.view]
  $e ShowOverlay $val
}


proc SetEditorSkip {win val} {
  set e [WindowLink $win.view]
  $e Skip $val
}


proc EditorToolDown {mod w x y} {
  global [set var $w.TrackState]

  $w ToolMode 1

  case [$w ToolState] in \
    7 { # bulldozer
      UIMakeSoundOn $w edit Rumble "-repeat 4"
    } \
    10 { # chalk
      StartChalk $w
    }

  case $mod in \
    constrain {
      set $var [list constrain_start $x $y]
      $w ToolConstrain $x $y
    } \
    default {
      set $var none
    }
  EditorTool ToolDown $w $x $y
}


proc EditorToolDrag {w x y} {
  EditorTool ToolDrag $w $x $y
}


proc EditorToolUp {w x y} {
  global [set var $w.TrackState]
  $w ToolMode 0

  case [$w ToolState] in \
    7 { # bulldozer
     UIStopSoundOn $w edit 1
    } \
    10 { # chalk
      StopChalk $w
    }

  EditorTool ToolUp $w $x $y
  set $var {}
  $w ToolConstrain -1 -1
  sim UpdateMaps
  sim UpdateEditors
}


proc EditorTool {action w x y} {
  global [set var $w.TrackState]
  set state [eval ident "\$\{$var\}"]
  case [lindex $state 0] in \
    constrain_start {
      set x0 [lindex $state 1]
      set y0 [lindex $state 2]
      set dx [expr "$x - $x0"]
      set dy [expr "$y - $y0"]
      if [expr "($dx > 16) || ($dx < -16)"] then {
        $w ToolConstrain -1 $y0
        set $var none
      } else {
	if [expr "($dy > 16) || ($dy < -16)"] then {
	  $w ToolConstrain $x0 -1
	  set $var none
	}
      }
    }
  $w $action $x $y
}


proc StartChalk {w} {
  sim CollapseMotion 0
}


proc StopChalk {w} {
  sim CollapseMotion 1
}


proc EditorPanDown {mod w x y} {
  global [set var $w.TrackState]
  $w ToolMode -1
  case $mod in \
    constrain {
      set $var [list constrain_start $x $y]
      $w ToolConstrain $x $y
    } \
    default {
      set $var none
    }
  EditorTool PanStart $w $x $y
}


proc EditorPanDrag {w x y} {
  EditorTool PanTo $w $x $y
}


proc EditorPanUp {w x y} {
  $w AutoGoing 0
  $w ToolMode 0
  EditorTool PanTo $w $x $y
  $w ToolConstrain -1 -1
  sim UpdateMaps
  sim UpdateEditors
}


proc EditorKeyDown {w k} {
  $w KeyDown $k
}


proc EditorKeyUp {w k} {
  $w KeyUp $k
}


proc BindEditorButtons {win} {
  set w [WindowLink $win.top]

  bind $win <1> "CancelPie $win ; EditorToolDown none %W %x %y"
  bind $win <B1-Motion> {EditorToolDrag %W %x %y}
  bind $win <ButtonRelease-1> {EditorToolUp %W %x %y}

  bind $win <Control-1> "CancelPie $win ; EditorToolDown constrain %W %x %y"
  bind $win <Control-B1-Motion> {EditorToolDrag %W %x %y}
  bind $win <Control-ButtonRelease-1> {EditorToolUp %W %x %y}

  bind $win <2> "CancelPie $win ; EditorPanDown none %W %x %y"
  bind $win <B2-Motion> {EditorPanDrag %W %x %y}
  bind $win <ButtonRelease-2> {EditorPanUp %W %x %y}

  bind $win <Control-2> "CancelPie $win ; EditorPanDown constrain %W %x %y"
  bind $win <Control-B2-Motion> {EditorPanDrag %W %x %y}
  bind $win <Control-ButtonRelease-2> {EditorPanUp %W %x %y}

  InitPie $win $w.toolpie
}


proc BindVotingButton {win but name} {
  set w [WindowLink $win.top]

  bind $but <Any-Enter> "VoteButtonEnter $win $but"
  bind $but <Any-Leave> "VoteButtonLeave $win $but"
  bind $but <1> "VoteButtonDown $win $but $name"
  bind $but <ButtonRelease-1> "VoteButtonUp $win $but $name"
}


proc VoteButtonEnter {win but} {
  global tk_priv
  set screen [winfo screen $but]
  if {[lindex [$but config -state] 4] != "disabled"} {
    $but config -state active
    set tk_priv(window@$screen) $but
  } else {
    set tk_priv(window@$screen) ""
  }
}


proc VoteButtonLeave {win but} {
  global tk_priv
  if {[lindex [$but config -state] 4] != "disabled"} {
    $but config -state normal
  }
  set screen [winfo screen $but]
  set tk_priv(window@$screen) ""
}


proc VoteButtonDown {win but name} {
  global tk_priv
  set screen [winfo screen $but]
  set rel [lindex [$but config -relief] 4]
  set tk_priv(relief@$screen) $rel
  if {[lindex [$but config -state] 4] != "disabled"} {
    set head [WindowLink $win.head]
    if {[IsVotingFor $head $name]} {
      $but config -relief raised
    } else {
      $but config -relief sunken
    }
  }
}


proc VoteButtonUp {win but name} {
  global tk_priv
  set screen [winfo screen $but]
  $but config -relief $tk_priv(relief@$screen)
  if {($but == $tk_priv(window@$screen))
	&& ([lindex [$but config -state] 4] != "disabled")} {
    uplevel #0 [list $but invoke]
    set head [WindowLink $win.head]
    if {[IsVotingFor $head $name]} {
      $but config -relief sunken
    } else {
      $but config -relief raised
    }
  }
}


proc PressVoteButton {win but name} {
  global tk_priv
  uplevel #0 [list $but invoke]
  set head [WindowLink $win.head]
  if {[IsVotingFor $head $name]} {
    $but config -relief sunken
  } else {
    $but config -relief raised
  }
}


proc UISetFunds {funds} {
  global HeadWindows EditorInfoWindows
  foreach win $HeadWindows {
    [WindowLink $win.funds] configure -text "$funds"
  }
  catch {
    foreach win $EditorInfoWindows {
      catch {[WindowLink $win.efunds] configure -text "$funds"}
    }
  }
}


proc UISetDate {date} {
  global HeadWindows EditorInfoWindows
  foreach win $HeadWindows {
    [WindowLink $win.date] configure -text "$date"
  }
  catch {
    foreach win $EditorInfoWindows {
      catch {[WindowLink $win.edate] configure -text "$date"}
    }
  }
}


proc UISetDemand {r c i} {
  global HeadWindows EditorInfoWindows

  if {$r <= 0} then {set ry0 32} else {set ry0 24}
  set ry1 [expr "$ry0 - $r"]
  if {$c <= 0} then {set cy0 32} else {set cy0 24}
  set cy1 [expr "$cy0 - $c"]
  if {$i <= 0} then {set iy0 32} else {set iy0 24}
  set iy1 [expr "$iy0 - $i"]

  foreach win $HeadWindows {
    set can [WindowLink $win.demand]
    $can coords r 8 $ry0 14 $ry1
    $can coords c 17 $cy0 23 $cy1
    $can coords i 26 $iy0 32 $iy1
  }
  catch {
    foreach win $EditorInfoWindows {
      catch {
	set can [WindowLink $win.edemand]
	$can coords r 15 $ry0 27 $ry1
	$can coords c 36 $cy0 48 $cy1
	$can coords i 57 $iy0 69 $iy1
      }
    }
  }
}


proc UISetOptions {autobudget autogoto autobulldoze disasters sound animation} {
  global AutoBudget AutoGoto AutoBulldoze Disasters Sound
  set AutoBudget $autobudget
  set AutoGoto $autogoto
  set AutoBulldoze $autobulldoze
  set Disasters $disasters
  set Sound $sound
  set DoAnimation $animation
}


proc UIDidToolRes {win x y} {
  UIMakeSoundOn $win edit O "-speed 140"
}


proc UIDidToolCom {win x y} {
  UIMakeSoundOn $win edit A "-speed 140"
}


proc UIDidToolInd {win x y} {
  UIMakeSoundOn $win edit E "-speed 140"
}


proc UIDidToolFire {win x y} {
  UIMakeSoundOn $win edit O "-speed 130"
}


proc UIDidToolQry {win x y} {
  UIMakeSoundOn $win edit E "-speed 200"
}


proc UIDidToolPol {win x y} {
  UIMakeSoundOn $win edit E "-speed 130"
}


proc UIDidToolWire {win x y} {
  UIMakeSoundOn $win edit O "-speed 120"
}


proc UIDidToolDozr {win x y} {
  UIMakeSoundOn $win edit Rumble
}


proc UIDidToolRail {win x y} {
  UIMakeSoundOn $win edit O "-speed 100"
}


proc UIDidToolRoad {win x y} {
  UIMakeSoundOn $win edit E "-speed 100"
}


proc UIDidToolChlk {win x y} {
}


proc UIDidToolEraser {win x y} {
}


proc UIDidToolStad {win x y} {
  UIMakeSoundOn $win edit O "-speed 90"
}


proc UIDidToolPark {win x y} {
  UIMakeSoundOn $win edit A "-speed 130"
}


proc UIDidToolSeap {win x y} {
  UIMakeSoundOn $win edit E "-speed 90"
}


proc UIDidToolCoal {win x y} {
  UIMakeSoundOn $win edit O "-speed 75"
}


proc UIDidToolNuc {win x y} {
  UIMakeSoundOn $win edit E "-speed 75"
}


proc UIDidToolAirp {win x y} {
  UIMakeSoundOn $win edit A "-speed 50"
}


proc UISetToolState {w state} {
  global EditorPallets EditorPalletImages ToolInfo
  set win [winfo toplevel $w]
  ExclusivePallet $state $win $EditorPallets ic $EditorPalletImages \
	raised sunken {NoFunction}
	{NoFunction}
  set c1 [WindowLink $w.cost1]
  if {"$c1" != ""} {
    set info [lindex $ToolInfo $state]
    set cost1 [lindex $info 1]
    set cost2 [lindex $info 2]
    $c1 configure -text "$cost1"
    [WindowLink $w.cost2] configure -text "$cost2"
  }
}


proc UIShowZoneStatus {zone density value crime pollution growth x y} {
  global QueryX QueryY
  set QueryX [expr "8 + 16 * $x"]
  set QueryY [expr "8 + 16 * $y"]
  UIShowPicture 9 [list $zone $density $value $crime $pollution $growth]
}


########################################################################
# Map Window Handlers


proc ShowMapOf {head} {
  global MapWindows
  set found 0
  foreach win $MapWindows {
    if {"[WindowLink $win.head]" == "$head"} {
      wm deiconify $win
      wm raise $win
      set found 1
    }
  }
  if {$found == 0} {
    NewMapOf $head
  } else {
    update idletasks
    sim UpdateMaps
  }
}


proc NewMapOf {head} {
  set win [MakeWindow.map $head [winfo server $head]]
  wm deiconify $win
  update idletasks
  sim UpdateMaps
}


proc ShowMaps {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowMapOf $win
  }
}


proc WithdrawMaps {} {
  global MapWindows
  foreach win $MapWindows {
    wm withdraw $win
  }
}


proc InitMaps {} {
  global MapWindows
  foreach win $MapWindows {
    InitMap $win
  }
}


proc InitMap {win} {
  SetMapState $win 0
}


proc EnableMaps {} {
  global MapWindows
  foreach win $MapWindows {
    EnableMap $win
  }
}


proc EnableMap {win} {
  [WindowLink $win.view] ShowEditors 1
  [WindowLink $win.zones] config -state normal
  [WindowLink $win.overlays] config -state normal
}


proc DisableMaps {} {
  global MapWindows
  foreach win $MapWindows {
    DisableMap $win
  }
}


proc DisableMap {win} {
  [WindowLink $win.view] ShowEditors 0
  [WindowLink $win.zones] config -state disabled
  [WindowLink $win.overlays] config -state disabled
}


proc SetMapState {win state} {
  set m [WindowLink $win.view]
  $m MapState $state
}


proc MapPanDown {w x y} {
  $w PanStart $x $y
}


proc MapPanDrag {w x y} {
  $w PanTo $x $y
}


proc MapPanUp {w x y} {
  $w PanTo $x $y
  sim UpdateMaps
  sim UpdateEditors
}


proc UISetMapState {w state} {
  global MapTitles
  set win [winfo toplevel $w]
  set m [WindowLink $win.view]
  set title [lindex $MapTitles $state]
  wm title $win "$title"
  wm iconname $win "$title"
  global [set var MapState.$win]
  set $var $state

  case $state { \
    {6 8 9 10 11 12 13} {
      [WindowLink $win.legend] config -bitmap "@images/legendmm.xpm"
    } \
    {7} {
      [WindowLink $win.legend] config -bitmap "@images/legendpm.xpm"
    } \
    {0 1 2 3 4 5 14} {
      [WindowLink $win.legend] config -bitmap "@images/legendn.xpm"
    }
  }
}


########################################################################
# Graph Window Handlers


proc ShowGraphOf {head} {
  set win [WindowLink $head.graph]
  if {$win == {}} {
    set win [MakeWindow.graph $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
  update idletasks
  sim UpdateGraphs
}


proc WithdrawGraphs {} {
  global GraphWindows
  foreach win $GraphWindows {
    wm withdraw $win
  }
}


proc InitGraphs {} {
  global GraphWindows
  foreach win $GraphWindows {
    InitGraph $win
  }
}


proc InitGraph {win} {
  UISetGraphState $win 1 1 1 1 1 1 0
}


proc UISetGraphState {win t0 t1 t2 t3 t4 t5 range} {
  set g [WindowLink $win.graphview]
  GraphPalletMask $win [expr "$t0 + ($t1<<1) + ($t2<<2) + ($t3<<3) + ($t4<<4) + ($t5<<5)"]
  GraphYearPallet $win $range
}


########################################################################
# Scenario Window Handlers


proc ShowScenarioOf {head} {
  set win [WindowLink $head.scenario]
  if {$win == {}} {
    set win [MakeWindow.scenario $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
}


proc ShowScenarios {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowScenarioOf $win
  }
}


proc WithdrawScenarios {} {
  global ScenarioWindows
  foreach win $ScenarioWindows {
    wm withdraw $win
  }
}


proc InitScenarios {} {
  global MapHistory MapHistoryNum
  if {$MapHistoryNum < 1} {
    set last disabled
  } else {
    set last normal
  }
  if {$MapHistoryNum == ([llength $MapHistory] - 1)} {
    set next disabled
  } else {
    set next normal
  }
  global ScenarioWindows
  foreach win $ScenarioWindows {
    [WindowLink $win.last] config -state $last
    [WindowLink $win.next] config -state $next
  }
}


proc InitScenario {win} {
  global MapHistory MapHistoryNum
  if {$MapHistoryNum < 1} {
    set last disabled
  } else {
    set last normal
  }
  if {$MapHistoryNum == ([llength $MapHistory] - 1)} {
    set next disabled
  } else {
    set next normal
  }
  [WindowLink $win.last] config -state $last
  [WindowLink $win.next] config -state $next
  UpdateVotesForUseThisMap
}


proc DeleteScenarioWindow {win} {
  UIQuit [WindowLink $win.head]
}


proc DoEnterCityName {win} {
}


########################################################################
# Undo/Redo Facility


proc InitHistory {} {
  global MapHistory
  global MapHistoryNum
  set MapHistory {}
  set MapHistoryNum -1
}


proc MakeHistory {cmd} {
  global MapHistory
  set len [llength $MapHistory]
  if {($len == 0) ||
      ($cmd != [lindex $MapHistory [expr $len-1]])} {
    lappend MapHistory $cmd
  } else {
    incr len -1
  }
  GotoHistory $len
}


proc GotoHistory {i} {
  global MapHistory
  global MapHistoryNum
  InitVotesForUseThisMap
  if {$i != $MapHistoryNum} {
    set MapHistoryNum $i
    set cmd [lindex $MapHistory $i]
    eval $cmd
  }
  if {$MapHistoryNum == 0} {
    set last disabled
  } else {
    set last normal
  }
  if {$MapHistoryNum == ([llength $MapHistory] - 1)} {
    set next disabled
  } else {
    set next normal
  }
  global ScenarioWindows
  foreach win $ScenarioWindows {
    [WindowLink $win.last] config -state $last
    [WindowLink $win.next] config -state $next
  }
}


proc NextHistory {} {
  global MapHistory
  global MapHistoryNum
  set len [llength $MapHistory]
  set i [expr "$MapHistoryNum + 1"]
  if {$i < $len} {
    GotoHistory $i
  }
}


proc PrevHistory {} {
  global MapHistory
  global MapHistoryNum
  set i [expr "$MapHistoryNum - 1"]
  if {$i >= 0} {
    GotoHistory $i
  }
}


########################################################################
# Config Window Handlers

proc ShowConfigOf {head} {
  set win [WindowLink $head.config]
  if {$win == {}} {
    set win [MakeWindow.config $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
  return $win
}


proc ShowConfigs {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowConfigOf $win
  }
}


proc WithdrawConfigs {} {
  global ConfigWindows
  foreach win $ConfigWindows {
    wm withdraw $win
  }
}


proc UIConfigure {win} {
  ShowConfigOf $win
}


########################################################################
# Key Window Handlers


proc InitKeys {} {
  global KeyWindows
  foreach win $KeyWindows {
    InitKey $win
  }
}


proc InitKey {win} {
  global KindOfLicense

  set t [WindowLink $win.type]
  set c [WindowLink $win.code]
  set k [WindowLink $win.key]

  UpdateLicenseOf $win

  case $KindOfLicense {
    0 { set l "Node Locked, Single Player" }
    1 { set l "Node Locked, Multi Player" }
    2 { set l "Floating, Single Player" }
    3 { set l "Floating, Multi Player" }
  }

  $t config -text "$l"
  $c config -text [LicenseCode]
  $k delete 0 end
}


proc ShowKeyOf {head} {
  set win [WindowLink $head.key]
  if {$win == {}} {
    set win [MakeWindow.key $head [winfo server $head]]
  }
  InitKey $win
  wm deiconify $win
  wm raise $win
  return $win
}


proc ShowKeys {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowKeyOf $win
  }
}


proc WithdrawKeys {} {
  global KeyWindows
  foreach win $KeyWindows {
    wm withdraw $win
  }
}


proc UIGetKey {win} {
  ShowKeyOf [WindowLink $win.head]
}


proc UIGetKeys {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowKeyOf $win
  }
}


proc DoInstallKey {win} {
  global KindOfLicense
  case $KindOfLicense {
    {0 1} { set kind 0 }
    {2 3} { set kind 1 }
    default { set kind 0 }
  }
  set key [[WindowLink $win.key] get]
  sim InstallKey $kind $key
  after 2000 sim Check
}


proc UpdateLicenses {} {
  global KeyWindows
  foreach win $KeyWindows {
    UpdateLicenseOf $win
  }
}

proc UpdateLicenseOf {win} {
  case [sim Type] {
    0 { set kind "Demo Mode" }
    1 { set kind "Node Locked, Single Player" }
    2 { set kind "Node Locked, Multi Player" }
    -1 { set kind "Floating, Single Player" }
    -2 { set kind "Floating, Multi Player" }
    -10 { set kind "Demo Mode, Queued Single" }
    -20 { set kind "Demo Mode, Queued Multi" }
    -30 { set kind "Demo Mode, Queued Any" }
    default { set kind "Unknown" }
  }

  set r [WindowLink $win.current]
  $r config -text "$kind"
}

proc SetKindOfLicense {type} {
  global KindOfLicense
  set KindOfLicense $type
  InitKeys
}


proc LicenseCode {} {
  global KindOfLicense ResourceDir KeyDir
  set kind [expr "$KindOfLicense >> 1"]
  set output "[exec $ResourceDir/licecode $ResourceDir $KeyDir $kind]"
  set code $output
  regexp {.* is: *([0-9 ]*).*} "$output" {\1} code
  if {($KindOfLicense & 1) == 0} {
    set code "$code SP"
  } else {
    set code "$code MP"
  }
  return $code
}


proc UpdateLicenseType {} {
  InitKeys
}


########################################################################
# Ask Window Handlers

proc ShowAskOf {head} {
  set win [WindowLink $head.ask]
  if {$win == {}} {
    set win [MakeWindow.ask $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
  return $win
}


proc ShowAsks {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowAskOf $win
  }
}


proc WithdrawAsks {} {
  global AskWindows
  foreach win $AskWindows {
    wm withdraw $win
  }
}


proc WithdrawAskOf {win} {
  set ask [WindowLink $win.ask]
  if {"$ask" != ""} {
    wm withdraw $ask
  }
}


proc AskQuestion {color title text left middle right} {
  global HeadWindows
  foreach win $HeadWindows {
    AskQuestionOn $win $color $title $text $left $middle $right
  }
}


proc AskQuestionOn {head color title text left middle right} {
  ShowAskOf $head

  set win [WindowLink $head.ask]
  set t [WindowLink $win.title]
  $t configure -text $title
  $t configure -background $color

  set t [WindowLink $win.text]
  $t configure -state normal
  $t delete 0.0 end
  $t insert end "${text}\n"
  $t configure -state disabled

  set bf [WindowLink $win.frame]
  set l [WindowLink $win.left]
  set m [WindowLink $win.middle]
  set r [WindowLink $win.vote]
  set rf [WindowLink $win.voteframe]

  if {$left != ""} {
    $l config \
	-text [lindex $left 0] \
	-command [format [lindex $left 2] $head]
    SetHelp $l [lindex $left 1]
    pack append $bf $l {left frame center}
  } else {
    pack unpack $l
  }

  if {$middle != ""} {
    $m config \
	-text [lindex $middle 0] \
	-command [format [lindex $middle 2] $head]
    SetHelp $m [lindex $middle 1]
    pack append $bf $m {left frame center expand}
  } else {
    pack unpack $m
  }

  if {$right != ""} {
    set notify [format [lindex $right 2] $head]
    set preview [format [lindex $right 3] $head]
    set cmd [list DoVote $win Ask $notify $preview]
    $r config \
	-text [lindex $right 0] \
	-command $cmd
    SetHelp $r [lindex $right 1]
    pack append $bf $rf {right frame center}
  } else {
    pack unpack $rf
  }

  InitVotesForAsk
}


########################################################################
# Player Window Handlers

proc ShowPlayerOf {head} {
  set win [WindowLink $head.player]
  if {$win == {}} {
    set win [MakeWindow.player $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
  return $win
}


proc ShowPlayers {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowPlayerOf $win
  }
}


proc WithdrawPlayers {} {
  global PlayerWindows
  foreach win $PlayerWindows {
    wm withdraw $win
  }
}


proc UpdatePlayers {} {
  global HeadWindows PlayerWindows

  set players ""
  foreach win $HeadWindows {
    set server [winfo server $win]
#    if {[string first : $server] == 0} {
#      set server "[exec hostname]:0"
#    }
    lappend players $server
  }

  sim Players [llength $players]

  foreach win $PlayerWindows {
    set list [WindowLink $win.players]
    $list delete 0 end
    eval "$list insert 0 $players"
  }

  UpdateVotesForUseThisMap
  UpdateVotesForAsk
  UpdateVotesForBudget
}


proc UIShowPlayer {win} {
  ShowPlayerOf $win
}


proc DoNewPlayer {win} {
  set field [WindowLink $win.display]
  set dpy [$field get]
  if {"$dpy" != ""} {
    $field delete 0 end
    sim Flush
    update idletasks
    AddPlayer $dpy
  }
}

########################################################################
# Notice Window Handlers


proc ShowNoticeOf {head} {
  set win [WindowLink $head.notice]
  if {$win == {}} {
    set win [MakeWindow.notice $head [winfo server $head]]
  }
  wm deiconify $win
  wm raise $win
  return $win
}


proc ShowNotices {} {
  global HeadWindows
  foreach win $HeadWindows {
    ShowNoticeOf $win
  }
}


proc WithdrawNotices {} {
  global NoticeWindows
  foreach win $NoticeWindows {
    wm withdraw $win
  }
}


proc ReShowPictureOn {{head ""}} {
  global ShowingPicture ShowingParms
  UIShowPictureOn $head $ShowingPicture $ShowingParms
}


proc UIShowPicture {id {parms ""}} {
  UIShowPictureOn "" $id $parms
}


proc UIShowPictureOn {where id {parms ""}} {
  global Messages ShowingPicture ShowingParms
  set ShowingPicture $id
  set ShowingParms $parms
  set msg $Messages($id)
  set color [lindex $msg 0]
  set title [lindex $msg 1]
  set body [lindex $msg 2]
  if {$parms != ""} {
    set cmd "format {$body} $parms"
    set body [uplevel #0 $cmd]
  }
  set props [lindex $msg 3]
  if {"$where" == ""} {
    global HeadWindows
    set where $HeadWindows
  }
  foreach head $where {
    NoticeMessageOn $head "$title" $color "$body" Large $props
  }
}


proc NoticeMessageOn {head title color text font props} {
  ShowNoticeOf $head
  set win [WindowLink $head.notice]

  set t [WindowLink $win.title]
  $t configure -text $title -background $color

  set t [WindowLink $win.text]
  $t configure -state normal -font [Font $head $font]
  $t delete 0.0 end
  $t insert end "${text}\n"
  $t configure -state disabled

  set left ""
  catch {set left [keylget props left]}
  set l [WindowLink $win.left]
  if {$left != ""} {
    $l config -bitmap $left
    place $l -in $t -anchor sw -relx .05 -rely .95
  } else {
    place forget $l
  }

  set middle ""
  catch {set middle [keylget props middle]}
  set m [WindowLink $win.middle]
  if {$middle != ""} {
    $m config -bitmap $middle
    place $m -in $t -anchor s -relx .5 -rely .95
  } else {
    place forget $m
  }

  set right ""
  catch {set right [keylget props right]}
  set r [WindowLink $win.right]
  if {$right != ""} {
    $r config -bitmap $right
    place $r -in $t -anchor se -relx .95 -rely .95
  } else {
    place forget $r
  }

  set view ""
  catch {set view [keylget props view]}
  set vf [WindowLink $win.viewframe]
  global v
  set v [WindowLink $win.view]
  set bg [WindowLink $win.background]
  if {$view != ""} {
    uplevel #0 "$view"
    pack unpack $t
    pack append $bg $vf {left frame center fill}
    pack append $bg $t {right frame center fill expand}
  } else {
    pack unpack $vf
  }
}

proc UIPopUpMessage {msg} {
  DoSendMessage $msg
}


proc ComeToMe {view} {
  set win [winfo toplevel $view]

  set xy [$view Pan]
  set x [expr "[lindex $xy 0] >>4"]
  set y [expr "[lindex $xy 1] >>4"]

  ComeTo $win $x $y
}


proc ComeTo {win x y} {
  global EditorWindows
  set head [WindowLink $win.head]
  set myeds {}
  set myautoeds {}
  foreach ed $EditorWindows {
    if {"[WindowLink $ed.head]" == "$head"} {
      lappend myeds $ed
      set view [WindowLink $ed.view]
      if {[$view AutoGoto] != 0} {
        lappend myautoeds $ed
      }
    }
  }
  if {[llength $myautoeds] != 0} {
    UIAutoGotoOn $x $y $myautoeds
  } else {
    if {[llength $myeds] != 0} {
      UIAutoGotoOn $x $y $myeds
    }
  }
}


proc FollowView {view id} {
  $view Follow $id

  set skips 999999
  if {[sim DoAnimation]} {
    set head [WindowLink [winfo toplevel $view].head]
    global EditorWindows
    foreach win $EditorWindows {
      if {"[WindowLink $win.head]" == "$head"} {
	set s [[WindowLink $win.view] Skip]
	set skips [min $skips $s]
      }
    }

    if {$skips == 999999} {
      set skips 0
    }
  }

  $view Skip $skips
  $view Update
}


proc PanView {view x y} {
  FollowView $view 0
  $view Pan $x $y
}


########################################################################
# Help Handler


proc HandleHelp {win x y rootx rooty} {
  global HelpWindows Messages
  set orig $win
  set head [WindowLink [winfo toplevel $win].head]
  set id ""
  while {1} {
    catch {set id $HelpWindows($win)}
    if {$id != ""} {
      break
    }
    set list [split $win .]
    set len [expr "[llength $list] - 2"]
    set list [lrange $list 0 $len]
    if {[llength $list] <= 1} {
      set id Window
      break
    }
    set win [join $list .]
  }
  if [info exists Messages($id)] {
    UIShowPictureOn $head $id 
  } else {
    UIShowPictureOn $head Window
  }
}


proc SetHelp {win id} {
  global HelpWindows
  set HelpWindows($win) $id
}


########################################################################
# Pie Menu Handlers


# Set up the bindings to pop up $pie when the right button is clicked in $win
proc InitPie {win pie} {
  bind $win <Motion> {}
  bind $win <3> "PieMenuDown $win $pie $pie Initial %X %Y"
  bind $win <B3-Motion> {}
  bind $win <B3-ButtonRelease> {}
}


# Set up the bindings to continue tracking $pie
# Get this: we keep the tracking machine state in the bindings!
proc ActivatePie {win root pie state} {
  bind $win <Motion> "PieMenuMotion $win $root $pie $state %X %Y"
  bind $win <3> "PieMenuDown $win $root $pie $state %X %Y"
  bind $win <B3-Motion> "PieMenuMotion $win $root $pie $state %X %Y"
  bind $win <B3-ButtonRelease> "PieMenuUp $win $root $pie $state %X %Y"
}


# Cancel and reset a pie menu
proc CancelPie {win} {
  set binding [bind $win <3>]
  set root [lindex $binding 2]
  set pie [lindex $binding 3]
  set state [lindex $binding 4]
  if {"$state" != "Initial"} {
    catch {$root ungrab $win}
    $pie unpost
    $pie activate none
    UIMakeSoundOn $win fancy Oop
  }
  InitPie $win $root
}


# Handle pie menu button down
proc PieMenuDown {win root pie state x y} {
  case $state {
    Initial {
      ActivatePie $win $root $pie FirstDown
      update idletasks
      catch {$root grab $win}
      $pie activate none
      $pie post $x $y
      update idletasks
    }
    ClickedUp {
      TrackPieMenu $pie $x $y
      ActivatePie $win $root $pie SecondDown
    }
    SelectedUp {
      $pie activate none
      $pie post $x $y
      $pie defer
      ActivatePie $win $root $pie SecondDown
    }
    FirstDown { # error
      CancelPie $win
    }
    SecondDown { # error
      CancelPie $win
    }
  }
}


# Handle pie menu button motion
proc PieMenuMotion {win root pie state x y} {
  case $state {
    FirstDown {
      TrackPieMenu $pie $x $y
      $pie defer
    }
    ClickedUp {
      $pie activate none
      $pie post $x $y
    }
    SecondDown {
      TrackPieMenu $pie $x $y
      $pie defer
    }
    SelectedUp {
      $pie activate none
      $pie post $x $y
    }
    Initial { # error
      CancelPie $win
    }
  }
}


# Handle pie menu button up
proc PieMenuUp {win root pie state x y} {
  case $state {
    FirstDown {
      TrackPieMenu $pie $x $y
      set active [$pie index active]
      if {$active == "none"} {
	$pie show
        catch {$root grab $win}
        ActivatePie $win $root $pie ClickedUp
      } else {
        set label [lindex [$pie entryconfig $active -label] 4]
        set submenu [lindex [$pie entryconfig $active -piemenu] 4]
	UIMakeSoundOn $win mode $label
	if {$submenu == {}} {
	  set reward [$pie pending]
	  catch {$root ungrab $win}
	  $pie unpost
          $pie activate none
          if {$reward} {
	    sim Funds [expr "[sim Funds] + 5"]
	    UIMakeSoundOn $win fancy Aaah
	  }
	  eval [lindex [$pie entryconfig $active -command] 4]
          InitPie $win $root	
	} else {
	  $pie unpost
          $pie activate none
          $submenu activate none
          $submenu post $x $y
          catch {$root grab $win}
	  ActivatePie $win $root $submenu SelectedUp
	}
      }
    }
    SecondDown {
      TrackPieMenu $pie $x $y
      set active [$pie index active]
      if {$active == "none"} {
	CancelPie $win
      } else {
        set label [lindex [$pie entryconfig $active -label] 4]
        set submenu [lindex [$pie entryconfig $active -piemenu] 4]
	UIMakeSoundOn $win mode $label
	if {$submenu == {}} {
	  set reward [$pie pending]
	  catch {$root ungrab $win}
	  $pie unpost
          $pie activate none
          if {$reward} {
	    sim Funds [expr "[sim Funds] + 5"]
	    UIMakeSoundOn $win fancy Aaah
	  }
	  eval [lindex [$pie entryconfig $active -command] 4]
	  InitPie $win $root
	} else {
	  $pie unpost
          $pie activate none
          $submenu activate none
          $submenu post $x $y
          catch {$root grab $win}
	  ActivatePie $win $root $submenu SelectedUp
	}
      }
    }
    Initial { # error
      CancelPie $win
    }
    ClickedUp { # error
      CancelPie $win
    }
    SelectedUp { # error
      CancelPie $win
    }
  }
}


# Track the selected item
proc TrackPieMenu {pie x y} {
  $pie activate @$x,$y
}


########################################################################
# Pallet Handlers


proc ExclusivePallet {state parent children prefix images inactive active cmd} {
  set i 0
  foreach child $children {
    set name [lindex $images $i]
    if {$i == $state} then {
      $parent.$child config \
	  -bitmap "@images/${prefix}${name}hi.xpm" \
	  -relief $active
    } else {
      $parent.$child config \
	  -bitmap "@images/${prefix}${name}.xpm" \
	  -relief $inactive
    }
    incr i
  }
  eval [concat $cmd $state]
}


proc NonExclusivePallet {mask parent children prefix images
			 inactive active cmd} {
  set i 0
  foreach child $children {
    set name [lindex $images $i]
    if {$mask & (1<<$i)} then {
      $parent.$child config \
	  -bitmap "@images/${prefix}${name}hi.xpm" \
	  -relief $active
    } else {
      $parent.$child config \
	  -bitmap "@images/${prefix}${name}.xpm" \
	  -relief $inactive
    }
    incr i
  }
  eval [concat $cmd $mask]
}


proc EditorPallet {win state} {
  global EditorPalletSounds
  UIMakeSoundOn $win mode [lindex $EditorPalletSounds $state]
  EditorSetTool $win $state
}


proc EditorSetTool {win state} {
  global EditorPallets
  global EditorPalletImages
  global CurrentEditorTool
  set CurrentEditorTool($win) $state
  ExclusivePallet $state $win $EditorPallets ic $EditorPalletImages \
	flat raised "$win.centerframe.view ToolState"
  EditorToolShow $win $state
}


# --- Modernised palette: hover info + status panel (added for A/UX) ---------
set EditorToolNames {
  Residential Commercial Industrial {Fire Dept} Query
  {Police Dept} {Power Line} Bulldozer Rail Road
  Chalk Eraser Stadium Park Seaport
  {Coal Power} {Nuclear Power} Airport
}
set EditorToolDescs {
  {Homes  $100} {Shops  $100} {Factories  $100}
  {$500} {Inspect}
  {$500} {$5} {Clear  $1}
  {$20} {$10}
  {Draw} {Erase} {$5000}
  {$10} {$3000}
  {$3000} {$5000} {$10000}
}

set EditorInfoWindows {}

proc EditorToolShow {win idx} {
  global EditorToolNames EditorToolDescs
  catch {
    [WindowLink $win.toolname] configure -text [lindex $EditorToolNames $idx]
    [WindowLink $win.tooldesc] configure -text [lindex $EditorToolDescs $idx]
  }
}

proc EditorToolRestore {win} {
  global CurrentEditorTool
  set idx 7
  catch {set idx $CurrentEditorTool($win)}
  EditorToolShow $win $idx
}


proc GraphPallet {win state} {
  set mask [[WindowLink $win.graphview] Mask]
  set mask [expr "$mask ^ (1<<$state)"]
  GraphPalletMask $win $mask
}


proc GraphPalletMask {win mask} {
  global GraphPallets
  global GraphPalletImages
  NonExclusivePallet $mask $win $GraphPallets gr $GraphPalletImages \
	flat flat "SetGraphState $win"
}


proc GraphYearPallet {win state} {
  global GraphYearPallets
  global GraphYearPalletImages
  ExclusivePallet $state $win $GraphYearPallets gr $GraphYearPalletImages \
	flat flat "SetGraphYearState $win"
}


proc SetGraphYearState {win state} {
  set graph [WindowLink $win.graphview]
  if {$state == 0} {
    $graph Range 10
  } else {
    $graph Range 120
  }
}


proc SetGraphState {win mask} {
  global GraphPallets
  set graph [WindowLink $win.graphview]
  $graph Mask $mask
}


########################################################################
# Button Handlers

proc sim_butEnter {w} {
  global tk_priv
  set screen [winfo server $w]
  set tk_priv(window@$screen) $w
}


proc sim_butLeave {w} {
  global tk_priv
  set screen [winfo server $w]
  set tk_priv(window@$screen) ""
}


proc sim_butDown {w} {
  global tk_priv
  set screen [winfo server $w]
  set pict [lindex [$w config -bitmap] 4]
  set tk_priv(relief@$screen) $pict
  $w config -bitmap [lindex [split $pict .] 0]hi.xpm
  update idletasks
}


proc sim_butUp {w} {
  global tk_priv
  set screen [winfo server $w]
  $w config -bitmap $tk_priv(relief@$screen)
  update idletasks
  if {$w == $tk_priv(window@$screen)} {
    uplevel #0 [list $w invoke]
  }
}


proc BindSimButton {w} {
  bind $w <Any-Enter> {sim_butEnter %W}
  bind $w <Any-Leave> {sim_butLeave %W}
  bind $w <1> {sim_butDown %W}
  bind $w <ButtonRelease-1> {sim_butUp %W}
}


########################################################################
# Internal Callbacks


proc UIStartSimCity {homedir resourcedir keydir hostname} {
  global HomeDir ResourceDir KeyDir HostName HeadWindows env
  set HomeDir $homedir
  set ResourceDir $resourcedir
  set KeyDir $keydir
  set HostName $hostname
  sim InitGame
  sim GameStarted
  update

  foreach display [sim Displays] {
    if {"[AddPlayer $display]" == ""} {
      echo Couldn't add a player on $display ...
    }
  }

  if {"$HeadWindows" == ""} {
    echo SimCity is exiting because it couldn't connect to any players.
    sim ReallyQuit
  }

  # A/UX test harness: auto-load a scenario so headless testing needs no
  # human at the picker.  Opt-in via AUXSIM_AUTOLOAD=<1-8>; selects the
  # scenario then commits it like the "Use This Map" button.  Normal play
  # is unaffected when the variable is unset.
  if {[info exists env(AUXSIM_AUTOLOAD)]} {
    set auxsim_scen $env(AUXSIM_AUTOLOAD)
    set auxsim_speed 1
    if {[info exists env(AUXSIM_SPEED)]} { set auxsim_speed $env(AUXSIM_SPEED) }
    after 4000 "catch {UILoadScenario $auxsim_scen} ; after 1500 {catch {UIUseThisMap} ; catch {sim Speed $auxsim_speed}}"
  }
}


proc UISelectCity {win} {
  AskQuestion [Color $win #ff0000 #ffffff] "Choose Another City" \
    "Do you want to abandon this city and choose another one?" \
    "{Keep playing.} SelectCity.No {RejectPlan}" \
    "" \
    "{Another city!} SelectCity.Yes {UIPickScenarioMode}"
}


proc UIQuit {head} {
  if {[sim Players] == 1} {
    set l "{Keep playing.} Quit.No {RejectPlan}"
    set m ""
    set r "{I quit!} Quit.IQuit {DoReallyQuit %s}"
  } else {
    set l "{Keep playing.} Quit.No {RejectPlan}"
    set m "{I quit!} Quit.IResign {DoIResign %s}"
    set r "{Everyone quit!} Quit.AllQuit {DoReallyQuit %s}"
  }
  AskQuestion [Color $head #ff0000 #ffffff] "Quit Playing SimCity" \
    "Do you want to quit playing SimCity?" \
    $l $m $r
}


proc DoIResign {head} {
  global VotesForAsk
  set display [winfo server $head]
  CrushHead $head
  DecRefDisplay $display
  UISetMessage "The player on X11 Display $display has resigned."
  UpdatePlayers
  if {([sim Players] == 0) ||
      ([llength $VotesForAsk] >= [sim Players])} {
    sim ReallyQuit
  }
}


proc DoReallyQuit {head} {
  sim ReallyQuit
}


proc UIPickScenarioMode {} {
  global State
  global CityLibDir
  set State scenario
  sim Pause
  WithdrawAll
  InitHistory
  UIGenerateCityNow
  InitHeads
  InitAllHeadMenus
  InitScenarios
  InitVotesForUseThisMap
  InitKeys
  ShowHeads
  ShowMaps
  DisableMaps
  ShowScenarios
  UIShowPicture 300
}


proc ForcePickScenarioMode {} {
  global State
  if {"$State" != "scenario"} {
    UIPickScenarioMode
  }
}


proc UIGenerateCityNow {} {
  global CityName GameLevel
  sim CityName NowHere
  sim GameLevel 0
  UIGenerateNewCity
}


proc UIGenerateNewCity {} {
  global CityName GameLevel
  if {$GameLevel == -1} {
    set GameLevel 0
  }
  MakeHistory "DoNewCity NowHere $GameLevel [sim Rand] [sim TreeLevel] [sim LakeLevel] [sim CurveLevel] [sim CreateIsland]"
}


proc DoNewCity {name level {r ""} {tl -1} {ll -1} {cl -1} {ci -1}} {
  global Scenario
  set Scenario -1
  sim TreeLevel $tl
  sim LakeLevel $ll
  sim CurveLevel $cl
  sim CreateIsland $ci
  if {"$r" == ""} {
    sim GenerateNewCity
  } else {
    sim GenerateSomeCity $r
  }
  sim CityName $name
  sim GameLevel $level
  UIShowPicture 25
}


proc UIDidGenerateNewCity {} {
  sim Update
}


proc IsVotingFor {win name} {
  global VotesFor$name
  set votes [eval ident "\$\{VotesFor$name\}"]
  if {[lsearch $votes $win] == -1} {
    return 0
  } else {
    return 1
  }
}


proc DoVote {win name notify preview} {
  global VotesFor$name
  set votes [eval ident "\$\{VotesFor$name\}"]

  set win [WindowLink $win.head]
  set i [lsearch $votes $win]
  if {$i == -1} {
    lappend VotesFor$name $win
  } else {
    set VotesFor$name [lreplace $votes $i $i]
  }
  UpdateVotesFor$name
  set votes [eval ident "\$\{VotesFor$name\}"]
  if {[llength $votes] >= [NeededVotes]} {
    eval "$notify"
  } else {
    eval "$preview"
  }
}


proc InitVotesForUseThisMap {} {
  global VotesForUseThisMap ScenarioWindows
  set VotesForUseThisMap {}
  foreach win $ScenarioWindows {
    [WindowLink $win.vote] config -relief raised
  }
  UpdateVotesForUseThisMap
}


proc UpdateVotesForUseThisMap {} {
  global ScenarioWindows
  UpdateVotesFor UseThisMap $ScenarioWindows
}


proc InitVotesForAsk {} {
  global VotesForAsk AskWindows
  set VotesForAsk {}
  foreach win $AskWindows {
    [WindowLink $win.vote] config -relief raised
  }
  sim PendingTool -1
  UpdateVotesForAsk
}


proc UpdateVotesForAsk {} {
  global AskWindows
  UpdateVotesFor Ask $AskWindows
}


proc ChangeBudget {} {
  global VotesForBudget
  if {"$VotesForBudget" != ""} {
    InitVotesForBudget
  }
  RestartBudgetTimer
}


proc InitVotesForBudget {} {
  global VotesForBudget BudgetWindows
  set VotesForBudget {}
  foreach win $BudgetWindows {
    [WindowLink $win.vote] config -relief raised
  }
  UpdateVotesForBudget
}


proc UpdateVotesForBudget {} {
  global BudgetWindows
  UpdateVotesFor Budget $BudgetWindows
}


proc UpdateVotesFor {name wins} {
  global VotesFor$name
  set votes [eval llength "\$\{VotesFor$name\}"]
  set needed [NeededVotes]

  foreach win $wins {
    set head [WindowLink $win.head]
    if {[IsVotingFor $head $name]} {
      set border [expr "($needed - $votes) * 2"]
      set pad [expr "12 - $border"]
      [WindowLink $win.vote] config -padx $pad -pady $pad
      [WindowLink $win.voteframe] config -borderwidth $border
    } else {
      set border [expr "($needed - $votes - 1) * 2"]
      set pad [expr "12 - $border"]
      [WindowLink $win.vote] config -padx $pad -pady $pad
      [WindowLink $win.voteframe] config -borderwidth $border
    }
  }
}


proc UIUseThisMap {} {
  global CityName GameLevel Scenario
  WithdrawAll
  # special handling for scenarios?
  if {$GameLevel != -1} {
    sim GameLevel $GameLevel
  }
  sim CityName $CityName
  UINewGame
  UIPlayGame
  if {$Scenario != -1} {
    UIShowPicture $Scenario
  }
}


proc IncRefDisplay {display} {
  global DisplayRegistry
  if ![info exists DisplayRegistry($display)] {
    set DisplayRegistry($display) 0
  }
  incr DisplayRegistry($display)
}


proc DecRefDisplay {display} {
  global DisplayRegistry
  incr DisplayRegistry($display) -1
  if {$DisplayRegistry($display) <= 0} {
    CloseDisplay $display
  }
}


proc CloseDisplay {display} {
}


proc DoStopSimCity {} {
  KillSoundServers
  destroy .
}


proc AddPlayer {display} {
  set i [string first : $display]
  if {$i == 0} {
#    set display "unix$display"
  } else {
    if {$i == -1} {
      set display "$display:0"
    }
  }

  echo Adding a player on $display ...

  set head [MakeWindow.head $display]
  if {"$head" != ""} {
    set display [winfo server $head]
    IncRefDisplay $display
    PrepHead $head
    UISetMessage "Added a player on X11 Display \"$display\"."
    UpdatePlayers
  } else {
    UISetMessage "Couldn't add a player on X11 Display \"$display\"!"
    global HeadWindows
    if {[llength $HeadWindows] != 0} {
      case [sim Type] {
	{2 -2} { }
	default {
	  UISetMessage "You need a Multi Player license!"
	  UIShowPicture 47
	  UIGetKeys
	  UIMakeSound warning Sorry
	}
      }
    }
  }
  return $head
}


proc Kaboom {} {
  if {[sim Rand] & 1} {
    eco
  } else {
    melt
  }
  sim MakeMonster
  sim MakeTornado
  sim MakeEarthquake
  UIMakeSound warning Oop {"-repeat 16"}
  UIMakeSound warning Boing {"-repeat 5"}
  after 1000 UIShowPicture 45
  after 2000 UIGetKeys
  after 3000 UIMakeSound warning Sorry
}


proc melt {} {
  sim HeatSteps 1
  sim HeatFlow -7
  sim HeatRule 0
}


proc eco {} {
  sim HeatSteps 1
  sim HeatFlow 19
  sim HeatRule 1
}


proc oops {} {
  sim HeatSteps 0
}


proc UISaveCity {win} {
  global SaveCityWin
  set SaveCityWin $win
  sim SaveCity
}


proc UISaveCityAs {{win ""}} {
  global SaveCityWin
  if {"$win" == ""} {set win $SaveCityWin}
  set SaveCityWin $win

  global CityDir
  set file [ShowFileOf $win]
  DoFileDialog $file "Save City" $CityDir "*.cty" "" \
	"UIDoReallySaveCity" ""
}


proc UIDoReallySaveCity {name path} {
  global CityDir
  if {![string match *.cty $name]} {
    set name $name.cty
  }
  set CityDir $path
  sim SaveCityAs $path/$name
}


proc UIDidSaveCity {} {
  DoSendMessage "Saved the city in \"[sim CityFileName]\"." status
}


proc UIDidntSaveCity {msg} {
  DoSendMessage $msg alert
  UIMakeSound warning Sorry "-speed 85"
}


proc UILoadScenario {scen} {
  MakeHistory "DoScenario $scen"
}


proc DoScenario {scen} {
  global Scenario
  set Scenario $scen
  sim LoadScenario $scen
  UIShowPicture $scen
}


proc UIDidLoadScenario {} {
}


proc UIStartScenario {id} {
  global Scenario
  set Scenario $id
  UILoadScenario $id
  UIPlayGame
  UIShowPicture $id
}


proc UIPlayNewCity {} {
  UIGenerateNewCity
  UIPlayGame
}


proc UIStartLoad {} {
  UIPlayGame
}


proc UIReallyStartGame {} {
  UIPickScenarioMode
}


proc UIPlayGame {} {
  global State
  set State play
  sim Resume
  sim Speed 3
  sim AutoGoto 1
  InitHeads
  InitAllHeadMenus
  ShowInitial
}


proc UISetSpeed {speed} {
  global Time State
  set Time $speed
  if {"$State" == "play"} {
    UISetMessage [lindex {
      {Time pauses.}
      {Time flows slow.}
      {Time flows medium.}
      {Time flows fast.}
    } $speed]
  }
}


proc DoSetGameLevel {level} {
  sim GameLevel $level
}


proc UISetGameLevel {level} {
  global GameLevel
  set GameLevel $level
}


proc UISetCityName {name} {
  global EditorWindows
  global CityName
  set CityName $name
  set title "SimCity Editor on $name"
  foreach win $EditorWindows {
    wm title $win "$title"
    wm iconname $win "$title"
  }
}


proc UILoadCity {win} {
  # if changed, r-u-sure?
  global CityDir
  set file [ShowFileOf $win]
  DoFileDialog $file "Load City" $CityDir "*.cty" "" \
	"UIDoLoadCity" ""
}


proc UIDoLoadCity {name path} {
  global CityDir
  set CityDir $path
  if {![string match *.cty $name]} {
    set name $name.cty
  }
  MakeHistory "DoLoadCity $path/$name"
}


proc DoLoadCity {filename} {
  sim LoadCity $filename
}

proc UIDidLoadCity {} {
  global State GameLevel Scenario
  set Scenario -1
  set GameLevel -1
  if {$State == "play"} {
    UIPlayGame
  } else {
    UIShowPicture 26 [sim CityFileName]
  }
}


proc UIDidntLoadCity {msg} {
  DoSendMessage $msg alert
  UIMakeSound warning Sorry "-speed 85"
  UIShowPicture 26 [sim CityFileName]
  sim Fill 0
  sim UpdateMaps
}


proc UINewGame {} {
  global OldBudget
  set OldBudget 0
  sim InitGame
  sim EraseOverlay
  InitEditors
  InitMaps
  InitGraphs
  update
  sim UpdateMaps
}


proc UIDidPan {w x y} {
  if {[$w ToolMode] == 1} {
    EditorToolDrag $w $x $y
  }
  update idletasks
}


proc UIDidStopPan {win} {
  UIMakeSoundOn $win fancy Skid "-volume 25"
  $win TweakCursor
}


proc UIEarthQuake {} {
}


proc UIAutoGoto {x y {except {}}} {
  global EditorWindows
  set x [expr "$x * 16 + 8"]
  set y [expr "$y * 16 + 8"]
  foreach win $EditorWindows {
    if {"$win" != "$except"} {
      set view [WindowLink $win.view]
      if {[$view AutoGoto] != 0} {
        $view AutoGoal $x $y
      }
    }
  }
  sim UpdateMaps
}


proc UIAutoGotoOn {x y eds} {
  set x [expr "$x * 16 + 8"]
  set y [expr "$y * 16 + 8"]
  foreach win $eds {
    [WindowLink $win.view] AutoGoal $x $y
  }
  sim UpdateMaps
}


proc DoLeaveGame {head} {
}


proc UILoseGame {} {
  UIPickScenarioMode
  UIShowPicture 200
}


proc DoPendTool {view tool x y} {
  global HeadWindows ToolInfo VotesForAsk

  set win [WindowLink $view.top]
  set head [WindowLink $win.head]

  if {($tool == [sim PendingTool]) &&
      ($x == [sim PendingX]) &&
      ($y == [sim PendingY])} {
    if {[lsearch $VotesForAsk $head] != -1} {
      # you can only vote once
      UIMakeSound edit Oop
    } else {
      UIMakeSound edit Boing
      set ask [WindowLink $head.ask]
      PressVoteButton $ask [WindowLink $ask.vote] Ask
    }
  } else {
    UIAutoGoto $x $y $win

    UIMakeSound edit Boing
    set info [lindex $ToolInfo $tool]
    set a [lindex $info 0]
    set name [lindex $info 1]
    set cost [lindex $info 2]
    set title "Build $a $name"
    set question "Do you support the plan to build $a $name for $cost?"
    AskQuestion [Color $win #00ff00 #ffffff] "$title" \
	"$question" \
	"{Veto plan.} Plan.Dismiss
	   {RejectPlan}" \
	"{Goto plan.} Plan.Dismiss
	   {ComeTo %s $x $y}" \
	"{Support plan!} Plan.Support
	   {SupportPlan $view %s $tool $x $y}
	   {PreviewSupportPlan $view %s $tool $x $y}"
    set VotesForAsk $head
    set ask [WindowLink $head.ask]
    [WindowLink $ask.vote] config -relief sunken

    UpdateVotesForAsk

    sim PendingTool $tool
    sim PendingX $x
    sim PendingY $y
    sim Votes [llength $VotesForAsk]
  }
}


proc RejectPlan {} {
  sim PendingTool -1
  if {[sim Players] > 1} {
    UIMakeSound edit Sorry
  }
  WithdrawAsks
}


proc NeededVotes {} {
  global FreeVotes
  set players [sim Players]
  set needed [expr "$players - $FreeVotes"]
  return [max 0 $needed]
}


proc SupportPlan {view h tool x y} {
  global VotesForAsk
  sim Votes [llength $VotesForAsk]
  sim PendingTool -1
  sim OverRide 1
  $view DoTool $tool $x $y
  sim OverRide 0
  WithdrawAsks
  UIMakeSound edit Aaah
}


proc PreviewSupportPlan {view h tool x y} {
  global VotesForAsk
  sim Votes [llength $VotesForAsk]
}
