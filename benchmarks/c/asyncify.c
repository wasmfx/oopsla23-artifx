#include "stdbool.h"
#include "stdint.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"

void asyncify_start_unwind(int stack)
    __attribute__((__import_module__("asyncify"), __import_name__("start_unwind")));
void asyncify_stop_unwind(void)
    __attribute__((__import_module__("asyncify"), __import_name__("stop_unwind")));
void asyncify_start_rewind(int stack)
    __attribute__((__import_module__("asyncify"), __import_name__("start_rewind")));
void asyncify_stop_rewind(void)
    __attribute__((__import_module__("asyncify"), __import_name__("stop_rewind")));

void a_coroutine(void);

const unsigned int STACK_SIZE = 4096;

typedef struct asyncify_data {
    uint8_t* stack;
    uint8_t* stack_end;
    // This isn't actually part of the asyncify metadata, but i need it, and i
    // think it fits here
    bool suspended;
} asyncify_data;

asyncify_data* allocate_stack(void) {
    uint8_t* stack = malloc(sizeof(uint8_t) * STACK_SIZE);
    uint8_t* stack_end = stack + STACK_SIZE;
    asyncify_data* metadata = malloc(sizeof(asyncify_data));
    *metadata = (asyncify_data) {
        stack,
        stack_end,
        false,
    };
    return metadata;
}

void free_stack(asyncify_data* metadata) {
    free(metadata->stack);
    free(metadata);
}

// Queue exactly matching queue from wasmfx
asyncify_data** queue = NULL;
unsigned int qsize = 0;
unsigned int qfront = 0;
unsigned int qback = 0;
const unsigned int qdelta = 1000000;

asyncify_data* dequeue(void) {
    if (qfront == qback) {
        return NULL;
    } else {
        unsigned int i = qfront;
        qfront = i + 1;
        return queue[i];
    }
}

void enqueue(asyncify_data* stack) {
    if (qback == qsize) {
        if (qfront < qdelta) {
            // Space is below threshold, grow table instead
            qsize += 10;
            queue = realloc(queue, sizeof(asyncify_data*) * qsize);
        } else {
            // Enough space, move entries up to head of table
            qback = qback - qfront;
            memmove(queue, queue + qfront, sizeof(asyncify_data*) * qback);
            qfront = 0;
        }
    }
    queue[qback] = stack;
    qback += 1;
}

asyncify_data* unwind_stack;

// Enqueues a_coroutine to the queue and returns the number of currently
// enqueued routines
unsigned int enqueue_a_coroutine(void) {
    asyncify_data* stack = allocate_stack();
    enqueue(stack);
    return qback - qfront;
}
// Asyncify is weird, the functions at the ends of the stack get treated differently
__attribute__((noinline))
void first_resume(asyncify_data* stack) {
    a_coroutine();
    // TODO: We ASSUME that we'll suspend the first time!
    asyncify_stop_unwind();
}
__attribute__((noinline))
void resume_again(asyncify_data* stack) {
    asyncify_start_rewind((int)stack);
    // Quirk of asyncify: we actually still need to call the function,
    // start_rewind doesn't do it (weird!)
    a_coroutine();
    // TODO: We ASSUME that we'll return the second time!
    // (don't stop_unwind)
}
// Pop a coroutine off of the queue, resume it, assume it returns, and return
// the number of currently enqueued routines
unsigned int pop_and_resume(void) {
    asyncify_data* stack = dequeue();
    unwind_stack = stack;
    if (!stack->suspended) {
        first_resume(stack);
        stack->suspended = true;
        // TODO: We ASSUME that we'll suspend the first time!
        // This has more work to do, put it at the end of the queue
        enqueue(stack);
    } else {
        resume_again(stack);
        // TODO: We ASSUME that we'll return the second time!
        free_stack(stack);
    }
    return qback - qfront;
}
// Suspend to the coroutine tag with no values
__attribute__((noinline))
void suspend(void) {
    if (unwind_stack->suspended) {
        asyncify_stop_rewind();
    } else {
        asyncify_start_unwind((int)unwind_stack);
    }
}
