#include "stdint.h"
#include "stdio.h"

#include "parameters.h"
#include "save_state.h"

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

int count = 0;
volatile void* black_box;
volatile int black_box_int;

void big_function(env* env) {
    int stuff[1024];
    black_box = stuff;
    stuff[1023] = 9;
    black_box = NULL;
}

// TODO: We don't actually have any state, so this isn't fair
void a_coroutine(env* env) {
    // suspend(\env -> more...) without lambda
    if (!env->suspended) {
        count++;
        env->save_for_later = count;
        suspend();
    } else {
        big_function(env);
        black_box_int = env->save_for_later;
        free_env(env);
    }
}

int main(int argc, char** argv) {
    for (unsigned int total_coroutines=0; total_coroutines<NUM_COROUTINES; ++total_coroutines) {
        unsigned int simul = enqueue_a_coroutine();
        while (simul > NUM_SIMULTANEOUS) {
            simul = pop_and_resume();
        }
    }
    while (pop_and_resume() > 0) {
        // Keep popping until there are no remaining coroutines
    }
    printf("%i threads run!\n", count);
    printf("%p is our final black box pointer!\n", black_box);
    printf("%i is our final black box int!\n", black_box_int);
    return 0;
}
