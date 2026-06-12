/* shared between auxtop.c and the m_aux3 accessor */
struct auxtop_proc {
    long pid;
    long uid;
    int  pri;
    int  nice;
    long size;    /* KB */
    int  stat;
    long secs;    /* CPU seconds */
    double pcpu;  /* fraction 0..1 (u-area, unreliable on AUX) */
    int  cpu;     /* scheduler p_cpu estimate */
    char name[16];
};
extern int auxtop_next();
