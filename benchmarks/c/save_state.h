#ifndef save_state_h_INCLUDED
#define save_state_h_INCLUDED

#include "stdbool.h"

// This is how we deal with not having lambda
typedef struct env {
    bool suspended;
    int save_for_later;
} env;

// Enqueues a_coroutine to the queue (defined in assembly) and returns the
// number of currently enqueued routines
unsigned int enqueue_a_coroutine(void);
// Pop a coroutine off of the queue, resume it, assume it returns, and return
// the number of currently enqueued routines
unsigned int pop_and_resume(void);
// Suspend to the coroutine tag with no values
void suspend(void);
// Free an environment that was allocated by enqueue_a_coroutine
void free_env(env* env);

#endif // save_state_h_INCLUDED

