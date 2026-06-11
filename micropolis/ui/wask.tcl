  global AskWindows
  set n [Unique]
  set win .ask$n
  set AskWindows [linsert $AskWindows 0 $win]

  LinkWindow $head.ask $win
  LinkWindow $win.head $head

  catch "destroy $win"
  toplevel $win -screen $display

  SetHelp $win Window

  wm title $win {SimCity}
  wm iconname $win {SimCity}
  wm geometry $win +320+260
  wm positionfrom $win user
  wm minsize $win 240 1
  wm protocol $win delete "DeleteWindow ask AskWindows"

  frame $win.top \
    -relief raised \
    -borderwidth 2
  LinkWindow $win.background $win.top

  # hidden compat title widget (the window title is named per use case now;
  # there is no coloured banner)
  label $win.top.title \
    -borderwidth 0
  LinkWindow $win.title $win.top.title

  # centered modal message
  message $win.top.text \
    -aspect 500 \
    -justify center \
    -borderwidth 12 \
    -relief flat \
    -font [Font $win Large]
  LinkWindow $win.text $win.top.text

  frame $win.top.frame \
    -borderwidth 8 \
    -relief flat
  LinkWindow $win.frame $win.top.frame

  button $win.top.frame.left \
    -font [Font $win Large]\
    -borderwidth 2 -width 8\
    -padx 4 -pady 4
  LinkWindow $win.left $win.top.frame.left

  button $win.top.frame.middle \
    -font [Font $win Large]\
    -borderwidth 2 -width 8\
    -padx 4 -pady 4
  LinkWindow $win.middle $win.top.frame.middle

  # the right button is the default action (Enter key); a 2px ring marks it
  frame $win.top.frame.rightframe \
    -borderwidth 2 \
    -relief sunken
  LinkWindow $win.voteframe $win.top.frame.rightframe

  button $win.top.frame.rightframe.right \
    -font [Font $win Large]\
    -relief raised \
    -borderwidth 2 -width 8\
    -padx 4 -pady 4
  LinkWindow $win.vote $win.top.frame.rightframe.right

  pack append $win.top.frame.rightframe\
    $win.top.frame.rightframe.right	{top frame center}

  BindVotingButton $win $win.top.frame.rightframe.right Ask

  pack append $win.top\
    $win.top.text	{top frame center expand fill} \
    $win.top.frame	{bottom frame center}

  pack append $win\
    $win.top		{left frame center expand fill}

  bind $win <Return> "$win.top.frame.rightframe.right invoke"
  bind $win <KP_Enter> "$win.top.frame.rightframe.right invoke"

  update idletasks
  return $win
