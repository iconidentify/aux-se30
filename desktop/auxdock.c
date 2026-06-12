/* auxdock - a drag-to-snap icon dock for fvwm 1.x on A/UX.
 *
 * Runs in the background watching root SubstructureNotify events. When you
 * drag a desktop icon up into the snap zone at the top of the screen, a
 * bright slot "illuminates" at the nearest grid column showing where it
 * will land; release (stop moving) and the icon - and its label - snap into
 * that slot, tight like a taskbar. fvwm has no such feature; this is new.
 *
 * fvwm 1.x icons = two root windows: a pixmap (taller) + a label below it.
 * We snap the pixmap and find/move its label with it.
 */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/time.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define ZONE_TOP   16        /* drag above this y to engage the dock */
#define ZONE_BOT   150
#define SLOTY      46        /* docked icon row y */
#define SLOTW      52        /* tight taskbar column pitch */
#define LEFTM      56        /* left margin of the dock */
#define HLW        46        /* highlight size */
#define HLH        50
#define SNAP_MS    200       /* idle time after a drag stops -> snap */

static unsigned long getcolor(dpy, name)
    Display *dpy; char *name;
{
    XColor c, e;
    Colormap cm = DefaultColormap(dpy, DefaultScreen(dpy));
    if (XAllocNamedColor(dpy, cm, name, &c, &e)) return c.pixel;
    return WhitePixel(dpy, DefaultScreen(dpy));
}

/* find a short label window near (x,y) - the icon's title strip */
static Window find_label(dpy, root, pixmap, x, y)
    Display *dpy; Window root, pixmap; int x, y;
{
    Window rr, parent, *ch, found = 0;
    unsigned int n, i;
    if (!XQueryTree(dpy, root, &rr, &parent, &ch, &n)) return 0;
    for (i = 0; i < n; i++) {
        XWindowAttributes wa;
        if (ch[i] == pixmap) continue;
        if (!XGetWindowAttributes(dpy, ch[i], &wa)) continue;
        if (wa.map_state != IsViewable) continue;
        if (wa.height >= 24 || wa.width > 150) continue;
        if (abs(wa.x - x) <= 10 && abs(wa.y - y) <= 12) { found = ch[i]; break; }
    }
    XFree((char *)ch);
    return found;
}

int main(argc, argv)
    int argc; char **argv;
{
    Display *dpy;
    Window root, hl, picon = 0;
    int screen, fd, slotx = 0, ihx = 0, ihy = 0, ih = 0, iw = 0, havepend = 0;
    XSetWindowAttributes swa;

    dpy = XOpenDisplay((char *)0);
    if (dpy == (Display *)0) { fprintf(stderr, "auxdock: no display\n"); return 1; }
    screen = DefaultScreen(dpy);
    root = RootWindow(dpy, screen);
    fd = ConnectionNumber(dpy);

    swa.override_redirect = True;
    swa.background_pixel = getcolor(dpy, "magenta");
    swa.border_pixel = getcolor(dpy, "cyan");
    hl = XCreateWindow(dpy, root, -200, -200, HLW, HLH, 2,
        CopyFromParent, InputOutput, CopyFromParent,
        CWOverrideRedirect | CWBackPixel | CWBorderPixel, &swa);

    XSelectInput(dpy, root, SubstructureNotifyMask);

    for (;;) {
        fd_set rd; struct timeval tv; int r;

        while (XPending(dpy)) {
            XEvent ev;
            XNextEvent(dpy, &ev);
            if (ev.type == ConfigureNotify) {
                XConfigureEvent *ce = &ev.xconfigure;
                if (ce->window != hl &&
                    ce->width <= 150 && ce->height >= 24 && ce->height <= 150 &&
                    ce->y >= ZONE_TOP && ce->y <= ZONE_BOT && ce->y != SLOTY) {
                    int slot = (ce->x - LEFTM + SLOTW / 2) / SLOTW;
                    if (slot < 0) slot = 0;
                    slotx = LEFTM + slot * SLOTW;
                    picon = ce->window;
                    ihx = ce->x; ihy = ce->y; ih = ce->height; iw = ce->width;
                    havepend = 1;
                    XMoveWindow(dpy, hl, slotx + (iw - HLW) / 2 - 2, SLOTY - 2);
                    XMapRaised(dpy, hl);
                    XFlush(dpy);
                }
            }
        }

        FD_ZERO(&rd); FD_SET(fd, &rd);
        tv.tv_sec = 0; tv.tv_usec = SNAP_MS * 1000;
        r = select(fd + 1, &rd, (fd_set *)0, (fd_set *)0, &tv);
        if (r == 0 && havepend) {
            Window lbl = find_label(dpy, root, picon, ihx, ihy + ih);
            XMoveWindow(dpy, picon, slotx, SLOTY);
            if (lbl) XMoveWindow(dpy, lbl, slotx, SLOTY + ih);
            XUnmapWindow(dpy, hl);
            XFlush(dpy);
            havepend = 0;
        }
    }
}
