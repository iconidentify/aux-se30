  global HeadWindows
  set n [Unique]
  set win .head$n

  catch "destroy $win"
  if {[catch "toplevel $win -screen $display"]} {
    puts stderr "Couldn't open X11 display \"$display\"."
    return ""
  }

  set visual [winfo screenvisual $win]
  set depth [winfo screendepth $win]
  if {!(("$visual" == "pseudocolor") ||
        (("$visual" == "staticgray") &&
         ($depth == 1)))} {
    catch "destroy $win"
    puts stderr "SimCity can't find an 8 bit color or 1 bit monochrome display on \"$display\"."
    return ""
  }

  set HeadWindows [linsert $HeadWindows 0 $win]

  SetHelp $win Window

  LinkWindow $win.head $win
  LinkWindow $win.editor {}
  LinkWindow $win.map {}
  LinkWindow $win.graph {}
  LinkWindow $win.budget {}
  LinkWindow $win.evaluation {}
  LinkWindow $win.scenario {}
  LinkWindow $win.file {}
  LinkWindow $win.config {}
  LinkWindow $win.notice {}
  LinkWindow $win.ask {}

  tk_bindForTraversal $win
  bind $win <F10> {tk_firstMenu %W} 
  bind $win <Mod2-Key> {tk_traverseToMenu %W %A} 


  wm title $win {SimCity Messages}
  wm iconname $win {Messages}
  wm geometry $win 400x240+5+5
  wm positionfrom $win user
  wm withdraw $win
  wm maxsize $win 2000 2000
  wm minsize $win 50 50
  # chat/messages window: closing it just hides it (Windows > Messages reopens);
  # the game is quit from the editor's File > Quit Playing.
  wm protocol $win delete "wm withdraw $win"

  global $win.postedMenu
  global $win.Sound

  frame $win.f1\
    -borderwidth 2\
    -relief raised
  tk_bindForTraversal $win.f1
  bind $win.f1 <F10> {tk_firstMenu %W} 
  bind $win.f1 <Mod2-Key> {tk_traverseToMenu %W %A} 

  SetHelp $win.f1.simcity SimCityMenu

  menubutton $win.f1.simcity\
    -menu $win.f1.simcity.m\
    -text {SimCity}\
    -font [Font $win Medium]\
    -variable $win.postedMenu
  tk_bindForTraversal $win.f1.simcity
  bind $win.f1.simcity <F10> {tk_firstMenu %W} 
  bind $win.f1.simcity <Mod2-Key> {tk_traverseToMenu %W %A} 

  tk_menus $win $win.f1.simcity

  menu $win.f1.simcity.m\
    -font [Font $win Medium]
  tk_bindForTraversal $win.f1.simcity.m
  bind $win.f1.simcity.m <F10> {tk_firstMenu %W} 
  bind $win.f1.simcity.m <Mod2-Key> {tk_traverseToMenu %W %A} 
    $win.f1.simcity.m add command\
      -label {About...}\
      -command "UIShowPicture 300"
    $win.f1.simcity.m add command\
      -label {Save City}\
      -command "UISaveCity $win"
    $win.f1.simcity.m add command\
      -label {Save City as...}\
      -command "UISaveCityAs $win"
    $win.f1.simcity.m add command\
      -label {Add Player...}\
      -command "UIShowPlayer $win"
    $win.f1.simcity.m add command\
      -label {Get Key...}\
      -command "UIGetKey $win"
    $win.f1.simcity.m add command\
      -label {Another City!}\
      -command "UISelectCity $win"
    $win.f1.simcity.m add command\
      -label {Quit Playing!}\
      -command "UIQuit $win"

  SetHelp $win.f1.options OptionsMenu

  menubutton $win.f1.options\
    -menu $win.f1.options.m\
    -text {Options}\
    -font [Font $win Medium]\
    -variable $win.postedMenu
  tk_bindForTraversal $win.f1.options
  bind $win.f1.options <F10> {tk_firstMenu %W} 
  bind $win.f1.options <Mod2-Key> {tk_traverseToMenu %W %A} 

  tk_menus $win $win.f1.options

  menu $win.f1.options.m\
    -font [Font $win Medium]
  tk_bindForTraversal $win.f1.options.m
  bind $win.f1.options.m <F10> {tk_firstMenu %W} 
  bind $win.f1.options.m <Mod2-Key> {tk_traverseToMenu %W %A} 
    $win.f1.options.m add checkbutton\
      -label {Auto Budget}\
      -variable AutoBudget\
      -command {sim AutoBudget $AutoBudget}
    $win.f1.options.m add checkbutton\
      -label {Auto Bulldoze}\
      -variable AutoBulldoze\
      -command {sim AutoBulldoze $AutoBulldoze}
    $win.f1.options.m add checkbutton\
      -label {Disasters}\
      -variable Disasters\
      -command {sim Disasters $Disasters}
    $win.f1.options.m add checkbutton\
      -label {Sound}\
      -variable Sound\
      -command {sim Sound $Sound}
    $win.f1.options.m add checkbutton\
      -label {Animation}\
      -variable DoAnimation\
      -command {sim DoAnimation $DoAnimation}

  SetHelp $win.f1.disasters DisastersMenu

  menubutton $win.f1.disasters\
    -menu $win.f1.disasters.m\
    -text {Disasters}\
    -font [Font $win Medium]\
    -variable $win.postedMenu
  tk_bindForTraversal $win.f1.disasters
  bind $win.f1.disasters <F10> {tk_firstMenu %W} 
  bind $win.f1.disasters <Mod2-Key> {tk_traverseToMenu %W %A} 

  tk_menus $win $win.f1.disasters

  menu $win.f1.disasters.m\
    -font [Font $win Medium]
  tk_bindForTraversal $win.f1.disasters.m
  bind $win.f1.disasters.m <F10> {tk_firstMenu %W} 
  bind $win.f1.disasters.m <Mod2-Key> {tk_traverseToMenu %W %A} 
    $win.f1.disasters.m add command\
      -label {Monster}\
      -command {sim MakeMonster}
    $win.f1.disasters.m add command\
      -label {Fire}\
      -command {sim MakeFire}
    $win.f1.disasters.m add command\
      -label {Flood}\
      -command {sim MakeFlood}
    $win.f1.disasters.m add command\
      -label {Meltdown}\
      -command {sim MakeMeltdown}
    $win.f1.disasters.m add command\
      -label {Air Crash}\
      -command {sim MakeAirCrash}
    $win.f1.disasters.m add command\
      -label {Tornado}\
      -command {sim MakeTornado}
    $win.f1.disasters.m add command\
      -label {Earthquake}\
      -command {sim MakeEarthquake}

  SetHelp $win.f1.time TimeMenu

  menubutton $win.f1.time\
    -menu $win.f1.time.m\
    -text {Time}\
    -font [Font $win Medium]\
    -variable $win.postedMenu
  tk_bindForTraversal $win.f1.time
  bind $win.f1.time <F10> {tk_firstMenu %W} 
  bind $win.f1.time <Mod2-Key> {tk_traverseToMenu %W %A} 

  tk_menus $win $win.f1.time

  menu $win.f1.time.m\
    -font [Font $win Medium]
  tk_bindForTraversal $win.f1.time.m
  bind $win.f1.time.m <F10> {tk_firstMenu %W} 
  bind $win.f1.time.m <Mod2-Key> {tk_traverseToMenu %W %A} 
    $win.f1.time.m add radiobutton\
      -label {Pause}\
      -value {0}\
      -command {sim Speed 0}\
      -variable Time
    $win.f1.time.m add radiobutton\
      -label {Slow}\
      -value {1}\
      -command {sim Speed 1}\
      -variable Time
    $win.f1.time.m add radiobutton\
      -label {Medium}\
      -value {2}\
      -command {sim Speed 2}\
      -variable Time
    $win.f1.time.m add radiobutton\
      -label {Fast}\
      -value {3}\
      -command {sim Speed 3}\
      -variable Time


  SetHelp $win.f1.priority PriorityMenu

  menubutton $win.f1.priority\
    -menu $win.f1.priority.m\
    -text {Priority}\
    -font [Font $win Medium]\
    -variable $win.postedMenu
  tk_bindForTraversal $win.f1.priority
  bind $win.f1.priority <F10> {tk_firstMenu %W} 
  bind $win.f1.priority <Mod2-Key> {tk_traverseToMenu %W %A} 

  tk_menus $win $win.f1.priority

  menu $win.f1.priority.m\
    -font [Font $win Medium]
  tk_bindForTraversal $win.f1.priority.m
  bind $win.f1.priority.m <F10> {tk_firstMenu %W} 
  bind $win.f1.priority.m <Mod2-Key> {tk_traverseToMenu %W %A} 
    $win.f1.priority.m add radiobutton\
      -label {Flat Out!}\
      -command {sim Delay 2}\
      -value {7}\
      -variable Priority
    $win.f1.priority.m add radiobutton\
      -label {Zoom Zoom}\
      -command {sim Delay 25}\
      -value {6}\
      -variable Priority
    $win.f1.priority.m add radiobutton\
      -label {Buzz Buzz}\
      -command {sim Delay 100}\
      -value {5}\
      -variable Priority
    $win.f1.priority.m add radiobutton\
      -label {Putter Putter}\
      -command {sim Delay 250}\
      -value {2}\
      -variable Priority
    $win.f1.priority.m add radiobutton\
      -label {Snore Snore}\
      -command {sim Delay 1000}\
      -value {0}\
      -variable Priority

  SetHelp $win.f1.windows WindowsMenu

  menubutton $win.f1.windows\
    -menu $win.f1.windows.m\
    -text {Windows}\
    -font [Font $win Medium]\
    -variable $win.postedMenu
  tk_bindForTraversal $win.f1.windows
  bind $win.f1.windows <F10> {tk_firstMenu %W} 
  bind $win.f1.windows <Mod2-Key> {tk_traverseToMenu %W %A} 

  tk_menus $win $win.f1.windows

  menu $win.f1.windows.m\
    -font [Font $win Medium]
  tk_bindForTraversal $win.f1.windows.m
  bind $win.f1.windows.m <F10> {tk_firstMenu %W} 
  bind $win.f1.windows.m <Mod2-Key> {tk_traverseToMenu %W %A} 
    $win.f1.windows.m add command\
      -label {Budget}\
      -command "UIShowBudgetAndWait"
    $win.f1.windows.m add command\
      -label {Evaluation}\
      -command "ShowEvaluationOf $win"
    $win.f1.windows.m add command\
      -label {Graph}\
      -command "ShowGraphOf $win"
    $win.f1.windows.m add command\
      -label {Map}\
      -command "ShowMapOf $win"
    $win.f1.windows.m add command\
      -label {Editor}\
      -command "ShowEditorOf $win"
    $win.f1.windows.m add command\
      -label {Map Copy}\
      -command "NewMapOf $win"
    $win.f1.windows.m add command\
      -label {Editor Copy}\
      -command "NewEditorOf $win"

  LinkWindow $win.m0 $win.f1.simcity.m
  LinkWindow $win.m1 $win.f1.options.m
  LinkWindow $win.m2 $win.f1.disasters.m
  LinkWindow $win.m3 $win.f1.time.m
  LinkWindow $win.m4 $win.f1.priority.m
  LinkWindow $win.m5 $win.f1.windows.m

  LinkWindow $win.b0 $win.f1.simcity
  LinkWindow $win.b1 $win.f1.options
  LinkWindow $win.b2 $win.f1.disasters
  LinkWindow $win.b3 $win.f1.time
  LinkWindow $win.b4 $win.f1.priority
  LinkWindow $win.b5 $win.f1.windows

  pack append $win.f1\
    $win.f1.simcity	{left frame nw} \
    $win.f1.options	{left frame nw} \
    $win.f1.disasters	{left frame nw} \
    $win.f1.time	{left frame nw} \
    $win.f1.priority	{left frame nw} \
    $win.f1.windows	{left frame nw}

  frame $win.f2\
    -borderwidth 2\
    -relief raised

  frame $win.f2.f1\
    -borderwidth 3\
    -relief flat

  frame $win.f2.f1.info\
    -borderwidth 2\
    -relief flat

  label $win.f2.f1.info.datelabel\
    -relief flat\
    -font [Font $win Medium]\
    -text {}\
    -anchor w\
    -width 17
  LinkWindow $win.date $win.f2.f1.info.datelabel

  label $win.f2.f1.info.fundslabel\
    -relief flat\
    -font [Font $win Medium]\
    -text {}\
    -anchor w\
    -width 17
  LinkWindow $win.funds $win.f2.f1.info.fundslabel

  pack append $win.f2.f1.info \
    $win.f2.f1.info.datelabel	{top frame nw} \
    $win.f2.f1.info.fundslabel	{top frame nw}

  frame $win.f2.f1.frame \
    -borderwidth 2\
    -relief sunken

  graphview $win.f2.f1.frame.graph\
    -font [Font $win Tiny]
  $win.f2.f1.frame.graph Range 10
  $win.f2.f1.frame.graph Mask 7
  LinkWindow $win.graphview $win.f2.f1.frame.graph

  canvas $win.f2.f1.frame.demand\
    -scrollincrement 0 \
    -borderwidth 0 \
    -background #BFBFBF \
    -width 80 -height 55
  LinkWindow $win.demand $win.f2.f1.frame.demand
  $win.f2.f1.frame.demand create bitmap 0 4 \
    -tags picture \
    -bitmap "@images/demandg.xpm" \
    -anchor nw 
  $win.f2.f1.frame.demand create rectangle -10 -10 1 1 \
    -tags r \
    -fill [Color $win #00ff00 #000000]
  $win.f2.f1.frame.demand create rectangle -10 -10 1 1 \
    -tags c \
    -fill [Color $win #0000ff #000000]
  $win.f2.f1.frame.demand create rectangle -10 -10 1 1 \
    -tags i \
    -fill [Color $win #ffff00 #000000]
  $win.f2.f1.frame.demand create bitmap 41 4 \
    -tags simcity \
    -bitmap "@images/simcitys.xpm" \
    -anchor nw 

  pack append $win.f2.f1.frame \
    $win.f2.f1.frame.graph	{left frame nw expand fill} \
    $win.f2.f1.frame.demand	{right frame nw fill}

  pack append $win.f2.f1 \
    $win.f2.f1.info		{left frame nw} \
    $win.f2.f1.frame		{left frame nw expand fill} \

  frame $win.f2.f2\
    -borderwidth 2 \
    -relief flat
  tk_bindForTraversal $win.f2.f2
  bind $win.f2.f2 <F10> {tk_firstMenu %W} 
  bind $win.f2.f2 <Mod2-Key> {tk_traverseToMenu %W %A} 

  scrollbar $win.f2.f2.scroll\
    -command "$win.f2.f2.text yview" \
    -borderwidth 2

  text $win.f2.f2.text \
    -yscroll "$win.f2.f2.scroll set" \
    -borderwidth 2 \
    -relief sunken \
    -wrap word \
    -state disabled \
    -font [Font $win Small]
  LinkWindow $win.text $win.f2.f2.text

  $win.f2.f2.text tag configure status \
    -font [Font $win Small]

  $win.f2.f2.text tag configure message \
    -font [Font $win Small] \
    -foreground #ffffff \
    -background #3f3f3f

  $win.f2.f2.text tag configure alert \
    -font [Font $win Alert] \
    -foreground [Color $win #ff3f3f #000000]

  pack append $win.f2.f2 \
    $win.f2.f2.scroll	{left frame center filly} \
    $win.f2.f2.text	{right frame center fill expand}

  frame $win.f2.f3 \
    -borderwidth 2 \
    -relief flat
  tk_bindForTraversal $win.f2.f3
  bind $win.f2.f3 <F10> {tk_firstMenu %W} 
  bind $win.f2.f3 <Mod2-Key> {tk_traverseToMenu %W %A} 

  button $win.f2.f3.talk\
    -font [Font $win Large] \
    -relief flat \
    -text {Talk:}
  LinkWindow $win.talk $win.f2.f3.talk
  bind $win.f2.f3.talk <1> {TalkDown %W}
  bind $win.f2.f3.talk <ButtonRelease-1> {TalkUp %W}

  entry $win.f2.f3.entry \
    -relief sunken\
    -text {}\
    -foreground #ffffff\
    -background #4f4f4f\
    -textvariable $win.f2.f3.entry.value\
    -font [Font $win Message]
  global $win.f2.f3.entry.value
  set $win.f2.f3.entry.value ""
  tk_bindForTraversal $win.f2.f3.entry
  bind $win.f2.f3.entry <F10> {tk_firstMenu %W} 
  bind $win.f2.f3.entry <Mod2-Key> {tk_traverseToMenu %W %A}
  bind $win.f2.f3.entry <Return> "DoEnterMessage %W %W.value"
  bind $win.f2.f3.entry <Escape> "DoEvalMessage %W %W.value"
  bind $win.f2.f3.entry <Any-Enter> {focus %W}
  LinkWindow $win.entry $win.f2.f3.entry

  pack append $win.f2.f3 \
    $win.f2.f3.talk    {left frame center padx 4} \
    $win.f2.f3.entry   {left frame center fillx expand padx 4}

  # Only the message log (f2.f2) and the Talk input (f2.f3) are shown - this is
  # now the Messages/Chat window.  The old menu bar (f1) and the date/funds/graph/
  # demand/eval panel (f2.f1) are still created (so the HeadWindows update loops
  # and LinkWindows stay valid) but no longer packed; those live in the editor.
  pack append $win.f2 \
    $win.f2.f2		{top frame center expand fill} \
    $win.f2.f3		{top frame center fillx}

  pack append $win\
    $win.f2		{top frame center expand fill}

  SetupSoundServer $win

  InitHead $win
  InitHeadMenus $win

  update idletasks
  return $win
