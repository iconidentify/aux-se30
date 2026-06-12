/* aux_termfix.c - make ncurses behave on the vintage A/UX xterm stack.
 *
 * Two distinct problems hide here:
 *
 * 1. The 1994 X11R6 xterm implements a number of advertised terminfo
 *    capabilities incorrectly (clears, single-axis addressing, scroll
 *    regions, insert/delete).  ncurses optimizes with them and its
 *    model of the screen diverges from the glass.  We NULL them so it
 *    falls back to absolute cursor addressing and literal spaces.
 *
 * 2. The A/UX tty driver post-processes output: ONLCR rewrites the ^J
 *    cursor-down motion into CR+LF (silently resetting the column) and
 *    TAB3 expands the ^I cursor-right motion into literal spaces
 *    (overwriting cells).  Either one scrambles ncurses' cursor
 *    tracking; a mapped ^J on the bottom row scrolls the whole screen
 *    behind ncurses' back.  We disable output post-processing on the
 *    tty and also NULL the control-character motion capabilities so
 *    ncurses moves only with escape sequences, then re-save program
 *    mode so the setting survives mode switches.
 *
 * Extends the fix auxtop ships as auxterm.c.  Isolated in its own file
 * because <term.h> defines capability names as macros that collide
 * with ordinary identifiers.  Link this only on vintage builds.
 */
#include <stdlib.h>
#include <string.h>
#include <curses.h>
#include <term.h>
#include <termio.h>

void dialc_term_quirks()
{
    struct termio t;
    char *term = getenv("TERM");

    /* raw output first: no NL/TAB rewriting by the tty driver (this is
     * a driver problem, needed whatever the terminal emulator is) */
    if (ioctl(1, TCGETA, &t) == 0) {
        t.c_oflag &= ~OPOST;
        (void)ioctl(1, TCSETA, &t);
    }
    def_prog_mode();

    /* a correct terminal (the rxvt port) needs none of the capability
     * surgery below - that is for the 1994 R6 xterm only */
    if (term && strncmp(term, "rxvt", 4) == 0) return;

    /* clearing */
    clr_eol = NULL;
    clr_eos = NULL;
    clear_screen = NULL;
    erase_chars = NULL;

    /* cursor motion shortcuts */
    column_address = NULL;
    row_address = NULL;
    parm_left_cursor = NULL;
    parm_right_cursor = NULL;
    parm_up_cursor = NULL;
    parm_down_cursor = NULL;

    /* control-character motions the tty driver can rewrite */
    cursor_down = NULL;           /* ^J: ONLCR turns it into CR+LF */
    tab = NULL;                   /* ^I: TAB3 expands it to spaces */
    back_tab = NULL;
    newline = NULL;

    /* scrolling and line shifting */
    scroll_forward = NULL;
    scroll_reverse = NULL;
    change_scroll_region = NULL;
    parm_index = NULL;
    parm_rindex = NULL;
    insert_line = NULL;
    delete_line = NULL;
    parm_insert_line = NULL;
    parm_delete_line = NULL;

    /* character insert/delete */
    insert_character = NULL;
    parm_ich = NULL;
    delete_character = NULL;
    parm_dch = NULL;
    enter_insert_mode = NULL;
    exit_insert_mode = NULL;
    enter_delete_mode = NULL;
    exit_delete_mode = NULL;

    /* repeat-character shortcut */
    repeat_char = NULL;
}
