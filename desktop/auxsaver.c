/*
 * auxsaver - a DVD-style bouncing-logo screensaver for A/UX X11 (1-bit mono).
 *
 *   auxsaver [timeout]   blank after <timeout> idle seconds (default 120)
 *   auxsaver -test       bounce now; self-exit after ~6s (forces the C89 logo)
 *
 * Bounces a logo on a black full-screen window. Each time the saver kicks in it
 * picks a RANDOM logo from the installed set (Apple/A-UX and C89 Summer). Idle
 * detection + wake are done by polling the pointer (always reliable, no grab
 * dependence); a key/button also wakes. Flicker-free: draw the logo at its new
 * spot first, then clear only the thin strip it vacated.  Pure Xlib.
 */
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

#define FRAME_MS 70
#define DX       5
#define DY       4
#define MAXLOGOS 4

static char *logofiles[MAXLOGOS] = {
    "/usr/local/c89logo.xbm",
    "/usr/local/auxlogo.xbm",
    0, 0
};

static void nap(ms) int ms; {
    struct timeval t; t.tv_sec = ms / 1000; t.tv_usec = (ms % 1000) * 1000;
    select(0, (fd_set *)0, (fd_set *)0, (fd_set *)0, &t);
}

main(argc, argv) int argc; char **argv; {
    Display *dpy; Window root, win, dw; Colormap cmap;
    int scr, W, H, di, timeout = 120, test = 0;
    int idle, x, y, nx, ny, dx, dy, wake, frames, px, py, ex, ey, cx, cy;
    unsigned int du;
    XColor blk, wht, junk; XSetWindowAttributes wa; XEvent ev;
    GC gc; Pixmap cpix; Cursor blank; char none[8];
    Pixmap logos[MAXLOGOS]; unsigned int lwid[MAXLOGOS], lht[MAXLOGOS];
    int nlogos = 0, c89 = -1, i, idx;
    Pixmap logo; unsigned int lw, lh;

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

    /* load every logo that exists */
    for (i = 0; i < MAXLOGOS && logofiles[i]; i++) {
        Pixmap p; unsigned int pw, ph; int hx, hy;
        if (XReadBitmapFile(dpy, root, logofiles[i], &pw, &ph, &p, &hx, &hy)
                == BitmapSuccess) {
            if (strstr(logofiles[i], "c89")) c89 = nlogos;
            logos[nlogos] = p; lwid[nlogos] = pw; lht[nlogos] = ph; nlogos++;
        }
    }
    if (nlogos == 0) { fprintf(stderr, "auxsaver: no logo files found\n"); exit(1); }
    srand((unsigned) time((time_t *) 0));

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
        if (!test) {
            nap(1000);
            XQueryPointer(dpy, root, &dw, &dw, &cx, &cy, &di, &di, &du);
            if (cx != px || cy != py) { px = cx; py = cy; idle = 0; continue; }
            if (++idle < timeout) continue;
        }

        /* pick a logo: -test forces C89 if present; else random */
        idx = (test && c89 >= 0) ? c89 : (rand() % nlogos);
        logo = logos[idx]; lw = lwid[idx]; lh = lht[idx];

        XMapRaised(dpy, win);
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
            x = nx; y = ny; XFlush(dpy);
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
