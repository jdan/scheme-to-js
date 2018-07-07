const { spawn } = require("child_process")
const prettier = require("prettier")

function compile(code, cb) {
  const scheme = spawn("scheme", ["-q"])

  let output = ""
  scheme.stdout.on("data", data => {
    output += data
  })
  scheme.on("close", () => {
    cb(prettier.format(output, { parser: "babylon" }))
  })

  scheme.stdin.end(`
    (load "compiler.scm")
    (display (scheme->js ${code}))
  `)
}

describe("+", () => {
  it("should work", done => {
    compile(`(+ 3 4)`, output => {
      expect(output).toMatchSnapshot()
      done()
    })
  })
})

describe("big block of code from main", () => {
  it("should match snapshots", done => {
    compile(
      `
      (begin
        ; These should be built in...
        (define (null? ls) (= 0 ls.length))
        (define (car ls) (Array.prototype.shift.call ls (Array.prototype.slice.call ls)))
        (define (cdr ls) (Array.prototype.slice.call ls 1))
        ; string-append is really just + but our + is a binary operator
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
        (string-join (Array "apples" "bananas" "cucumbers") ","))))
    `,
      output => {
        expect(output).toMatchSnapshot()
        expect(eval(output)).toMatchSnapshot()
        done()
      }
    )
  })
})