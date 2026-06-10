  global EditorWindows
  set n [Unique]
  set win .editor$n
  set EditorWindows [linsert $EditorWindows 0 $win] 

  global Skip.$win
  set Skip.$win 0
  global AutoGoto.$win
  set AutoGoto.$win 0
  global Controls.$win
  set Controls.$win 1
  global Overlay.$win
  set Overlay.$win 0

  LinkWindow $head.editor $win
  LinkWindow $win.head $head

  catch "destroy $win"
  toplevel $win -screen $display

  SetHelp $win Window

  bind $win <Visibility> {[WindowLink %W.view] Visible [string compare %s FullyObscured]}
  bind $win <Map> {[WindowLink %W.view] Visible 1}
  bind $win <Unmap> {[WindowLink %W.view] Visible 0}
  # $head.editor points to most recently created or entered editor
  bind $win <Enter> "LinkWindow $head.editor $win"

  global CityName
  wm title $win "SimCity Editor"
  wm iconname $win $CityName
  wm group $win $head
  wm geometry $win 550x535+440+5
  wm positionfrom $win user
  wm withdraw $win
  wm maxsize $win 2000 2000
  wm minsize $win 32 32
  wm protocol $win delete "DeleteWindow editor EditorWindows"

  frame $win.topframe\
    -borderwidth 0

  frame $win.topframe.controls\
    -borderwidth 2\
    -relief raised

  # ================= consolidated menu bar (from the Controls window) =========

  # ---- File ----
  menubutton $win.topframe.controls.file\
    -menu $win.topframe.controls.file.m -text {File}\
    -font [Font $win Medium] -variable $win.postedMenu -borderwidth 2 -relief flat
  tk_bindForTraversal $win.topframe.controls.file
  bind $win.topframe.controls.file <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.file <Mod2-Key> {tk_traverseToMenu %W %A}
  tk_menus $win $win.topframe.controls.file
  menu $win.topframe.controls.file.m -font [Font $win Medium]
  tk_bindForTraversal $win.topframe.controls.file.m
  bind $win.topframe.controls.file.m <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.file.m <Mod2-Key> {tk_traverseToMenu %W %A}
    $win.topframe.controls.file.m add command -label {Save City} -command "UISaveCity $head"
    $win.topframe.controls.file.m add command -label {Save City as...} -command "UISaveCityAs $head"
    $win.topframe.controls.file.m add command -label {Another City!} -command "UISelectCity $head"
    $win.topframe.controls.file.m add separator
    $win.topframe.controls.file.m add command -label {Add Player...} -command "UIShowPlayer $head"
    $win.topframe.controls.file.m add command -label {Get Key...} -command "UIGetKey $head"
    $win.topframe.controls.file.m add separator
    $win.topframe.controls.file.m add command -label {Quit Playing!} -command "UIQuit $head"

  # ---- Options ----
  menubutton $win.topframe.controls.options\
    -menu $win.topframe.controls.options.m -text {Options}\
    -font [Font $win Medium] -variable $win.postedMenu -borderwidth 2 -relief flat
  tk_bindForTraversal $win.topframe.controls.options
  bind $win.topframe.controls.options <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.options <Mod2-Key> {tk_traverseToMenu %W %A}
  tk_menus $win $win.topframe.controls.options
  menu $win.topframe.controls.options.m -font [Font $win Medium]
  tk_bindForTraversal $win.topframe.controls.options.m
  bind $win.topframe.controls.options.m <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.options.m <Mod2-Key> {tk_traverseToMenu %W %A}
    $win.topframe.controls.options.m add checkbutton -label {Auto Budget} -variable AutoBudget -command {sim AutoBudget $AutoBudget}
    $win.topframe.controls.options.m add checkbutton -label {Auto Bulldoze} -variable AutoBulldoze -command {sim AutoBulldoze $AutoBulldoze}
    $win.topframe.controls.options.m add checkbutton -label {Disasters} -variable Disasters -command {sim Disasters $Disasters}
    $win.topframe.controls.options.m add checkbutton -label {Sound} -variable Sound -command {sim Sound $Sound}
    $win.topframe.controls.options.m add checkbutton -label {Animation} -variable DoAnimation -command {sim DoAnimation $DoAnimation}
    $win.topframe.controls.options.m add separator
    $win.topframe.controls.options.m add checkbutton -label {Auto Goto} -variable AutoGoto.$win -command "SetEditorAutoGoto $win \$\{AutoGoto.$win\}"
    $win.topframe.controls.options.m add checkbutton -label {Palette Panel} -variable Controls.$win -command "SetEditorControls $win \$\{Controls.$win\}"
    $win.topframe.controls.options.m add checkbutton -label {Chalk Overlay} -variable Overlay.$win -command "SetEditorOverlay $win \$\{Overlay.$win\}"
    $win.topframe.controls.options.m add separator
    $win.topframe.controls.options.m add radiobutton -label {Redraw: Always} -variable Skip.$win -value 0 -command "SetEditorSkip $win 0"
    $win.topframe.controls.options.m add radiobutton -label {Redraw: Often} -variable Skip.$win -value 1 -command "SetEditorSkip $win 1"
    $win.topframe.controls.options.m add radiobutton -label {Redraw: Sometimes} -variable Skip.$win -value 2 -command "SetEditorSkip $win 4"
    $win.topframe.controls.options.m add radiobutton -label {Redraw: Seldom} -variable Skip.$win -value 3 -command "SetEditorSkip $win 16"
    $win.topframe.controls.options.m add radiobutton -label {Redraw: Rarely} -variable Skip.$win -value 4 -command "SetEditorSkip $win 64"

  # ---- Speed ----
  menubutton $win.topframe.controls.speed\
    -menu $win.topframe.controls.speed.m -text {Speed}\
    -font [Font $win Medium] -variable $win.postedMenu -borderwidth 2 -relief flat
  tk_bindForTraversal $win.topframe.controls.speed
  bind $win.topframe.controls.speed <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.speed <Mod2-Key> {tk_traverseToMenu %W %A}
  tk_menus $win $win.topframe.controls.speed
  menu $win.topframe.controls.speed.m -font [Font $win Medium]
  tk_bindForTraversal $win.topframe.controls.speed.m
  bind $win.topframe.controls.speed.m <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.speed.m <Mod2-Key> {tk_traverseToMenu %W %A}
    $win.topframe.controls.speed.m add radiobutton -label {Pause} -value {0} -variable Time -command {sim Speed 0}
    $win.topframe.controls.speed.m add radiobutton -label {Slow} -value {1} -variable Time -command {sim Speed 1}
    $win.topframe.controls.speed.m add radiobutton -label {Medium} -value {2} -variable Time -command {sim Speed 2}
    $win.topframe.controls.speed.m add radiobutton -label {Fast} -value {3} -variable Time -command {sim Speed 3}
    $win.topframe.controls.speed.m add separator
    $win.topframe.controls.speed.m add radiobutton -label {Priority: Flat Out!} -value {7} -variable Priority -command {sim Delay 2}
    $win.topframe.controls.speed.m add radiobutton -label {Priority: Zoom Zoom} -value {6} -variable Priority -command {sim Delay 25}
    $win.topframe.controls.speed.m add radiobutton -label {Priority: Buzz Buzz} -value {5} -variable Priority -command {sim Delay 100}
    $win.topframe.controls.speed.m add radiobutton -label {Priority: Putter Putter} -value {2} -variable Priority -command {sim Delay 250}
    $win.topframe.controls.speed.m add radiobutton -label {Priority: Snore Snore} -value {0} -variable Priority -command {sim Delay 1000}

  # ---- Disasters ----
  menubutton $win.topframe.controls.disasters\
    -menu $win.topframe.controls.disasters.m -text {Disasters}\
    -font [Font $win Medium] -variable $win.postedMenu -borderwidth 2 -relief flat
  tk_bindForTraversal $win.topframe.controls.disasters
  bind $win.topframe.controls.disasters <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.disasters <Mod2-Key> {tk_traverseToMenu %W %A}
  tk_menus $win $win.topframe.controls.disasters
  menu $win.topframe.controls.disasters.m -font [Font $win Medium]
  tk_bindForTraversal $win.topframe.controls.disasters.m
  bind $win.topframe.controls.disasters.m <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.disasters.m <Mod2-Key> {tk_traverseToMenu %W %A}
    $win.topframe.controls.disasters.m add command -label {Monster} -command {sim MakeMonster}
    $win.topframe.controls.disasters.m add command -label {Fire} -command {sim MakeFire}
    $win.topframe.controls.disasters.m add command -label {Flood} -command {sim MakeFlood}
    $win.topframe.controls.disasters.m add command -label {Meltdown} -command {sim MakeMeltdown}
    $win.topframe.controls.disasters.m add command -label {Air Crash} -command {sim MakeAirCrash}
    $win.topframe.controls.disasters.m add command -label {Tornado} -command {sim MakeTornado}
    $win.topframe.controls.disasters.m add command -label {Earthquake} -command {sim MakeEarthquake}

  # ---- Windows ----
  menubutton $win.topframe.controls.windows\
    -menu $win.topframe.controls.windows.m -text {Windows}\
    -font [Font $win Medium] -variable $win.postedMenu -borderwidth 2 -relief flat
  tk_bindForTraversal $win.topframe.controls.windows
  bind $win.topframe.controls.windows <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.windows <Mod2-Key> {tk_traverseToMenu %W %A}
  tk_menus $win $win.topframe.controls.windows
  menu $win.topframe.controls.windows.m -font [Font $win Medium]
  tk_bindForTraversal $win.topframe.controls.windows.m
  bind $win.topframe.controls.windows.m <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.windows.m <Mod2-Key> {tk_traverseToMenu %W %A}
    $win.topframe.controls.windows.m add command -label {Budget} -command "UIShowBudgetAndWait"
    $win.topframe.controls.windows.m add command -label {Evaluation} -command "ShowEvaluationOf $head"
    $win.topframe.controls.windows.m add command -label {Graph} -command "ShowGraphOf $head"
    $win.topframe.controls.windows.m add command -label {Map} -command "ShowMapOf $head"
    $win.topframe.controls.windows.m add command -label {Editor} -command "ShowEditorOf $head"
    $win.topframe.controls.windows.m add separator
    $win.topframe.controls.windows.m add command -label {Map Copy} -command "NewMapOf $head"
    $win.topframe.controls.windows.m add command -label {Editor Copy} -command "NewEditorOf $head"

  # ---- Help ----
  menubutton $win.topframe.controls.help\
    -menu $win.topframe.controls.help.m -text {Help}\
    -font [Font $win Medium] -variable $win.postedMenu -borderwidth 2 -relief flat
  tk_bindForTraversal $win.topframe.controls.help
  bind $win.topframe.controls.help <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.help <Mod2-Key> {tk_traverseToMenu %W %A}
  tk_menus $win $win.topframe.controls.help
  menu $win.topframe.controls.help.m -font [Font $win Medium]
  tk_bindForTraversal $win.topframe.controls.help.m
  bind $win.topframe.controls.help.m <F10> {tk_firstMenu %W}
  bind $win.topframe.controls.help.m <Mod2-Key> {tk_traverseToMenu %W %A}
    $win.topframe.controls.help.m add command -label {About...} -command "UIShowPicture 300"

  pack append $win.topframe.controls\
    $win.topframe.controls.file {left frame nw}\
    $win.topframe.controls.options {left frame nw}\
    $win.topframe.controls.speed {left frame nw}\
    $win.topframe.controls.disasters {left frame nw}\
    $win.topframe.controls.windows {left frame nw}\
    $win.topframe.controls.help {left frame nw}

  pack append $win.topframe\
    $win.topframe.controls	{top frame nw fillx}

  frame $win.centerframe\
    -cursor hand2\
    -borderwidth 2\
    -relief sunken

  editorview $win.centerframe.view\
    -font [Font $win Big]
  LinkWindow $win.view $win.centerframe.view
  LinkWindow $win.centerframe.view.top $win

  BindEditorButtons $win.centerframe.view

  bind $win.centerframe.view <Any-Enter> {focus %W}

  set entry [WindowLink $head.entry]
  bind $win.centerframe.view <Any-KeyPress> "
      if {\"%A\" != \"\"} {
	  $entry insert cursor %A
	  tk_entrySeeCaret $entry
      }
  "

  bind $win.centerframe.view <Delete> "tk_entryDelPress $entry"
  bind $win.centerframe.view <BackSpace> "tk_entryDelPress $entry"
  bind $win.centerframe.view <Control-h> "tk_entryDelPress $entry"
  bind $win.centerframe.view <Control-d> "tk_textCutPress $entry"
  bind $win.centerframe.view <Control-u> "tk_entryDelLine $entry"
  bind $win.centerframe.view <Control-v> "tk_entryCopyPress $entry"
  bind $win.centerframe.view <Control-w> "tk_entryBackword $entry; tk_entrySeeCaret $entry"
  bind $win.centerframe.view <Return> "DoEnterMessage $entry $entry.value"
  bind $win.centerframe.view <Escape> "DoEvalMessage $entry $entry.value"

  bind $win.centerframe.view <Up> "%W PanBy 0 16 ; %W TweakCursor"
  bind $win.centerframe.view <Down> "%W PanBy 0 -16 ; %W TweakCursor"
  bind $win.centerframe.view <Left> "%W PanBy 16 0 ; %W TweakCursor"
  bind $win.centerframe.view <Right> "%W PanBy -16 0 ; %W TweakCursor"
  bind $win.centerframe.view <Tab> "EditorToolDown none %W %x %y ; EditorToolUp %W %x %y"

  bind $win.centerframe.view <Meta-KeyPress> {EditorKeyDown %W %K}
  bind $win.centerframe.view <Meta-KeyRelease> {EditorKeyUp %W %K}
  bind $win.centerframe.view <Shift-Meta-KeyPress> {EditorKeyDown %W %K}
  bind $win.centerframe.view <Shift-Meta-KeyRelease> {EditorKeyUp %W %K}

  pack append $win.centerframe\
    $win.centerframe.view {top frame center fill expand}

  frame $win.leftframe\
    -borderwidth 2\
    -relief raised\
    -geometry 88x10

  frame $win.leftframe.tools\
    -borderwidth 0\
    -relief flat

  label $win.leftframe.tools.costlabel1\
    -relief flat\
    -font [Font $win Medium]\
    -text {}
  LinkWindow $win.cost1 $win.leftframe.tools.costlabel1
  LinkWindow $win.centerframe.view.cost1 $win.leftframe.tools.costlabel1

  label $win.leftframe.tools.costlabel2\
    -relief flat\
    -font [Font $win Medium]\
    -text {}
  LinkWindow $win.cost2 $win.leftframe.tools.costlabel2
  LinkWindow $win.centerframe.view.cost2 $win.leftframe.tools.costlabel2

  frame $win.leftframe.tools.r0 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r0.palletres\
    -bitmap "@images/icres.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 0"
  button $win.leftframe.tools.r0.palletcom\
    -bitmap "@images/iccom.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 1"
  pack append $win.leftframe.tools.r0 $win.leftframe.tools.r0.palletres {left frame nw} $win.leftframe.tools.r0.palletcom {left frame nw}

  frame $win.leftframe.tools.r1 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r1.palletind\
    -bitmap "@images/icind.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 2"
  button $win.leftframe.tools.r1.palletpolice\
    -bitmap "@images/icpol.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 5"
  pack append $win.leftframe.tools.r1 $win.leftframe.tools.r1.palletind {left frame nw} $win.leftframe.tools.r1.palletpolice {left frame nw}

  frame $win.leftframe.tools.r2 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r2.palletfire\
    -bitmap "@images/icfire.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 3"
  button $win.leftframe.tools.r2.palletquery\
    -bitmap "@images/icqry.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 4"
  pack append $win.leftframe.tools.r2 $win.leftframe.tools.r2.palletfire {left frame nw} $win.leftframe.tools.r2.palletquery {left frame nw}

  frame $win.leftframe.tools.r3 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r3.palletroad\
    -bitmap "@images/icroad.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 9"
  button $win.leftframe.tools.r3.palletrail\
    -bitmap "@images/icrail.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 8"
  pack append $win.leftframe.tools.r3 $win.leftframe.tools.r3.palletroad {left frame nw} $win.leftframe.tools.r3.palletrail {left frame nw}

  frame $win.leftframe.tools.r4 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r4.palletwire\
    -bitmap "@images/icwire.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 6"
  button $win.leftframe.tools.r4.palletcoal\
    -bitmap "@images/iccoal.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 15"
  pack append $win.leftframe.tools.r4 $win.leftframe.tools.r4.palletwire {left frame nw} $win.leftframe.tools.r4.palletcoal {left frame nw}

  frame $win.leftframe.tools.r5 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r5.palletnuclear\
    -bitmap "@images/icnuc.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 16"
  button $win.leftframe.tools.r5.palletpark\
    -bitmap "@images/icpark.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 13"
  pack append $win.leftframe.tools.r5 $win.leftframe.tools.r5.palletnuclear {left frame nw} $win.leftframe.tools.r5.palletpark {left frame nw}

  frame $win.leftframe.tools.r6 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r6.palletstadium\
    -bitmap "@images/icstad.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 12"
  button $win.leftframe.tools.r6.palletseaport\
    -bitmap "@images/icseap.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 14"
  pack append $win.leftframe.tools.r6 $win.leftframe.tools.r6.palletstadium {left frame nw} $win.leftframe.tools.r6.palletseaport {left frame nw}

  frame $win.leftframe.tools.r7 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r7.palletairport\
    -bitmap "@images/icairp.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 17"
  button $win.leftframe.tools.r7.palletbulldozer\
    -bitmap "@images/icdozr.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 7"
  pack append $win.leftframe.tools.r7 $win.leftframe.tools.r7.palletairport {left frame nw} $win.leftframe.tools.r7.palletbulldozer {left frame nw}

  frame $win.leftframe.tools.r8 -borderwidth 0 -relief flat
  button $win.leftframe.tools.r8.palletchalk\
    -bitmap "@images/icchlk.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 10"
  button $win.leftframe.tools.r8.palleteraser\
    -bitmap "@images/icersr.xpm"\
    -width 36 -height 36 -borderwidth 1 -relief flat -padx 0 -pady 0 -text {} -cursor hand2\
    -command "EditorPallet $win 11"
  pack append $win.leftframe.tools.r8 $win.leftframe.tools.r8.palletchalk {left frame nw} $win.leftframe.tools.r8.palleteraser {left frame nw}

  pack append $win.leftframe.tools \
    $win.leftframe.tools.r0	{top frame nw} \
    $win.leftframe.tools.r1	{top frame nw} \
    $win.leftframe.tools.r2	{top frame nw} \
    $win.leftframe.tools.r3	{top frame nw} \
    $win.leftframe.tools.r4	{top frame nw} \
    $win.leftframe.tools.r5	{top frame nw} \
    $win.leftframe.tools.r6	{top frame nw} \
    $win.leftframe.tools.r7	{top frame nw} \
    $win.leftframe.tools.r8	{top frame nw}


  # --- status panel + hover info (added for A/UX) ---
  # fixed-size status panel (frame -width/-height is honored here; the labels are
  # place'd so changing their text on hover cannot resize the panel -> no reflow,
  # so the packed tool buttons never shift out from under the cursor).
  frame $win.leftframe.status\
    -borderwidth 2 -relief sunken -width 84 -height 34
  label $win.leftframe.status.name\
    -font [Font $win Small] -text {Bulldozer} -anchor w
  label $win.leftframe.status.desc\
    -font [Font $win Tiny] -text {Clear  $1} -anchor w
  LinkWindow $win.toolname $win.leftframe.status.name
  LinkWindow $win.tooldesc $win.leftframe.status.desc
  place $win.leftframe.status.name -x 3 -y 2
  place $win.leftframe.status.desc -x 3 -y 18

  foreach pair {
    {r0.palletres 0} {r0.palletcom 1} {r1.palletind 2} {r2.palletfire 3} {r2.palletquery 4} {r1.palletpolice 5} {r4.palletwire 6} {r7.palletbulldozer 7} {r3.palletrail 8} {r3.palletroad 9} {r8.palletchalk 10} {r8.palleteraser 11} {r6.palletstadium 12} {r5.palletpark 13} {r6.palletseaport 14} {r4.palletcoal 15} {r5.palletnuclear 16} {r7.palletairport 17}
  } {
    set hb $win.leftframe.tools.[lindex $pair 0]
    set hi [lindex $pair 1]
    # In this old Tk an instance binding REPLACES the widget's class binding, so
    # we must call the button's own tk_butEnter/tk_butLeave (which maintain the
    # armed-state used by tk_butUp to fire -command) before our status update -
    # otherwise clicks stop invoking the command after the first hover.
    bind $hb <Enter> "tk_butEnter %W ; EditorToolShow $win $hi"
    bind $hb <Leave> "tk_butLeave %W ; EditorToolRestore $win"
  }

  # RCI demand gauge below the buttons (mirrors the head window's indicator;
  # UISetDemand updates this editor copy too via EditorInfoWindows/$win.edemand).
  canvas $win.leftframe.demand\
    -scrollincrement 0\
    -borderwidth 0\
    -background #D0D0D0\
    -width 84 -height 68
  LinkWindow $win.edemand $win.leftframe.demand
  $win.leftframe.demand create bitmap 0 0\
    -tags picture\
    -bitmap "@images/rcigauge.xpm"\
    -anchor nw
  $win.leftframe.demand create rectangle -10 -10 1 1\
    -tags r\
    -fill [Color $win #00ff00 #000000]
  $win.leftframe.demand create rectangle -10 -10 1 1\
    -tags c\
    -fill [Color $win #0000ff #000000]
  $win.leftframe.demand create rectangle -10 -10 1 1\
    -tags i\
    -fill [Color $win #ffff00 #000000]

  # date/funds now live in the top strip; register this editor so UISetFunds /
  # UISetDate / UISetDemand update those linked widgets ($win.efunds/edate/edemand).
  global EditorInfoWindows
  lappend EditorInfoWindows $win

  pack append $win.leftframe\
    $win.leftframe.tools	{top frame center}\
    $win.leftframe.demand	{top frame center}\
    $win.leftframe.status	{bottom frame center fillx}

  # ---- bottom status bar: date | funds | notification message ----
  frame $win.statusbar\
    -borderwidth 2 -relief raised
  label $win.statusbar.date\
    -borderwidth 1 -relief sunken -font [Font $win Medium] -text {} -anchor w -width 12
  LinkWindow $win.edate $win.statusbar.date
  label $win.statusbar.funds\
    -borderwidth 1 -relief sunken -font [Font $win Medium] -text {} -anchor w -width 16
  LinkWindow $win.efunds $win.statusbar.funds
  label $win.statusbar.message\
    -borderwidth 1 -relief sunken -font [Font $win Medium] -text {} -anchor w
  LinkWindow $win.message $win.statusbar.message
  pack append $win.statusbar\
    $win.statusbar.date	{left frame w filly}\
    $win.statusbar.funds	{left frame w filly}\
    $win.statusbar.message	{left frame w expand fill}

  pack append $win\
    $win.topframe	{top frame center fillx} \
    $win.statusbar	{bottom frame center fillx} \
    $win.centerframe	{right frame center expand fill} \
    $win.leftframe	{left frame center filly} 

  global ShapePies

  piemenu $win.toolpie\
      -title Tool\
      -font [Font $win Medium]\
      -fixedradius 26\
      -shaped $ShapePies\
      -preview "UIMakeSoundOn $head fancy Woosh {-volume 40}"
    $win.toolpie add command\
      -label Road -bitmap "@images/icroadhi.xpm"\
      -xoffset -4\
      -command "EditorSetTool $win 9"
    $win.toolpie add command\
      -label Bulldozer -bitmap "@images/icdozrhi.xpm"\
      -xoffset 5 -yoffset 17\
      -command "EditorSetTool $win 7"
    $win.toolpie add piemenu\
      -font [Font $win Medium]\
      -label Zone -piemenu $win.zonepie 
    $win.toolpie add command\
      -label Wire -bitmap "@images/icwirehi.xpm"\
      -xoffset -4 -yoffset 17\
      -command "EditorSetTool $win 6"
    $win.toolpie add command\
      -label Rail -bitmap "@images/icrailhi.xpm"\
      -xoffset 4\
      -command "EditorSetTool $win 8"
    $win.toolpie add command\
      -label Chalk -bitmap "@images/icchlkhi.xpm"\
      -xoffset -4 -yoffset -17\
      -command "EditorSetTool $win 10"
    $win.toolpie add piemenu\
      -font [Font $win Medium]\
      -label Build -piemenu $win.buildpie
    $win.toolpie add command\
      -label Eraser -bitmap "@images/icersrhi.xpm"\
      -xoffset 4 -yoffset -17\
      -command "EditorSetTool $win 11"

  piemenu $win.zonepie\
      -title Zone\
      -font [Font $win Medium]\
      -shaped $ShapePies\
      -initialangle 270 -fixedradius 20
    $win.zonepie add command\
      -label Query -bitmap "@images/icqryhi.xpm"\
      -yoffset 5\
      -command "EditorSetTool $win 4"
    $win.zonepie add command\
      -label Police -bitmap "@images/icpolhi.xpm"\
      -xoffset 4 -yoffset -10\
      -command "EditorSetTool $win 5"
    $win.zonepie add command\
      -label Ind -bitmap "@images/icindhi.xpm"\
      -xoffset 4 -yoffset 25\
      -command "EditorSetTool $win 2"
    $win.zonepie add command\
      -label Com -bitmap "@images/iccomhi.xpm"\
      -yoffset -5\
      -command "EditorSetTool $win 1"
    $win.zonepie add command\
      -label Res -bitmap "@images/icreshi.xpm"\
      -xoffset -4 -yoffset 25\
      -command "EditorSetTool $win 0"
    $win.zonepie add command\
      -label Fire -bitmap "@images/icfirehi.xpm"\
      -xoffset -4 -yoffset -10\
      -command "EditorSetTool $win 3"

  piemenu $win.buildpie\
      -title Build\
      -font [Font $win Medium]\
      -shaped $ShapePies\
      -initialangle 270 -fixedradius 25
    $win.buildpie add command\
      -label Airport -bitmap "@images/icairphi.xpm"\
      -yoffset 7\
      -command "EditorSetTool $win 17"
    $win.buildpie add command\
      -label Nuclear -bitmap "@images/icnuchi.xpm"\
      -xoffset 11 -yoffset -10\
      -command "EditorSetTool $win 16"
    $win.buildpie add command\
      -label Seaport -bitmap "@images/icseaphi.xpm"\
      -xoffset 0 -yoffset 14\
      -command "EditorSetTool $win 14"
    $win.buildpie add command\
      -label Park -bitmap "@images/icparkhi.xpm"\
      -yoffset -5\
      -command "EditorSetTool $win 13"
    $win.buildpie add command\
      -label Stadium -bitmap "@images/icstadhi.xpm"\
      -xoffset 0 -yoffset 14\
      -command "EditorSetTool $win 12"
    $win.buildpie add command\
      -label Coal -bitmap "@images/iccoalhi.xpm"\
      -xoffset -11 -yoffset -10\
      -command "EditorSetTool $win 15"

  SetEditorAutoGoto $win 0
  SetEditorControls $win 1
  SetEditorOverlay $win 1

  InitEditor $win

  global CityName
  UISetCityName $CityName

  update idletasks
  return $win
