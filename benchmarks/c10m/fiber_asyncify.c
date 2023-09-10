// An asyncify implementation of the basic fiber interface.

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#include "fiber.h"

/** Asyncify imports **/
// The following functions are asyncify primitives:
// * asyncify_start_unwind(iptr): initiates a continuation
//   capture. The argument `iptr` is a pointer to an asyncify stack.
// * asyncify_stop_unwind(): delimits a capture continuations.
// * asyncify_start_rewind(iptr): initiates a continuation
//   reinstatement. The argument `iptr` is a pointer to an asyncify
//   stack.
// * asyncfiy_stop_rewind(): delimits the extent of a continuation
//  reinstatement.
extern
__attribute__((__import_module__("asyncify"), __import_name__("start_unwind")))
void asyncify_start_unwind(void*);

extern
__attribute__((__import_module__("asyncify"), __import_name__("stop_unwind")))
void asyncify_stop_unwind(void);

extern
__attribute__((__import_module__("asyncify"), __import_name__("start_rewind")))
void asyncify_start_rewind(void*);

extern
__attribute__((__import_module__("asyncify"), __import_name__("stop_rewind")))
void asyncify_stop_rewind(void);

// We track the currently active fiber via this global variable.
static volatile fiber_t active_fiber = NULL;

// Fiber states:
// * ACTIVE: the fiber is actively executing.
// * YIELDING: the fiber is suspended.
// * DONE: the fiber is finished (i.e. run to completion).
typedef enum { ACTIVE, YIELDING, DONE } fiber_state_t;

// A fiber stack is an asyncify stack, i.e. a reserved area of memory
// for asyncify to store the call chain and locals. Note: asyncify
// assumes `end` is at offset 4. Moreover, asyncify stacks grow
// upwards, so it must be that top <= end.
struct  __attribute__((packed)) fiber_stack {
  uint8_t *top;
  uint8_t *end;
  /* uint8_t *unwound; */
  uint8_t *buffer;
};
static_assert(sizeof(uint8_t*) == 4, "sizeof(uint8_t*) != 4");
static_assert(sizeof(struct fiber_stack) == 12, "struct fiber_stack: No padding allowed");

// The fiber structure embeds the asyncify stack (struct fiber_stack),
// its state, an entry point, and two buffers for communicating
// payloads and managing fiber local data, respectively.
struct fiber {
  /** The underlying asyncify stack. */
  struct fiber_stack stack;
  // Fiber state.
  fiber_state_t state;
  // Initial function to run on the fiber.
  fiber_entry_point_t entry;
  // Payload buffer.
  void *arg;
};

// Allocates a fiber stack of size stack_size.
static
__attribute__((noinline))
struct fiber_stack fiber_stack_alloc(size_t stack_size) {
  uint8_t *buffer = malloc(sizeof(uint8_t) * stack_size);
  uint8_t *top = buffer;
  uint8_t *end = buffer + stack_size;
  struct fiber_stack stack = (struct fiber_stack) { top, end, /* NULL, */ buffer };
  return stack;
}

// Frees an allocated fiber_stack.
static
__attribute__((noinline))
void fiber_stack_free(struct fiber_stack fiber_stack) {
  free(fiber_stack.buffer);
}

// Allocates a fiber object.
// NOTE: the entry point `fn` should be careful about uses of `printf`
// and related functions, as they can cause asyncify to corrupt its
// own state. See `wasi-io.h` for asyncify-safe printing functions.
__attribute__((noinline))
fiber_t fiber_sized_alloc(size_t stack_size, fiber_entry_point_t entry) {
  fiber_t fiber = (fiber_t)malloc(sizeof(struct fiber));
  fiber->stack = fiber_stack_alloc(stack_size);
  fiber->state = ACTIVE;
  fiber->entry = entry;
  fiber->arg = NULL;
  return fiber;
}

// Allocates a fiber object with the default stack size.
__attribute__((noinline))
fiber_t fiber_alloc(fiber_entry_point_t entry) {
  return fiber_sized_alloc(FIBER_DEFAULT_STACK_SIZE, entry);
}

// Frees a fiber object.
__attribute__((noinline))
void fiber_free(fiber_t fiber) {
  fiber_stack_free(fiber->stack);
  free(fiber);
}

// Yields control from within a fiber computation to whichever point
// originally resumed the fiber.
__attribute__((noinline))
__attribute__((export_name("fiber_yield")))
void* fiber_yield(void *arg) {
  if (active_fiber->state == YIELDING) {
    asyncify_stop_rewind();
    active_fiber->state = ACTIVE;
    return active_fiber->arg;
  } else {
    active_fiber->arg = arg;
    active_fiber->state = YIELDING;
    asyncify_start_unwind(&active_fiber->stack);
    return NULL; // dummy value; this statement never gets executed.
  }
}

/* static */
/* __attribute__((noinline)) */
/* void fiber_stack_note_unwound(struct fiber_stack* stack) { */
/*   stack->unwound = stack->top; */
/* } */

/* static */
/* __attribute__((noinline)) */
/* void fiber_stack_rewind(struct fiber_stack* stack) { */
/*   stack->top = stack->unwound; */
/* } */

// Resumes a given fiber. Control is transferred to the fiber.
__attribute__((noinline))
__attribute__((export_name("fiber_resume")))
void* fiber_resume(fiber_t fiber, void *arg, fiber_result_t *result) {
  // If we are done, signal error and return.
  if (fiber->state == DONE) {
    *result = FIBER_ERROR;
    return NULL;
  }

  // Remember the currently executing fiber.
  volatile fiber_t prev = active_fiber;
  // Set the given fiber as the actively executing fiber.
  active_fiber = fiber;

  // If we are resuming a suspended fiber...
  if (fiber->state == YIELDING) {
    // ... then update the argument buffer.
    fiber->arg = arg;
    // ... and initiate the stack rewind.
    //fiber_stack_rewind(&fiber->stack);
    asyncify_start_rewind(&fiber->stack);
  }

  // Run the entry function. Note: the entry function must be run
  // first both when the fiber is started and resumed!
  void *fiber_result = fiber->entry(arg);
  // The following function delimits the effects of fiber_yield.
  asyncify_stop_unwind();
  //fiber_stack_note_unwound(&fiber->stack);
  // Check whether the fiber finished or suspended.
  if (fiber->state != YIELDING)
    fiber->state = DONE;

  // Restore the previously executing fiber.
  active_fiber = prev;
  // Signal success.
  *result = fiber->state == YIELDING ? FIBER_YIELD : FIBER_OK;
  return fiber->state == YIELDING ? fiber->arg : fiber_result;

}
