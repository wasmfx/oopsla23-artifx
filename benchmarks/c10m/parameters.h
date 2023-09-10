#ifndef __ASYNCWL_PARAMETERS_H
#define __ASYNCWL_PARAMETERS_H

#include <stdint.h>

static const uint32_t modifier = 10;
// This parameter controls how many coroutines are generated in total.
static const uint32_t total_conn = modifier * 1000000;
// This parameter controls the maxmimum number of simultaneous
// coroutines.
#define active_conn ((uint32_t)10000)
// This parameter controls the stack manipulation size parameter for
// each coroutine.
static const uint32_t stack_kb = 32;


static const uint32_t reference = 10010000;

static int verify(const uint32_t my_count, const uint32_t reference) {
  if (my_count == reference) return 0;
  else return 1;
}

#endif
