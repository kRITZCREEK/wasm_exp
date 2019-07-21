(module
 (memory 1)
 (global $watermark (mut i32) (i32.const 0))

 (func $allocate (param $bytes i32) (result i32)
       (local $res i32)
       (set_local $res (global.get $watermark))
       (global.set $watermark (i32.add (get_local $res) (get_local $bytes)))
       (get_local $res))

 (table 1 anyfunc)
 (elem (i32.const 0) $add)
 (func $add (param $args i32) (result i32)
       (local $x i32)
       (local $y i32)
       (set_local $x (i32.load16_u (get_local $args)))
       (set_local $y (i32.load16_u (i32.add (get_local $args) (i32.const 2))))
       (i32.add (get_local $x) (get_local $y)))

 (func $test (result i32)
       (call $make_closure
             ;; arity
             (i32.const 2)
             ;; code pointer for body
             (i32.const 0))
       (call $apply (i32.const 5))
       (call $apply (i32.const 16))

       (call $make_closure
             ;; arity
             (i32.const 2)
             ;; code pointer for body
             (i32.const 0))
       (call $apply (i32.const 10))
       (call $apply (i32.const 10))

       i32.add
       ;; returns (5 + 16) + (10 + 10) = 41
       )
 (export "test" (func $test))

 ;; Creates a new closure with the following layout:
 ;; 2bytes => Arity
 ;; 2bytes => Applied argument counter
 ;; n*2bytes => Space for applied arguments
 ;; 2bytes => index of the function to be called from the function table
 (func $make_closure (param $arity i32) (param $code_pointer i32) (result i32)
       (local $closure_start i32)
       ;; The size of a closure is 6bytes + 2bytes per argument
       (set_local $closure_start
                  (call $allocate
                        (i32.add (i32.const 6)
                                 (i32.mul (i32.const 2) (get_local $arity)))))
       ;; Initializes arity
       (i32.store16
        (get_local $closure_start)
        (get_local $arity))
       ;; Initializes applied arg counter to 0
       (i32.store16
        (i32.add (get_local $closure_start) (i32.const 2))
        (i32.const 0))
       ;; writes the code pointer
       (i32.store16
        (i32.add (i32.add (get_local $closure_start) (i32.const 4)) ;; skips over arity and applied counter
                 (i32.mul (get_local $arity) (i32.const 2))) ;; skips over arguments
        (get_local $code_pointer))
       (get_local $closure_start))

 (type $i32_to_i32 (func (param i32) (result i32)))
 (func $apply (param $closure i32) (param $arg i32) (result i32)
       (local $arity i32)
       (local $applied i32)
       (local $arg_start i32)
       (local $next_arg i32)
       (local $code_pointer_offset i32)

       (set_local $arity (i32.load16_u (get_local $closure)))
       (set_local $applied (i32.load16_u (i32.add (get_local $closure) (i32.const 2))))
       (set_local $arg_start (i32.add (get_local $closure) (i32.const 4)))
       (set_local $next_arg (i32.add (get_local $arg_start)
                                     (i32.mul (get_local $applied)
                                              (i32.const 2))))
       (set_local $code_pointer_offset
                  (i32.add (get_local $arg_start)
                           (i32.mul (get_local $arity)
                                    (i32.const 2))))

       ;; write the supplied argument into its spot
       ;; TODO: We should be copying the closure here
       (i32.store16 (get_local $next_arg) (get_local $arg))
       (if (result i32)
           (i32.eq (get_local $arity) (i32.add (get_local $applied) (i32.const 1)))
         (then
          ;; if all arguments have been supplied we're ready to execute the body
          (call_indirect (type $i32_to_i32) (get_local $arg_start) (i32.load16_u (get_local $code_pointer_offset))))
         (else
          ;; If we're still missing arguments we bump the applied counter and return the new closure
          (i32.store16 (i32.add (get_local $closure) (i32.const 2)) (i32.add (get_local $applied) (i32.const 1)))
          (get_local $closure))))
)
