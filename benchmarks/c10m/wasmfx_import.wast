;; WasmFX implementation of the abstract async worker operations

(module $wasmfx_import
  (type $awt (func (param i32) (result i32)))
  (type $cawt (cont $awt))

  (tag $yield (param i32) (result i32))

  (table $conts 10000 (ref null $cawt)) ;; Update size to match dataset size.

  (elem declare func $async_worker_yield)
  (elem declare func $alloc_async_worker)
  (elem declare func $resume_async_worker)
  (elem declare func $free_async_worker)

  ;; (elem declare func $store_put)
  ;; (elem declare func $store_get)

  (elem declare func $async_worker) ;; NOTE(dhil): remove from assembled binary.

  ;; (func $store_get (export "store_get") (param $key i32) (result (ref null $cawt))
  ;;   (table.get $conts (local.get $key))
  ;; )

  ;; (func $store_put (export "store_put") (param $key i32) (param $k (ref null $cawt))
  ;;   (table.set $conts (local.get $key) (local.get $k))
  ;; )

  (func $async_worker_yield (export "async_worker_yield") (param $value i32) (result i32)
    (suspend $yield (local.get $value))
  )

  (func $async_worker (param i32) (result i32)
    (unreachable))

  (func $alloc_async_worker (param $key i32)
    (table.set $conts (local.get $key)
       (cont.new $cawt (ref.func $async_worker))) ;; NOTE(dhil): replace $async_worker by the actual function index.
  )

  (func $resume_async_worker (param $key i32) (param $value i32) (result i32)
    (local $k (ref null $cawt))
    (block $on_return (result i32)
      (block $on_yield (result i32 (ref $cawt))
        (resume $cawt (tag $yield $on_yield) (local.get $value) (table.get $conts (local.get $key)))
        (br $on_return)
      ) ;; on_yield [ i32 (ref $cawt) ]
      (local.set $k)
      (table.set $conts (local.get $key) (local.get $k))
    ) ;; on_return
  )

  (func $free_async_worker (param $key i32))
)
