local ffi = require 'ffi'
local C = ffi.C

ffi.cdef[[
/* from sys/event.h */
enum {
  EVFILT_READ     = -1,
  EVFILT_WRITE    = -2,
  EVFILT_AIO      = -3,
  EVFILT_VNODE    = -4,
  EVFILT_PROC     = -5,
  EVFILT_SIGNAL   = -6,
  EVFILT_TIMER    = -7,
  EVFILT_MACHPORT = -8,
  EVFILT_FS       = -9,
  EVFILT_USER     = -10,
  /* -11 unused */
  EVFILT_VM       = -12,
  EVFILT_SYSCOUNT = -14,
};

/* actions */
enum {
  EV_ADD     = 0x0001,
  EV_DELETE  = 0x0002,
  EV_ENABLE  = 0x0004,
  EV_DISABLE = 0x0008,
  EV_RECEIPT = 0x0040,
};

/* flags */
enum {
  EV_ONSHOT   = 0x0010,
  EV_CLEAR    = 0x0020,
  EV_DISPATCH = 0x0080,

  EV_SYSFLAGS = 0xF000, /* reserved by system */
  EV_FLAG0    = 0x1000, /* filter-specific flag */
  EV_FLAG1    = 0x2000, /* filter-specific flag */

  EV_POOL     = EV_FLAG0,
  EV_OOBAND   = EV_FLAG1,
};

/* returned values */
enum {
  EV_EOF   = 0x8000,
  EV_ERROR = 0x4000,
};

struct kevent {
  uintptr_t ident;
  int16_t   filter;
  uint16_t  flags;
  uint32_t  fflags;
  intptr_t  data;
  void      *udata;
};

struct timespec {
  long tv_sec; /* __darwin_time_t typedef in i386/_types.h */
  long tv_nsec;
};
]]
