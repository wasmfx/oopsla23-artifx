#include <stdio.h>
#include "parameters.h"

// Enqueues a_coroutine to the queue (defined in assembly) and returns the
// number of currently enqueued routines
unsigned int enqueue_a_coroutine(void);
// Pop a coroutine off of the queue, resume it, assume it returns, and return
// the number of currently enqueued routines
unsigned int pop_and_resume(void);
// Suspend to the coroutine tag with no values
void suspend(void);

int count = 0;
volatile void* black_box;
volatile int black_box_int;

void big_function(void) {
    int stuff[1024];
    black_box = stuff;
    stuff[1023] = 9;
    black_box = NULL;
}

void a_coroutine(void) {
    count++;
    int save_for_later = count;
    suspend();
    big_function();
    black_box_int = save_for_later;
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
