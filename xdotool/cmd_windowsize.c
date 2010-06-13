#include "xdo_cmd.h"

int cmd_windowsize(context_t *context) {
  int ret = 0;
  unsigned int width, height;
  int c;
  int opsync = 0;

  int use_hints = 0;
  typedef enum {
    opt_unused, opt_help, opt_usehints, opt_sync
  } optlist_t;
  struct option longopts[] = {
    { "usehints", 0, NULL, opt_usehints },
    { "help", no_argument, NULL, opt_help },
    { "sync", no_argument, NULL, opt_sync },
    { 0, 0, 0, 0 },
  };

  int size_flags = 0;
  char *cmd = *context->argv;
  int option_index;
  static const char *usage =
            "Usage: %s [--sync] [--usehints] [window=%1] width height\n"
            HELP_SEE_WINDOW_STACK
            "--usehints  - Use window sizing hints (like font size in terminals)\n"
            "--sync      - only exit once the window has resized\n";


  while ((c = getopt_long_only(context->argc, context->argv, "+uh",
                               longopts, &option_index)) != -1) {
    switch (c) {
      case 'h':
      case opt_help:
        printf(usage, cmd);
        consume_args(context, context->argc);
        return EXIT_SUCCESS;
      case 'u':
      case opt_usehints:
        use_hints = 1;
        break;
      case opt_sync:
        opsync = 1;
        break;
      default:
        fprintf(stderr, usage, cmd);
        return EXIT_FAILURE;
    }
  }

  if (use_hints) {
    size_flags |= SIZE_USEHINTS;
  }

  consume_args(context, optind);

  const char *window_arg = "%1";

  if (!window_get_arg(context, 2, 0, &window_arg)) {
    fprintf(stderr, "Invalid argument count, got %d, expected %d\n", 
            3, context->argc);
    fprintf(stderr, usage, cmd);
    return EXIT_FAILURE;
  }

  width = (unsigned int)strtoul(context->argv[0], NULL, 0);
  height = (unsigned int)strtoul(context->argv[1], NULL, 0);
  consume_args(context, 2);

  unsigned int original_w, original_h;
  window_each(context, window_arg, {
    if (opsync) {
      unsigned int w = width;
      unsigned int h = height;
      xdo_get_window_size(context->xdo, window, &original_w, &original_h);
      if (size_flags & SIZE_USEHINTS) { 
        xdo_window_translate_with_sizehint(context->xdo, window, w, h, &w, &h);
      }
      if (original_w == w && original_h == h) {
        /* Skip, this window doesn't need to move. */
        break;
      }
    }
    ret = xdo_window_setsize(context->xdo, window, width, height, size_flags);
    if (ret) {
      fprintf(stderr, "xdo_window_setsize on window:%ld reported an error\n",
              window);
      return ret;
    }
    if (opsync) {
      xdo_window_wait_for_size(context->xdo, window, original_w, original_h, 0,
                               SIZE_FROM);
    }
  }); /* window_each(...) */

  return ret;
}

