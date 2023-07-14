use v6;

my $file = slurp;

# Gather some types that we use
$file ~~ rx:sigspace/\(type \(\;(\d+)\;\) \(func\)\)/;
my $unit_unit = $0;
$file ~~ rx:sigspace/\(type \(\;(\d+)\;\) \(func \(param i32\)\)\)/;
my $i32_unit = $0;
$file ~~ rx:sigspace/\(type \(\;(\d+)\;\) \(func \(param i32 i32\)\)\)/;
my $i32_i32_unit = $0;

# Your program must use a dummy function to print:
# 
# ```go
# //go:noinline
# func wrappedPrint(thething int32) {
#     println(thething)
# }
# ```

# It has to actually print to prevent optimization. In the generated wat replace
# $main.wrappedPrint

# $file ~~ s:sigspace/
#   \(func \$main.wrappedPrint .*unreachable\)/
#   (func \$main.wrappedPrint (param i32)
#     (call \$spectest_print (local.get 0)))/;

# # The following is useful only if avoiding wasi
# # Remove the fd_write import and add
# 
# $file ~~ s:sigspace/
#   \(import \"wasi_snapshot_preview1\" \"fd_write\" \(func \$runtime.fd_write.*?\)\)\)/
#   (import "spectest" "print_i32" (func \$spectest_print (param i32)))/;
# 
# # And replace the fd_write call (in panic stuff) with unreachable
# $file ~~ s:sigspace/
#         call .runtime.fd_write/
#         unreachable/;

# Remove the asyncify imports that we're obseleting
$file ~~ s:sigspace/\n
  \(import \"asyncify\" \"stop_rewind\" .* \"start_rewind\" \(func \$start_rewind .*?\)\)\)//;

# Add our types and tag
$file ~~ s:sigspace/\n
  \(func/
  (type \$asyncify_resume_cont (cont REPLACE_EMPTY))
  (type \$asyncify_call_indirect_cont (cont REPLACE_I32_I32))
  (tag \$asyncify_effect)
  (func/;

# Replace `REPLACE_EMPTY` with the index for (func) and `REPLACE_I32_I32` with
# the index for (i32, i32) -> ().
$file ~~ s/REPLACE_EMPTY/$unit_unit/;
$file ~~ s/REPLACE_I32_I32/$i32_i32_unit/;

# for some reason putting this as a variable makes it work, the literal doesn't
# To accomodate a later new table entry, expand the table
# size, (table ...) just above it, in this case from 6 to 7 (adjust both numbers).
my $replacement = Q[
  ;; Table as simple queue (keeping it simple, no ring buffer)
  (table $queue 0 (ref null $asyncify_resume_cont))
  (global $qdelta i32 (i32.const 10))
  (global $qback (mut i32) (i32.const 0))
  (global $qfront (mut i32) (i32.const 0))

  (func $queue-empty (result i32)
    (i32.eq (global.get $qfront) (global.get $qback))
  )

  (func $dequeue (result (ref null $asyncify_resume_cont))
    (local $i i32)
    (if (call $queue-empty)
      (then (return (ref.null $asyncify_resume_cont)))
    )
    (local.set $i (global.get $qfront))
    (global.set $qfront (i32.add (local.get $i) (i32.const 1)))
    (table.get $queue (local.get $i))
  )

  (func $enqueue (param $k (ref $asyncify_resume_cont))
    ;; Check if queue is full
    (if (i32.eq (global.get $qback) (table.size $queue))
      (then
        ;; Check if there is enough space in the front to compact
        (if (i32.lt_u (global.get $qfront) (global.get $qdelta))
          (then
            ;; Space is below threshold, grow table instead
            (drop (table.grow $queue (ref.null $asyncify_resume_cont) (global.get $qdelta)))
          )
          (else
            ;; Enough space, move entries up to head of table
            (global.set $qback (i32.sub (global.get $qback) (global.get $qfront)))
            (table.copy $queue $queue
              (i32.const 0)         ;; dest = new front = 0
              (global.get $qfront)  ;; src = old front
              (global.get $qback)   ;; len = new back = old back - old front
            )
            (table.fill $queue      ;; null out old entries to avoid leaks
              (global.get $qback)   ;; start = new back
              (ref.null $asyncify_resume_cont)      ;; init value
              (global.get $qfront)  ;; len = old front = old front - new front
            )
            (global.set $qfront (i32.const 0))
          )
        )
      )
    )
    (table.set $queue (global.get $qback) (local.get $k))
    (global.set $qback (i32.add (global.get $qback) (i32.const 1)))
  )];

$file ~~ s:sigspace/
  \(table .*? (\d+) \d+ funcref\)/(table {$0+1} {$0+1} funcref)\n$replacement/;

$replacement = Q[
  (func $runtime.scheduler
    (local i32)
    block  ;; label = @1
      loop  ;; label = @2
        i32.const 0
        i32.load8_u offset=65973
        ;; check schedulerDone (which gets set at end of main)
        br_if 1 (;@1;)
        ;; pop the queue and resume the continuation
        call $dequeue
        br_on_null 1
        (block $coroutine_suspend (param (ref $asyncify_resume_cont)) (result (ref $asyncify_resume_cont))
          (resume $asyncify_resume_cont
            (tag $asyncify_effect $coroutine_suspend))
          ;; it suspended, so continue without re-enqueuing
          br 1)
        ;; re-enqeue the coroutine. tinygo makes this the coroutine's job, but
        ;; we make it the scheduler's job
        call $enqueue
        br 0 (;@2;)
      end
      unreachable
    end)];

$file ~~ s:sigspace/
  \(func \$runtime.scheduler.*?
    (end|unreachable)\)/$replacement/;

$replacement = Q[
  (func $runtime.minSched
    call $runtime.scheduler)];

$file ~~ s:sigspace/
  \(func \$runtime.minSched.*?
    end\)/$replacement/;

# Replace the existing queue.
# Delete `$_*internal/task.Task_.Resume`.

$replacement = Q[
  (func $_*internal/task.Queue_.Pop (result i32) unreachable)
  (func $_*internal/task.Queue_.Push (param i32))];

$file ~~ s:sigspace/
  \(func \$_\*internal\/task.Queue_.Pop.*
  \(func \$_\*internal\/task.Task_.Resume.*?
    unreachable\)/$replacement/;


# Delete `tinygo_unwind`, `tinygo_launch`, `tinygo_rewind` (all next to each
# other).

$file ~~ s:sigspace/
  \(func \$tinygo_unwind.*
  \(func \$tinygo_rewind.*?
    return\)//;

# Replace Pause with a simple suspend:

$replacement = Q[
  (func $internal/task.Pause
    suspend $asyncify_effect)];

$file ~~ s:sigspace/
  \(func \$internal\/task.Pause.*?
    i32.store\)/$replacement/;

# Find $internal/task.start. Starting with call `$enqueue_fn_args`, we *replace*
# the call and the rest of the function with this code:
# This depends on a function that reifies call_indirect.

$replacement = Q[
    (cont.new $asyncify_call_indirect_cont (ref.func $asyncify_call_indirect))
    (cont.bind $asyncify_call_indirect_cont $asyncify_resume_cont)
    call $enqueue)
  (func $asyncify_call_indirect (param i32) (param i32)
    (call_indirect (type REPLACE_TYPE) (local.get 1) (local.get 0)))];

$file ~~ s:sigspace/(
  \(func .internal.task.start.*?)
    call .enqueue_fn_args.*?
    global.set .__stack_pointer\)/$0$replacement/;

# Above we reference (type REPLACE_TYPE). Replace with the index of the (i32) ->
# () from the top of the file.
$file ~~ s/REPLACE_TYPE/$i32_unit/;

# Now you need to add the new `$asyncify_call_indirect` function to the elements
# (elem ...) at the very bottom.

$file ~~ s:sigspace/
  (\(elem (\(\;0\;\))? \(i32.const 1\) .*?)\)/
  $0 \$asyncify_call_indirect\)/;

say $file;
