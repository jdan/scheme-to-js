#! /usr/bin/env scheme --script
(load "compiler.scm")

(display
    (scheme->js
        (begin
            ; These should be built in...
            (define (null? ls) (= 0 ls.length))
            (define (cdr ls) (Array.prototype.slice.call ls 1))

            (define (string-join strs joiner)
                (define (helper strs acc)
                    (if (null? strs)
                        acc
                        (helper (cdr strs)
                                (string-append
                                    acc
                                    joiner
                                    (car strs)))))
                (if (null? strs)
                    ""
                    (helper (cdr strs) (car strs))))
            (println (string-join (Array "apples" "bananas" "cucumbers") ",")))))
