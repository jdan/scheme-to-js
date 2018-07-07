(load "compiler.scm")

(display
    (scheme->js
        (begin
            (define (string-join strs joiner)
                (define (helper strs acc)
                    (if (null? strs)
                        acc
                        (helper (cdr strs)
                                (+ acc
                                   (+ joiner (car strs))))))
                (if (null? strs)
                    ""
                    (helper (cdr strs) (car strs))))
            (println (string-join (Array "apples" "bananas" "cucumbers") ",")))))
