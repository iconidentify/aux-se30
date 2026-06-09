/*
 * auxsaver - a DVD-style bouncing-logo screensaver for A/UX X11 (1-bit mono).
 *
 *   auxsaver [timeout]   blank after <timeout> idle seconds (default 120)
 *   auxsaver -test       bounce now; self-exit after ~6s (for testing)
 *
 * Bounces /usr/local/auxlogo.xbm around a black full-screen window. Idle is
 * found - and the saver dismissed - by polling the pointer (always reliable,
 * no dependence on event delivery or grabs); a key or button also dismisses.
 * Flicker-free: draw the logo at its new spot first, then clear only the thin
 * strip it vacated.  Pure Xlib; gcc 2.7.2.3 + our A/UX X11R6 shared libs.
 */
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#define LOGO     "/usr/local/auxlogo.xbm"
#define FRAME_MS 70
#define DX       5
#define DY       4

static void nap(ms) int ms; {
    struct timeval t; t.tv_sec = ms / 1000; t.tv_usec = (ms % 1000) * 1000;
    select(0, (fd_set *)0, (fd_set *)0, (fd_set *)0, &t);
}

main(argc, argv) int argc; char **argv; {
    Display *dpy; Window root, win, dw; Colormap cmap;
    int scr, W, H, di, timeout = 120, test = 0;
    int idle, x, y, nx, ny, dx, dy, wake, frames, px, py, ex, ey, cx, cy;
    unsigned int lw, lh, du;
    XColor blk, wht, junk; XSetWindowAttributes wa; XEvent ev;
    GC gc; Pixmap logo, cpix; Cursor blank; char none[8];

    if (argc > 1) {
        if (!strcmp(argv[1], "-test")) test = 1; else timeout = atoi(argv[1]);
    }
    if (timeout < 5) timeout = 5;

    if (!(dpy = XOpenDisplay((char *)0))) {
        fprintf(stderr, "auxsaver: cannot open display\n"); exit(1);
    }
    scr = DefaultScreen(dpy); root = RootWindow(dpy, scr);
    W = DisplayWidth(dpy, scr); H = DisplayHeight(dpy, scr);
    cmap = DefaultColormap(dpy, scr);
    XAllocNamedColor(dpy, cmap, "black", &blk, &junk);
    XAllocNamedColor(dpy, cmap, "white", &wht, &junk);

    if (XReadBitmapFile(dpy, root, LOGO, &lw, &lh, &logo, &di, &di)
            != BitmapSuccess) {
        fprintf(stderr, "auxsaver: cannot read %s\n", LOGO); exit(1);
    }

    wa.override_redirect = True;
    wa.background_pixel  = blk.pixel;
    wa.event_mask        = KeyPressMask | ButtonPressMask | PointerMotionMask;
    win = XCreateWindow(dpy, root, 0, 0, W, H, 0, CopyFromParent, InputOutput,
        CopyFromParent, CWOverrideRedirect | CWBackPixel | CWEventMask, &wa);

    gc = XCreateGC(dpy, win, 0L, (XGCValues *)0);
    XSetForeground(dpy, gc, wht.pixel);
    XSetBackground(dpy, gc, blk.pixel);

    memset(none, 0, sizeof none);
    cpix  = XCreateBitmapFromData(dpy, root, none, 8, 8);
    blank = XCreatePixmapCursor(dpy, cpix, cpix, &blk, &blk, 0, 0);

    XQueryPointer(dpy, root, &dw, &dw, &px, &py, &di, &di, &du);

    for (idle = 0; ; ) {
        if (!test) {                                  /* wait for idle */
            nap(1000);
            XQueryPointer(dpy, root, &dw, &dw, &cx, &cy, &di, &di, &du);
            if (cx != px || cy != py) { px = cx; py = cy; idle = 0; continue; }
            if (++idle < timeout) continue;
        }

        XMapRaised(dpy, win);                         /* run the saver */
        XClearWindow(dpy, win);
        XGrabKeyboard(dpy, win, True, GrabModeAsync, GrabModeAsync, CurrentTime);
        XGrabPointer(dpy, win, True, ButtonPressMask | PointerMotionMask,
            GrabModeAsync, GrabModeAsync, None, blank, CurrentTime);
        XSync(dpy, True);
        XQueryPointer(dpy, root, &dw, &dw, &ex, &ey, &di, &di, &du);

        x = (W - lw) / 2; y = (H - lh) / 2;
        dx = DX; dy = DY; wake = 0; frames = 0;
        XCopyPlane(dpy, logo, win, gc, 0, 0, lw, lh, x, y, 1L);
        XFlush(dpy);

        while (!wake) {
            nap(FRAME_MS);
            while (XPending(dpy)) {
                XNextEvent(dpy, &ev);
                if (ev.type == KeyPress || ev.type == ButtonPress
                        || ev.type == MotionNotify) wake = 1;
            }
            XQueryPointer(dpy, root, &dw, &dw, &cx, &cy, &di, &di, &du);
            if (cx != ex || cy != ey) wake = 1;
            if (test && ++frames > 80) wake = 1;
            if (wake) break;

            nx = x + dx; ny = y + dy;
            if (nx <= 0)      { nx = 0;      dx = -dx; }
            if (nx + lw >= W) { nx = W - lw; dx = -dx; }
            if (ny <= 0)      { ny = 0;      dy = -dy; }
            if (ny + lh >= H) { ny = H - lh; dy = -dy; }
            XCopyPlane(dpy, logo, win, gc, 0, 0, lw, lh, nx, ny, 1L);
            if      (nx > x) XClearArea(dpy, win, x, y, (unsigned)(nx-x), lh, False);
            else if (nx < x) XClearArea(dpy, win, nx+lw, y, (unsigned)(x-nx), lh, False);
            if      (ny > y) XClearArea(dpy, win, x, y, lw, (unsigned)(ny-y), False);
            else if (ny < y) XClearArea(dpy, win, x, ny+lh, lw, (unsigned)(y-ny), False);
            x = nx; y = ny;
            XFlush(dpy);
        }

        XUngrabPointer(dpy, CurrentTime);
        XUngrabKeyboard(dpy, CurrentTime);
        XUnmapWindow(dpy, win);
        XSync(dpy, True);
        XQueryPointer(dpy, root, &dw, &dw, &px, &py, &di, &di, &du);
        idle = 0;
        if (test) break;
    }
    XCloseDisplay(dpy); exit(0);
}
