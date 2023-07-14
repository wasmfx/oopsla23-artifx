;;! target = "aarch64"
;;!
;;! settings = ['enable_heap_access_spectre_mitigation=true']
;;!
;;! compile = true
;;!
;;! [globals.vmctx]
;;! type = "i64"
;;! vmctx = true
;;!
;;! [globals.heap_base]
;;! type = "i64"
;;! load = { base = "vmctx", offset = 0, readonly = true }
;;!
;;! [globals.heap_bound]
;;! type = "i64"
;;! load = { base = "vmctx", offset = 8, readonly = true }
;;!
;;! [[heaps]]
;;! base = "heap_base"
;;! min_size = 0x10000
;;! offset_guard_size = 0xffffffff
;;! index_type = "i32"
;;! style = { kind = "dynamic", bound = "heap_bound" }

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i32 1)

  (func (export "do_store") (param i32 i32)
    local.get 0
    local.get 1
    i32.store8 offset=0x1000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load8_u offset=0x1000))

;; function u0:0:
;; block0:
;;   mov w10, w0
;;   ldr x11, [x2, #8]
;;   ldr x12, [x2]
;;   add x12, x12, x0, UXTW
;;   add x12, x12, #4096
;;   movz x13, #0
;;   subs xzr, x10, x11
;;   csel x11, x13, x12, hi
;;   csdb
;;   strb w1, [x11]
;;   b label1
;; block1:
;;   ret
;;
;; function u0:1:
;; block0:
;;   mov w10, w0
;;   ldr x11, [x1, #8]
;;   ldr x12, [x1]
;;   add x12, x12, x0, UXTW
;;   add x12, x12, #4096
;;   movz x13, #0
;;   subs xzr, x10, x11
;;   csel x11, x13, x12, hi
;;   csdb
;;   ldrb w0, [x11]
;;   b label1
;; block1:
;;   ret
