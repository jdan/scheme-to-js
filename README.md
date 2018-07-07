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
$ cat example.scm
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
$ scheme --script example.scm | prettier --parser babylon
(() => {
  function string$join(strs, joiner) {
    return (() => {
      function helper(strs, acc) {
        return 0 === strs.length
          ? acc
          : helper(strs.slice(1), acc + (joiner + strs[0]));
      }
      return 0 === strs.length ? "" : helper(strs.slice(1), strs[0]);
    })();
  }
  return console.log(string$join(Array("apples", "bananas", "cucumbers"), ","));
})();
$ scheme --script example.scm  | prettier --parser babylon | node
apples,bananas,cucumbers
```
