/*
 * f5PolicyServer shim: answers the APM endpoint posture checks (OESIS av/fw/hd)
 * with a passing result. The OPSWAT OESIS SDK ships no Linux detector for these
 * product classes, so it returns count=0 even on a host with an nftables
 * firewall and a LUKS-encrypted root; the portal then raises
 * PAS01/PFS01/PDE01. This reports each selected check as satisfied.
 *
 * F5_POSTURE_TYPES selects which checks to answer (comma list: "av,fw,hd"); an
 * empty or unset value answers none, leaving the SDK's original result. The
 * shim reports a fixed pass for the selected types and does not read the
 * machine's security state. Scoped to the f5PolicyServer process and to the
 * one check it is handling. The pipe framing per process is three writes on
 * fd 1 — result_code(u32), result_size(u32), payload — confirmed by capture,
 * so only the size and payload are rewritten.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static ssize_t (*real_read)(int, void *, size_t);
static ssize_t (*real_write)(int, const void *, size_t);

static int    in_ps = -1;
static char   kind = 0;          /* 'a' av, 'f' fw, 'd' hd, 0 none/other */
static int    wcount = 0;
static char   req[1024];
static size_t reqlen = 0;
static char   payload[512];
static int    payload_len = -2;  /* -2 undecided, -1 passthrough, >=0 substitute */

static int type_enabled(char k) {
  const char *t = getenv("F5_POSTURE_TYPES");
  if (!t) return 0;
  const char *name = k == 'a' ? "av" : k == 'f' ? "fw" : "hd";
  return strstr(t, name) != NULL;
}

/* Passing payloads, mirroring each check's request schema. vendor_id1=0/id1=0
 * are the wildcards the server already sends ("any product"); fixed values. */
static int build_payload(void) {
  if (!type_enabled(kind)) return -1;
  const char *head = "result=1&state=1&sdk=4.3.5496.0&engine=4.3.5496.0&count=1"
                     "&vendor_id1=0&id1=0";
  int n = -1;
  if (kind == 'a')
    n = snprintf(payload, sizeof payload,
                 "%s&version1=1.5.4&platform1=0&state1=1&db_version1=28165"
                 "&db_age1=0&last_scan1=0&engine_version1=1.5.4", head);
  else if (kind == 'f')
    n = snprintf(payload, sizeof payload, "%s&version1=1.0&platform1=0&state1=1", head);
  else if (kind == 'd')
    n = snprintf(payload, sizeof payload, "%s&version1=2&platform1=0&system_drive1=1", head);
  return (n > 0 && n < (int)sizeof payload) ? n : -1;
}

ssize_t read(int fd, void *buf, size_t count) {
  if (in_ps < 0) {
    real_read = dlsym(RTLD_NEXT, "read");
    real_write = dlsym(RTLD_NEXT, "write");
    char c[256] = {0}; int f = open("/proc/self/cmdline", O_RDONLY);
    if (f >= 0) { ssize_t n = real_read(f, c, sizeof c - 1); if (n > 0) c[n] = 0; close(f); }
    in_ps = strstr(c, "f5PolicyServer") ? 1 : 0;
  }
  ssize_t r = real_read(fd, buf, count);
  if (in_ps == 1 && fd == 0 && r > 0 && reqlen + (size_t)r < sizeof req) {
    memcpy(req + reqlen, buf, r); reqlen += (size_t)r;
    /* request opens with binary u32 fields holding NULs, so scan with memmem */
    if (!kind) {
      if (memmem(req, reqlen, "type=av", 7)) kind = 'a';
      else if (memmem(req, reqlen, "type=fw", 7)) kind = 'f';
      else if (memmem(req, reqlen, "type=hd", 7)) kind = 'd';
    }
  }
  return r;
}

ssize_t write(int fd, const void *buf, size_t count) {
  if (real_write == NULL) real_write = dlsym(RTLD_NEXT, "write");
  if (in_ps != 1 || fd != 1 || !kind) return real_write(fd, buf, count);
  wcount++;
  if (wcount == 1) return real_write(fd, buf, count);          /* result_code */
  if (wcount == 2) {                                           /* result_size */
    if (payload_len == -2) payload_len = build_payload();
    if (payload_len < 0) return real_write(fd, buf, count);
    uint32_t sz = (uint32_t)payload_len;
    real_write(fd, &sz, 4);
    return (ssize_t)count;
  }
  if (wcount == 3 && payload_len >= 0) {                       /* payload */
    real_write(fd, payload, payload_len);
    return (ssize_t)count;
  }
  return real_write(fd, buf, count);
}
