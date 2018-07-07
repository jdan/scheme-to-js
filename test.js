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

describe("arrays", () => {
  it("should be able to car lists", done => {
    compile("(car (Array 1 2 3))", output => {
      expect(output).toMatchSnapshot()
      expect(eval(output)).toMatchSnapshot()
      done()
    })
  })

  it("should be able to cdr lists", done => {
    compile("(cdr (Array 1 2 3))", output => {
      expect(output).toMatchSnapshot()
      expect(eval(output)).toMatchSnapshot()
      done()
    })
  })

  it("should be able to recurse until an empty list", done => {
    compile(
      `
      (begin
        (define (sum ns)
          (if (null? ns)
              0
              (+ (car ns) (sum (cdr ns)))))
        (sum (Array 1 3 5 7 9))))
    `,
      output => {
        expect(output).toMatchSnapshot()
        expect(eval(output)).toMatchSnapshot()
        done()
      }
    )
  })
})
