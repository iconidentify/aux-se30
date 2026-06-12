/* auxterm.c - isolated because <term.h> defines terminfo capability
 * names (tab, lines, columns, ...) as macros that collide with normal
 * identifiers. Here we NULL out the terminal capabilities that the 1994
 * X11R6 xterm implements incorrectly, forcing ncurses onto the ones
 * that work:
 *   clr_eol/clr_eos/clear_screen  -> clear by writing literal spaces
 *   column_address/row_address    -> position only via absolute cursor_address
 *   parm_*_cursor                 -> no parameterized relative moves
 * Without this, ncurses "optimizes" a row's redraw with a single-axis
 * column jump that no-ops on the R6 xterm, leaving that row's cursor at
 * the previous column (the "init at column 50" ghost). */
#include <curses.h>
#include <term.h>

void auxtop_defeat_clear()
{
    clr_eol = NULL;
    clr_eos = NULL;
    clear_screen = NULL;
    column_address = NULL;
    row_address = NULL;
    parm_left_cursor = NULL;
    parm_right_cursor = NULL;
    parm_up_cursor = NULL;
    parm_down_cursor = NULL;
}
