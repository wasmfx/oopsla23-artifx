#include "stdbool.h"
#include "stdint.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"

#include "save_state.h"

void a_coroutine(env* env);

const unsigned int ENV_SIZE = 2048;
env* allocate_env(void) {
    env* tenv = malloc(sizeof(env));
    *tenv = (env) {
        false,
    };
    return tenv;
}
void free_env(env* env) {
    free(env);
}

// Queue exactly matching queue from wasmfx (copied from asyncify.c)
env** queue = NULL;
unsigned int qsize = 0;
unsigned int qfront = 0;
unsigned int qback = 0;
const unsigned int qdelta = 10;

env* dequeue(void) {
    if (qfront == qback) {
        return NULL;
    } else {
        unsigned int i = qfront;
        qfront = i + 1;
        return queue[i];
    }
}

void enqueue(env* stack) {
    if (qback == qsize) {
        if (qfront < qdelta) {
            // Space is below threshold, grow table instead
            qsize += 10;
            queue = realloc(queue, sizeof(env*) * qsize);
        } else {
            // Enough space, move entries up to head of table
            qback = qback - qfront;
            memmove(queue, queue + qfront, sizeof(env*) * qback);
            qfront = 0;
        }
    }
    queue[qback] = stack;
    qback += 1;
}

env* current_env;

// Enqueues a_coroutine to the queue (defined in assembly) and returns the
// number of currently enqueued routines
unsigned int enqueue_a_coroutine(void) {
    env* empty = allocate_env();
    enqueue(empty);
    return qback - qfront;
}
// Pop a coroutine off of the queue, resume it, assume it returns, and return
// the number of currently enqueued routines
unsigned int pop_and_resume(void) {
    current_env = dequeue();
    a_coroutine(current_env);
    return qback - qfront;
}
// Suspend to the coroutine tag with no values
void suspend(void) {
    current_env->suspended = true;
    enqueue(current_env);
}

