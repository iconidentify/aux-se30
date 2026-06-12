/* bgroot - set the root window background from an XPM, politely.
 * Implements the _XSETROOT_ID convention (kills the previous setter's
 * retained resources, so swapping backgrounds doesn't leak colormap
 * cells) and allocates with maximum closeness (never fails outright on
 * a crowded 8-bit colormap - approximates with existing cells). */
#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/xpm.h>

int main(int argc, char **argv)
{
    Display *dpy;
    Window root;
    Pixmap pm, mask;
    XpmAttributes att;
    Atom prop, type;
    int format, rc;
    unsigned long nitems, after;
    unsigned char *data = NULL;

    if (argc != 2) {
        fprintf(stderr, "usage: bgroot file.xpm\n");
        return 1;
    }
    dpy = XOpenDisplay(NULL);
    if (dpy == NULL) {
        fprintf(stderr, "bgroot: cannot open display\n");
        return 1;
    }
    root = DefaultRootWindow(dpy);
    prop = XInternAtom(dpy, "_XSETROOT_ID", False);

    /* free the previous background's retained colors */
    if (XGetWindowProperty(dpy, root, prop, 0, 1, True, AnyPropertyType,
            &type, &format, &nitems, &after, &data) == Success
            && type == XA_PIXMAP && format == 32 && nitems == 1) {
        XKillClient(dpy, *((Pixmap *)data));
    }
    if (data != NULL)
        XFree(data);
    XSync(dpy, False);

    att.valuemask = XpmCloseness;
    att.closeness = 65535;
    rc = XpmReadFileToPixmap(dpy, root, argv[1], &pm, &mask, &att);
    if (rc != XpmSuccess) {
        fprintf(stderr, "bgroot: XpmError %d\n", rc);
        return 1;
    }
    XSetWindowBackgroundPixmap(dpy, root, pm);
    XClearWindow(dpy, root);
    XChangeProperty(dpy, root, prop, XA_PIXMAP, 32, PropModeReplace,
        (unsigned char *)&pm, 1);
    XSetCloseDownMode(dpy, RetainPermanent);
    XSync(dpy, False);
    printf("bgroot: ok\n");
    return 0;
}
