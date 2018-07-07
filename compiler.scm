(define (scheme->js* expr)
    (cond [(tagged-expr? 'if expr) (if-expr->js expr)]
          [(tagged-expr? 'lambda expr) (lambda-expr->js expr)]
          [(tagged-expr? 'define expr) (define-expr->js expr)]
          [(tagged-expr? 'begin expr) (begin-expr->js expr)]
          [(tagged-expr? 'println expr) (println-expr->js expr)]

          [(tagged-expr? '= expr) (js-infix "===" expr)]
          [(tagged-expr? '+ expr) (js-infix "+" expr)]
          [(tagged-expr? '- expr) (js-infix "-" expr)]
          [(tagged-expr? '* expr) (js-infix "*" expr)]
          [(tagged-expr? '/ expr) (js-infix "/" expr)]

          ; Some array methods
          [(tagged-expr? 'null? expr) (null?-expr->js expr)]
          [(tagged-expr? 'get expr) (get-expr->js expr)]
          [(tagged-expr? 'car expr) (car-expr->js expr)]
          [(tagged-expr? 'cdr expr) (cdr-expr->js expr)]

          [(pair? expr)
           (cond [(null? expr) "[]"]
                 [(map-expr? expr) (map-expr->js expr)]
                 [else (apply-expr->js expr)])]

          [(boolean? expr)
           (if expr "true" "false")]
          [(string? expr)
           (string-append "\"" expr "\"")]
          [(number? expr)
           (number->string expr)]
          [(symbol? expr)
           (symbol->string* expr)]

          [else
           (error "Undefined expression type:" expr)]))

; A quick macro so we don't need to quote the body
(define-syntax scheme->js
    (syntax-rules ()
        [(_ expr)
         (scheme->js* (quote expr))]))

(define (tagged-expr? tag expr)
    (and (pair? expr)
         (eq? (car expr) tag)))

(define (if-expr->js expr)
    (let [(condition (scheme->js* (cadr expr)))
          (consequent (scheme->js* (caddr expr)))
          (alternate (scheme->js* (cadddr expr)))]
        (string-append
            "(" condition ")"
            "?"
            "(" consequent ")"
            ":"
            "(" alternate ")")))

(define (lambda-expr->js expr)
    (let [(vars (map symbol->string* (cadr expr)))
          (body (scheme->js* (caddr expr)))]
        (string-append
            "((" (string-join vars ",") ") => " body ")")))

(define (define-expr->js expr)
    (let* [(name (symbol->string* (caadr expr)))
           (vars (map symbol->string* (cdadr expr)))
           (body (scheme->js* (cons 'begin (cddr expr))))]
        (string-append
            "function " name "(" (string-join vars ",") ") {"
            "return " body
            "}")))

(define (begin-expr->js expr)
    (define optimized-single-statement car)

    (let [(statements (map scheme->js* (cdr expr)))]
        (if (= 1 (length statements))
            (optimized-single-statement statements)
            (let* [(flipped* (reverse statements))
                   (last (car flipped*))
                   (all-but-last (reverse (cdr flipped*)))]
                (string-append
                    "(() => {"
                    (string-join all-but-last ";")
                    "return " last
                    "})()")))))

(define (apply-expr->js expr)
    (let [(fn (scheme->js* (car expr)))
          (vars (map scheme->js* (cdr expr)))]
        (string-append
            "((" fn ")(" (string-join vars ",") "))")))

(define (println-expr->js expr)
    (scheme->js* (cons 'console.log (cdr expr))))

(define (null?-expr->js expr)
    (let [(ls (scheme->js* (cadr expr)))]
        (string-append "(0 === (" ls ").length)")))

(define (get-expr->js expr)
    (let [(ls (scheme->js* (cadr expr)))
          (idx (scheme->js* (caddr expr)))]
        (string-append "(" ls ")[" idx "]")))

(define (car-expr->js expr)
    (get-expr->js `(get ,(cadr expr) 0)))

(define (cdr-expr->js expr)
    (let [(ls (scheme->js* (cadr expr)))]
        (string-append "(" ls ").slice(1)")))

(define (map-expr? expr)
    (and (pair? expr)
         (> (length expr) 0)
         (even? (length expr))
         (eq? #\: (string-ref (symbol->string (car expr)) 0))))

(define (map-expr->js expr)
    (define (make-term key value)
        (string-append "\"" (symbol->string* key) "\": "
                       (scheme->js* value)
                       ","))
    (define (helper terms acc)
        (if (null? terms)
            acc
            (helper (cddr terms)
                    (cons (make-term (car terms) (cadr terms))
                          acc))))
    (string-join
        (list "{"
              (string-join (helper expr '()) "")
              "}")
        ""))

(define (js-infix op expr)
    (string-append
        "("
        (scheme->js* (cadr expr))
        op
        (scheme->js* (caddr expr))
        ")"))

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

(define (string-replace str targets replacement)
    (let [(replacement* (string-ref replacement 0))
          (targets* (string->list targets))]
        (list->string
            (map (lambda (char)
                    (if (member char targets*)
                        replacement*
                        char))
                 (string->list str)))))

(define (symbol->string* sym)
    (string-replace (symbol->string sym) ":->*?" "$"))
