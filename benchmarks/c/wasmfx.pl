use v6;

my $file = slurp;

# Gather some types that we use
$file ~~ rx:sigspace/\(type \(\;(\d+)\;\) \(func\)\)/;
my $unit_unit = $0;
$file ~~ rx:sigspace/\(type \(\;(\d+)\;\) \(func \(param i32\)\)\)/;
my $i32_unit = $0;
$file ~~ rx:sigspace/\(type \(\;(\d+)\;\) \(func \(param i32 i32\)\)\)/;
my $i32_i32_unit = $0;
$file ~~ rx:sigspace/\(export \"a_coroutine\" \(func (\d+)\)\)/;
my $a_coroutine_idx = $0;

# We remove each import, capturing the index that was assigned to it to
# transform calls. We replace each import with a placeholder to keep indices
# the same
$file ~~ s:sigspace/\n
  \(import \"env\" \"enqueue_a_coroutine\" \(func \(\;(\d+)\;\) \(type \d+\)\)\)/
  (import "wasi_snapshot_preview1" "proc_exit" (func (type $i32_unit)))/;
my $enqueue_a_coroutine_idx = $0;
$file ~~ s:sigspace/\n
  \(import \"env\" \"pop_and_resume\" \(func \(\;(\d+)\;\) \(type \d+\)\)\)/
  (import "wasi_snapshot_preview1" "proc_exit" (func (type $i32_unit)))/;
my $pop_and_resume_idx = $0;
$file ~~ s:sigspace/\n
  \(import \"env\" \"suspend\" \(func \(\;(\d+)\;\) \(type \d+\)\)\)/
  (import "wasi_snapshot_preview1" "proc_exit" (func (type $i32_unit)))/;
my $suspend_idx = $0;

# Add a single () -> () tag
$file ~~ s:sigspace/\n
  \(func/
  (type \$coroutine (cont $unit_unit))
  (func/;

# suspend becomes suspend using our tag
$file ~~ s:g:sigspace/call $suspend_idx>>/suspend \$scheduler/;
# The other calls call into our runtime below
$file ~~ s:g:sigspace/call $enqueue_a_coroutine_idx>>/call \$enqueue_a_coroutine/;
$file ~~ s:g:sigspace/call $pop_and_resume_idx>>/call \$pop_and_resume/;

my $replacement = Q[
  (tag $scheduler)

  ;; Table as simple queue (keeping it simple, no ring buffer)
  (table $queue 1000000 (ref null $coroutine))
  (global $qdelta i32 (i32.const 10))
  (global $qback (mut i32) (i32.const 0))
  (global $qfront (mut i32) (i32.const 0))

  (func $queue-empty (result i32)
    (i32.eq (global.get $qfront) (global.get $qback))
  )

  (func $dequeue (result (ref null $coroutine))
    (local $i i32)
    (if (call $queue-empty)
      (then (return (ref.null $coroutine)))
    )
    (local.set $i (global.get $qfront))
    (global.set $qfront (i32.add (local.get $i) (i32.const 1)))
    (table.get $queue (local.get $i))
  )

  (func $enqueue (param $k (ref $coroutine))
    ;; Check if queue is full
    (if (i32.eq (global.get $qback) (table.size $queue))
      (then
        ;; Check if there is enough space in the front to compact
        (if (i32.lt_u (global.get $qfront) (global.get $qdelta))
          (then
            ;; Space is below threshold, grow table instead
            (drop (table.grow $queue (ref.null $coroutine) (global.get $qdelta)))
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
              (ref.null $coroutine)      ;; init value
              (global.get $qfront)  ;; len = old front = old front - new front
            )
            (global.set $qfront (i32.const 0))
          )
        )
      )
    )
    (table.set $queue (global.get $qback) (local.get $k))
    (global.set $qback (i32.add (global.get $qback) (i32.const 1)))
  )

  (func $enqueue_a_coroutine (result i32)
   ref.func A_COROUTINE_IDX
   cont.new $coroutine
   call $enqueue
   (i32.sub (global.get $qback) (global.get $qfront)))
  (func $pop_and_resume (result i32)
   (block $returned
     (block $suspended (result (ref $coroutine))
       call $dequeue
       resume $coroutine (tag $scheduler $suspended)
       br $returned)
     call $enqueue)
   (i32.sub (global.get $qback) (global.get $qfront)))
  (export];
$file ~~ s:sigspace/^^  \(export/$replacement/;
$file ~~ s/A_COROUTINE_IDX/$a_coroutine_idx/;

# Now you need to add the new `$asyncify_call_indirect` function to the elements
# (elem ...) at the very bottom.

#$file ~~ s:sigspace/
#  (\(elem (\(\;0\;\))? \(i32.const 1\) .*?)\)/
#  $0 \$asyncify_call_indirect\)/;

say $file;
