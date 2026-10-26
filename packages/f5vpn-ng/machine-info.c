/*
 * LD_PRELOAD shim for f5vpn-ng: adds the APM "Machine Info" network-adapter
 * fields that the old Qt client (via f5PolicyServer check_type 3) sent and
 * the GTK rewrite dropped. Without them Airbus's home-office policy branch has
 * no MAC to evaluate and hangs the session up with HO01.
 *
 * The client formats its answer with g_snprintf(buf, 1024, FMT, ...), so the
 * hook matches on that exact format string and appends
 *   &netadaptercount=N&netadapternames=IF\;...&netadaptermacaddresses=MAC\;...
 * in f5PolicyServer's own encoding (percent-encoded values, "\;" separators,
 * uppercase hex). Interfaces come from F5VPN_NETADAPTERS (comma separated);
 * only those are disclosed, so docker bridges and veths stay out.
 */
#define _GNU_SOURCE
#include <ctype.h>
#include <dlfcn.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char FMT[] = "hostname=%s&domain=%s&platform=linux&os_version=%s";

static size_t pct_append(char *dst, size_t cap, const char *src) {
  size_t len = strlen(dst);
  for (; *src && len + 4 < cap; src++) {
    unsigned char c = (unsigned char)*src;
    if (isalnum(c))
      dst[len++] = (char)c;
    else
      len += (size_t)snprintf(dst + len, cap - len, "%%%02X", c);
  }
  dst[len] = 0;
  return len;
}

static int read_mac(const char *ifname, char *mac, size_t cap) {
  char path[256];
  snprintf(path, sizeof path, "/sys/class/net/%s/address", ifname);
  FILE *f = fopen(path, "r");
  if (!f) return 0;
  int ok = fgets(mac, (int)cap, f) != NULL;
  fclose(f);
  if (!ok) return 0;
  mac[strcspn(mac, "\n")] = 0;
  for (char *p = mac; *p; p++) *p = (char)toupper((unsigned char)*p);
  return strlen(mac) == 17;  /* tun/p2p devices have no hardware address */
}

int g_snprintf(char *s, unsigned long n, const char *fmt, ...) {
  static int (*real)(char *, unsigned long, const char *, va_list);
  if (!real) real = dlsym(RTLD_NEXT, "g_vsnprintf");
  va_list ap;
  va_start(ap, fmt);
  int r = real(s, n, fmt, ap);
  va_end(ap);
  if (r < 0 || (unsigned long)r >= n || strcmp(fmt, FMT) != 0) return r;

  const char *env = getenv("F5VPN_NETADAPTERS");
  if (!env || !*env) return r;

  char names[512] = "", macs[512] = "", list[256], mac[32];
  int count = 0;
  snprintf(list, sizeof list, "%s", env);
  for (char *ifname = strtok(list, ","); ifname; ifname = strtok(NULL, ",")) {
    if (!read_mac(ifname, mac, sizeof mac)) continue;
    pct_append(names, sizeof names, ifname);
    strncat(names, "\\;", sizeof names - strlen(names) - 1);
    pct_append(macs, sizeof macs, mac);
    strncat(macs, "\\;", sizeof macs - strlen(macs) - 1);
    count++;
  }
  if (!count) return r;
  return r + snprintf(s + r, n - (unsigned long)r,
                      "&netadaptercount=%d&netadapternames=%s&netadaptermacaddresses=%s",
                      count, names, macs);
}
