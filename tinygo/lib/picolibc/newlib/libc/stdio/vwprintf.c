/*
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * and/or other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */
/* doc in vfwprintf.c */

#define _DEFAULT_SOURCE
#include <_ansi.h>
#include <stdio.h>
#include <wchar.h>
#include <stdarg.h>
#include "local.h"

#ifndef _REENT_ONLY

int
vwprintf (const wchar_t *__restrict fmt,
       va_list ap)
{
  struct _reent *reent = _REENT;

  _REENT_SMALL_CHECK_INIT (reent);
  return _vfwprintf_r (reent, _stdout_r (reent), fmt, ap);
}

#endif /* !_REENT_ONLY */

int
_vwprintf_r (struct _reent *ptr,
       const wchar_t *fmt,
       va_list ap)
{
  _REENT_SMALL_CHECK_INIT (ptr);
  return _vfwprintf_r (ptr, _stdout_r (ptr), fmt, ap);
}
