//! The unix fiber implementation has some platform-specific details
//! (naturally) but there's a few details of the stack layout which are common
//! amongst all platforms using this file. Remember that none of this applies to
//! Windows, which is entirely separate.
//!
//! The stack is expected to look pretty standard with a guard page at the end.
//! Currently allocation happens in this file but this is probably going to be
//! refactored to happen somewhere else. Otherwise though the stack layout is
//! expected to look like so:
//!
//!
//! ```text
//! 0xB000 +-----------------------+   <- top of stack
//!        | &Cell<RunResult>      |   <- where to store results
//! 0xAff8 +-----------------------+
//!        | *const u8             |   <- last sp to resume from
//! 0xAff0 +-----------------------+   <- 16-byte aligned
//!        |                       |
//!        ~        ...            ~   <- actual native stack space to use
//!        |                       |
//! 0x1000 +-----------------------+
//!        |  guard page           |
//! 0x0000 +-----------------------+
//! ```
//!
//! Here `0xAff8` is filled in temporarily while `resume` is running. The fiber
//! started with 0xB000 as a parameter so it knows how to find this.
//! Additionally `resumes` stores state at 0xAff0 to restart execution, and
//! `suspend`, which has 0xB000 so it can find this, will read that and write
//! its own resumption information into this slot as well.

#![allow(unused_macros)]

use crate::RunResult;
use std::alloc::{alloc, dealloc, Layout};
use std::cell::Cell;
use std::io;
use std::ops::Range;
use std::ptr;

#[derive(Debug)]
pub struct FiberStack {
    // The top of the stack; for stacks allocated by the fiber implementation itself,
    // the base address of the allocation will be `top.sub(len.unwrap())`
    top: *mut u8,
    // The length of the stack
    len: usize,
    // whether or not this stack was mmap'd
    mmap: bool,
}

impl FiberStack {
    pub fn new(size: usize) -> io::Result<Self> {
        // Round up our stack size request to the nearest multiple of the
        // page size.
        let page_size = rustix::param::page_size();
        let size = if size == 0 {
            page_size
        } else {
            (size + (page_size - 1)) & (!(page_size - 1))
        };

        unsafe {
            // Add in one page for a guard page and then ask for some memory.
            let mmap_len = size + page_size;
            let mmap = rustix::mm::mmap_anonymous(
                ptr::null_mut(),
                mmap_len,
                rustix::mm::ProtFlags::empty(),
                rustix::mm::MapFlags::PRIVATE,
            )?;

            rustix::mm::mprotect(
                mmap.cast::<u8>().add(page_size).cast(),
                size,
                rustix::mm::MprotectFlags::READ | rustix::mm::MprotectFlags::WRITE,
            )?;

            Ok(Self {
                top: mmap.cast::<u8>().add(mmap_len),
                len: mmap_len,
                mmap: true,
            })
        }
    }

    pub fn malloc(size: usize) -> io::Result<Self> {
        unsafe {
            let layout = Layout::array::<u8>(size).unwrap();
            let base = alloc(layout);
            FiberStack::from_raw_parts(base, size)
        }
    }

    pub unsafe fn from_raw_parts(base: *mut u8, len: usize) -> io::Result<Self> {
        Ok(Self {
            top: base.add(len),
            len,
            mmap: false,
        })
    }

    pub fn top(&self) -> Option<*mut u8> {
        Some(self.top)
    }

    pub unsafe fn parent(&self) -> *mut u8 {
        self.top.cast::<*mut u8>().offset(-2).read()
    }

    pub unsafe fn write_parent(&self, tsp: *mut u8) {
        self.top.cast::<*mut u8>().offset(-2).write(tsp);
    }

    pub fn range(&self) -> Option<Range<usize>> {
        let base = unsafe { self.top.sub(self.len) as usize };
        Some(base..base + self.len)
    }
}

impl Drop for FiberStack {
    fn drop(&mut self) {
        unsafe {
            if self.mmap {
                let ret = rustix::mm::munmap(self.top.sub(self.len) as _, self.len);
                debug_assert!(ret.is_ok());
            } else {
                let layout = Layout::array::<u8>(self.len).unwrap();
                dealloc(self.top.sub(self.len), layout);
            }
        }
    }
}

pub struct Fiber;

pub struct Suspend(*mut u8);

extern "C" {
    fn wasmtime_fibre_init(
        top_of_stack: *mut u8,
        entry: extern "C" fn(*mut u8, *mut u8),
        entry_arg0: *mut u8,
    );
    fn wasmtime_fibre_switch(top_of_stack: *mut u8);
    #[allow(dead_code)] // only used in inline assembly for some platforms
    fn wasmtime_fibre_start();
}

extern "C" fn fiber_start<F, A, B, C>(arg0: *mut u8, top_of_stack: *mut u8)
where
    F: FnOnce(A, &super::Suspend<A, B, C>) -> C,
{
    unsafe {
        let inner = Suspend(top_of_stack);
        let initial = inner.take_resume::<A, B, C>();
        super::Suspend::<A, B, C>::execute(inner, initial, Box::from_raw(arg0.cast::<F>()))
    }
}

impl Fiber {
    pub fn new<F, A, B, C>(stack: &FiberStack, func: F) -> io::Result<Self>
    where
        F: FnOnce(A, &super::Suspend<A, B, C>) -> C,
    {
        unsafe {
            let data = Box::into_raw(Box::new(func)).cast();
            wasmtime_fibre_init(stack.top, fiber_start::<F, A, B, C>, data);
        }

        Ok(Self)
    }

    pub(crate) fn resume<A, B, C>(&self, stack: &FiberStack, result: &Cell<RunResult<A, B, C>>) {
        unsafe {
            // Store where our result is going at the very tip-top of the
            // stack, otherwise known as our reserved slot for this information.
            //
            // In the diagram above this is updating address 0xAff8
            let addr = stack.top.cast::<usize>().offset(-1);
            addr.write(result as *const _ as usize);

            wasmtime_fibre_switch(stack.top);

            // null this out to help catch use-after-free
            addr.write(0);
        }
    }
}

impl Suspend {
    pub fn switch<A, B, C>(&self, result: RunResult<A, B, C>) -> A {
        unsafe {
            // Calculate 0xAff8 and then write to it
            (*self.result_location::<A, B, C>()).set(result);
            wasmtime_fibre_switch(self.0);
            self.take_resume::<A, B, C>()
        }
    }

    unsafe fn take_resume<A, B, C>(&self) -> A {
        match (*self.result_location::<A, B, C>()).replace(RunResult::Executing) {
            RunResult::Resuming(val) => val,
            _ => panic!("not in resuming state"),
        }
    }

    unsafe fn result_location<A, B, C>(&self) -> *const Cell<RunResult<A, B, C>> {
        let ret = self.0.cast::<*const u8>().offset(-1).read();
        assert!(!ret.is_null());
        ret.cast()
    }

    pub fn from_top_ptr(ptr: *mut u8) -> Self {
        Suspend(ptr)
    }
}

cfg_if::cfg_if! {
    if #[cfg(target_arch = "x86_64")] {
        mod x86_64;
    } else {
        compile_error!("fibers are not supported on this CPU architecture");
    }
}
