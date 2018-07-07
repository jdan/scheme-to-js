## scheme-to-js
a scheme->js compiler written in scheme

### Hi 👋

This is a Scheme compiler written in Scheme that produces JavaScript.

I've done this before (in JavaScript) - https://github.com/jdan/lispjs. You'll find that writing the
compiler in Scheme itself means I can effectively skip parsing.

### Running

I've written this repository with [Chez Scheme](https://github.com/cisco/ChezScheme) in mind. It's pretty
tiny and easy to install. I typically [build it without X11](https://github.com/cisco/ChezScheme/issues/84#issuecomment-401233680).

### Example

```
$ cat main.scm
(load "compiler.scm")

(display
    (scheme->js
        (begin
            ; These should be built in...
            (define (null? ls) (= 0 ls.length))
            (define (car ls) (Array.prototype.shift.call ls (Array.prototype.slice.call ls)))
            (define (cdr ls) (Array.prototype.slice.call ls 1))
            ; string-append is really just `+`, but our `+` is a binary operator
            (define (string-append a b c)
                (+ a (+ b c)))

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
$ scheme --script main.scm
(() => {function null$(ls) {return (0===ls.length)};function car(ls) {return ((Array.prototype.shift.call)(ls,((Array.prototype.slice.call)(ls))))};function cdr(ls) {return ((Array.prototype.slice.call)(ls,1))};function string$append(a,b,c) {return (a+(b+c))};function string$join(strs,joiner) {return (() => {function helper(strs,acc) {return (((null$)(strs)))?(acc):(((helper)(((cdr)(strs)),((string$append)(acc,joiner,((car)(strs)))))))}return (((null$)(strs)))?(""):(((helper)(((cdr)(strs)),((car)(strs)))))})()}return ((console.log)(((string$join)(((Array)("apples","bananas","cucumbers")),","))))})()
$ scheme --script main.scm  | prettier --parser babylon
(() => {
  function null$(ls) {
    return 0 === ls.length;
  }
  function car(ls) {
    return Array.prototype.shift.call(ls, Array.prototype.slice.call(ls));
  }
  function cdr(ls) {
    return Array.prototype.slice.call(ls, 1);
  }
  function string$append(a, b, c) {
    return a + (b + c);
  }
  function string$join(strs, joiner) {
    return (() => {
      function helper(strs, acc) {
        return null$(strs)
          ? acc
          : helper(cdr(strs), string$append(acc, joiner, car(strs)));
      }
      return null$(strs) ? "" : helper(cdr(strs), car(strs));
    })();
  }
  return console.log(string$join(Array("apples", "bananas", "cucumbers"), ","));
})();
$ scheme --script main.scm  | prettier --parser babylon | node
apples,bananas,cucumbers
```

