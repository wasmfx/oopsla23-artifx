// Fiber-based implementation of the primitive operations.

#include <stdlib.h>
#include <stdint.h>
#include <fiber.h>

#include "parameters.h"

static fiber_t store[active_conn];

extern
__attribute__((import_module("env"),import_name("async_worker")))
void* async_worker(void*);

__attribute__((noinline))
__attribute__((export_name("alloc_async_worker")))
void alloc_async_worker(uint32_t key) {
  store[key] = fiber_alloc(async_worker);
}

__attribute__((noinline))
__attribute__((export_name("resume_async_worker")))
uint32_t resume_async_worker(uint32_t key, uint32_t arg) {
  fiber_result_t status;
  return (uint32_t)fiber_resume(store[key], (void*)((intptr_t)arg), &status);
}

__attribute__((noinline))
__attribute__((export_name("async_worker_yield")))
uint32_t async_worker_yield(uint32_t arg) {
  return (uint32_t)fiber_yield((void*)((intptr_t)arg));
}

__attribute__((noinline))
__attribute__((export_name("free_async_worker")))
void free_async_worker(uint32_t key) {
  fiber_free(store[key]);
}
