// use bdb
// store things in an in-memory bdb?

/*
 * provide a "window manager" library.
 * - accept all necessary events
 * + Allow registry of events
 *  | Register events.
 *  | Store list of windows, state, etc
 * + Provide querying of window list without hitting the X server?
 * + Store additional properties for all windows via optional struct.
 */

typedef struct xenv {
  
} xenv_t

wm_t *wm_init(char *display) {
  wm_t *wm = NULL:
  wm = malloc(sizeof(wm_t));
}