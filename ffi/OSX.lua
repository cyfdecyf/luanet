local ffi = require 'ffi'

--[[
The following definitions are copied from header files on OS X.
--]]

ffi.cdef[[
static const int EOF = -1; /* stdio.h */

/* sys/errno.h */
enum {
  EINTR = 4,

  EAGAIN = 35,
  EWOULDBLOCK = 35,

  ECONNABORTED = 53,
  ECONNRESET = 54,
  ETIMEOUT = 60,
  ECONNREFUSED = 61,
};

enum {
  F_DUPFD = 0,
  F_GETFD = 1,
  F_SETFD = 2,
  F_GETFL = 3,
  F_SETFL = 4,
};

enum {
  O_NONBLOCK = 0x0004,
  O_APPEND = 0x0008,
};

static const int FD_CLOEXEC = 1;

enum {
  SOCK_STREAM = 1,
  SOCK_DGRAM  = 2,
  SOCK_RAW    = 3,
};

enum {
  AF_UNSPEC = 0,
  AF_UNIX   = 1,
  AF_INET   = 2,
  AF_INET6  = 30,
};

enum {
  SO_DEBUG      = 0x0001,
  SO_ACCEPTCONN = 0x0002,
  SO_REUSEADDR  = 0x0004,
  SO_KEEPALIVE  = 0x0008,
  SO_DONTROUTE  = 0x0010,
  SO_BROADCAST  = 0x0020,
};

/* sys/_types.h */
typedef int32_t pid_t;
typedef uint32_t useconds_t;

/* From netinet/in.h */
static const int INADDR_ANY = (uint32_t)0x00000000;

static const int SOMAXCONN = 128;
static const int SOL_SOCKET = 0xffff;

/* Various types. */

typedef uint8_t sa_family_t;
typedef uint32_t socklen_t;

/*
  i386/_types.h
  sys/_types/_size_t.h
  sys/_types/_ssize_t.h
  sys/_types/_in_addr_t.h
 */
typedef long ssize_t;
typedef unsigned long size_t;
typedef uint32_t in_addr_t;
typedef uint16_t in_port_t;

/* netinet/ip.h */
struct in_addr {
    in_addr_t s_addr;
};

/* netinet/in.h */
struct sockaddr {
    uint8_t     sa_len;     /* total length */
    sa_family_t sa_family;  /* [XSI] address family */
    char        sa_data[14];    /* [XSI] addr value (actually larger) */
};

struct sockaddr_in {
    uint8_t     sin_len;
    sa_family_t sin_family;
    in_port_t   sin_port;
    struct in_addr sin_addr;
    char        sin_zero[8];
};

/* Use the biggest sockaddr in accept, so no need to  */
typedef struct sockaddr_in sockaddr_big;
]]
