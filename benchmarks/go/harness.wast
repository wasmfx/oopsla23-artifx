(input "coroutines.wat")
(register "entry")

(module
  (func (export "_start") (import "entry" "_start")))

(invoke "_start")
