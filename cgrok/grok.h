#ifndef _GROK_H_
#define _GROK_H_

#include <pcre.h>
#include <db.h>

typedef struct grok grok_t;

typedef struct grok_pattern {
  const char *name;
  char *regexp;
} grok_pattern_t;

struct grok {
  DB *patterns;
  
  /* These are initialized when grok_compile is called */
  pcre *re;
  const char *pattern;
  char *full_pattern;
  int *pcre_capture_vector;
  int pcre_num_captures;
  
  /* Data storage for named-capture (grok capture) information */
  DB *captures_by_id;
  DB *captures_by_name;
  DB *captures_by_capture_number;
  int max_capture_num;
  
  /* PCRE pattern compilation errors */
  const char *pcre_errptr;
  int pcre_erroffset;

  unsigned int logmask;
  char *errstr;
};

extern int g_grok_global_initialized;
extern pcre *g_pattern_re;
extern int g_pattern_num_captures;
extern int g_cap_name;
extern int g_cap_pattern;
extern int g_cap_subname;
extern int g_cap_predicate;

/* pattern to match %{FOO:BAR} */
/* or %{FOO<=3} */
#define PATTERN_REGEX "%{" \
                        "(?<name>" \
                          "(?<pattern>[A-z0-9._-]+)" \
                          "(?::(?<subname>[A-z0-9._-]+))?" \
                        ")" \
                        "(?<predicate>\\s*(?:[$]?=[<>=~]|![=~]|[$]?[<>])\\s*[^}]+)?" \
                      "}"
#define CAPTURE_ID_LEN 4
#define CAPTURE_FORMAT "%04x"


#include "logging.h"
#include "grok_match.h"

#ifndef GROK_TEST_NO_PATTERNS
#include "grok_pattern.h"
#endif

#ifndef GROK_TEST_NO_CAPTURE
#include "grok_capture.h"
#endif

#include "grokre.h"

#endif /* ifndef _GROK_H_ */
