(module
  ;; NB this should use a shared memory when it's supported
  (memory 1)

  (func (export "32.load8u") (param i32) (result i32)
    local.get 0 i32.atomic.load8_u)
  (func (export "32.load16u") (param i32) (result i32)
    local.get 0 i32.atomic.load16_u)
  (func (export "32.load32u") (param i32) (result i32)
    local.get 0 i32.atomic.load)
  (func (export "64.load8u") (param i32) (result i64)
    local.get 0 i64.atomic.load8_u)
  (func (export "64.load16u") (param i32) (result i64)
    local.get 0 i64.atomic.load16_u)
  (func (export "64.load32u") (param i32) (result i64)
    local.get 0 i64.atomic.load32_u)
  (func (export "64.load64u") (param i32) (result i64)
    local.get 0 i64.atomic.load)

  (func (export "32.store8") (param i32)
    local.get 0 i32.const 0 i32.atomic.store8)
  (func (export "32.store16") (param i32)
    local.get 0 i32.const 0 i32.atomic.store16)
  (func (export "32.store32") (param i32)
    local.get 0 i32.const 0 i32.atomic.store)
  (func (export "64.store8") (param i32)
    local.get 0 i64.const 0 i64.atomic.store8)
  (func (export "64.store16") (param i32)
    local.get 0 i64.const 0 i64.atomic.store16)
  (func (export "64.store32") (param i32)
    local.get 0 i64.const 0 i64.atomic.store32)
  (func (export "64.store64") (param i32)
    local.get 0 i64.const 0 i64.atomic.store)

  (func (export "32.load8u o1") (param i32) (result i32)
    local.get 0 i32.atomic.load8_u offset=1)
  (func (export "32.load16u o1") (param i32) (result i32)
    local.get 0 i32.atomic.load16_u offset=1)
  (func (export "32.load32u o1") (param i32) (result i32)
    local.get 0 i32.atomic.load offset=1)
  (func (export "64.load8u o1") (param i32) (result i64)
    local.get 0 i64.atomic.load8_u offset=1)
  (func (export "64.load16u o1") (param i32) (result i64)
    local.get 0 i64.atomic.load16_u offset=1)
  (func (export "64.load32u o1") (param i32) (result i64)
    local.get 0 i64.atomic.load32_u offset=1)
  (func (export "64.load64u o1") (param i32) (result i64)
    local.get 0 i64.atomic.load offset=1)

  (func (export "32.store8 o1") (param i32)
    local.get 0 i32.const 0 i32.atomic.store8 offset=1)
  (func (export "32.store16 o1") (param i32)
    local.get 0 i32.const 0 i32.atomic.store16 offset=1)
  (func (export "32.store32 o1") (param i32)
    local.get 0 i32.const 0 i32.atomic.store offset=1)
  (func (export "64.store8 o1") (param i32)
    local.get 0 i64.const 0 i64.atomic.store8 offset=1)
  (func (export "64.store16 o1") (param i32)
    local.get 0 i64.const 0 i64.atomic.store16 offset=1)
  (func (export "64.store32 o1") (param i32)
    local.get 0 i64.const 0 i64.atomic.store32 offset=1)
  (func (export "64.store64 o1") (param i32)
    local.get 0 i64.const 0 i64.atomic.store offset=1)
)

;; aligned loads
(assert_return (invoke "32.load8u" (i32.const 0)) (i32.const 0))
(assert_return (invoke "32.load16u" (i32.const 0)) (i32.const 0))
(assert_return (invoke "32.load32u" (i32.const 0)) (i32.const 0))
(assert_return (invoke "64.load8u" (i32.const 0)) (i64.const 0))
(assert_return (invoke "64.load16u" (i32.const 0)) (i64.const 0))
(assert_return (invoke "64.load64u" (i32.const 0)) (i64.const 0))
(assert_return (invoke "32.load8u o1" (i32.const 0)) (i32.const 0))
(assert_return (invoke "32.load16u o1" (i32.const 1)) (i32.const 0))
(assert_return (invoke "32.load32u o1" (i32.const 3)) (i32.const 0))
(assert_return (invoke "64.load8u o1" (i32.const 0)) (i64.const 0))
(assert_return (invoke "64.load16u o1" (i32.const 1)) (i64.const 0))
(assert_return (invoke "64.load32u o1" (i32.const 3)) (i64.const 0))
(assert_return (invoke "64.load64u o1" (i32.const 7)) (i64.const 0))

;; misaligned loads
(assert_return (invoke "32.load8u" (i32.const 1)) (i32.const 0))
(assert_trap (invoke "32.load16u" (i32.const 1)) "unaligned atomic")
(assert_trap (invoke "32.load32u" (i32.const 1)) "unaligned atomic")
(assert_return (invoke "64.load8u" (i32.const 1)) (i64.const 0))
(assert_trap (invoke "64.load16u" (i32.const 1)) "unaligned atomic")
(assert_trap (invoke "64.load32u" (i32.const 1)) "unaligned atomic")
(assert_trap (invoke "64.load64u" (i32.const 1)) "unaligned atomic")
(assert_return (invoke "32.load8u o1" (i32.const 0)) (i32.const 0))
(assert_trap (invoke "32.load16u o1" (i32.const 0)) "unaligned atomic")
(assert_trap (invoke "32.load32u o1" (i32.const 0)) "unaligned atomic")
(assert_return (invoke "64.load8u o1" (i32.const 0)) (i64.const 0))
(assert_trap (invoke "64.load16u o1" (i32.const 0)) "unaligned atomic")
(assert_trap (invoke "64.load32u o1" (i32.const 0)) "unaligned atomic")
(assert_trap (invoke "64.load64u o1" (i32.const 0)) "unaligned atomic")

;; aligned stores
(assert_return (invoke "32.store8" (i32.const 0)))
(assert_return (invoke "32.store16" (i32.const 0)))
(assert_return (invoke "32.store32" (i32.const 0)))
(assert_return (invoke "64.store8" (i32.const 0)))
(assert_return (invoke "64.store16" (i32.const 0)))
(assert_return (invoke "64.store64" (i32.const 0)))
(assert_return (invoke "32.store8 o1" (i32.const 0)))
(assert_return (invoke "32.store16 o1" (i32.const 1)))
(assert_return (invoke "32.store32 o1" (i32.const 3)))
(assert_return (invoke "64.store8 o1" (i32.const 0)))
(assert_return (invoke "64.store16 o1" (i32.const 1)))
(assert_return (invoke "64.store32 o1" (i32.const 3)))
(assert_return (invoke "64.store64 o1" (i32.const 7)))

;; misaligned stores
(assert_return (invoke "32.store8" (i32.const 1)))
(assert_trap (invoke "32.store16" (i32.const 1)) "unaligned atomic")
(assert_trap (invoke "32.store32" (i32.const 1)) "unaligned atomic")
(assert_return (invoke "64.store8" (i32.const 1)))
(assert_trap (invoke "64.store16" (i32.const 1)) "unaligned atomic")
(assert_trap (invoke "64.store32" (i32.const 1)) "unaligned atomic")
(assert_trap (invoke "64.store64" (i32.const 1)) "unaligned atomic")
(assert_return (invoke "32.store8 o1" (i32.const 0)))
(assert_trap (invoke "32.store16 o1" (i32.const 0)) "unaligned atomic")
(assert_trap (invoke "32.store32 o1" (i32.const 0)) "unaligned atomic")
(assert_return (invoke "64.store8 o1" (i32.const 0)))
(assert_trap (invoke "64.store16 o1" (i32.const 0)) "unaligned atomic")
(assert_trap (invoke "64.store32 o1" (i32.const 0)) "unaligned atomic")
(assert_trap (invoke "64.store64 o1" (i32.const 0)) "unaligned atomic")
