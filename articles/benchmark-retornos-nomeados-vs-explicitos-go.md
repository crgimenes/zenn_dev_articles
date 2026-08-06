---
title: "Goの名前付き戻り値と明示的な戻り値をベンチマークで比較する"
emoji: "⚡"
type: "tech"
topics: ["go", "benchmark", "testing", "development"]
published: true
---

A question came up in our Go study group: are named returns faster than explicit returns? That was the hypothesis.

Fortunately, Go has good tools to test this.

Let's write some code with two sum functions: one with named returns and one with explicit returns.

```go
package main

import (
    "testing"
)

// Função com retornos nomeados
func somaNomeados(a, b int) (resultado int, err error) {
    resultado = a + b
    return
}

// Função com retornos explícitos
func somaExplicitos(a, b int) (int, error) {
    return a + b, nil
}
```

Next, we create the benchmark functions. The names of these functions matter. Go's testing tool looks for functions that start with "Benchmark".

```go
func BenchmarkSomaNomeados(b *testing.B) {
    for i := 0; i < b.N; i++ {
        somaNomeados(1, 2)
    }
}

func BenchmarkSomaExplicitos(b *testing.B) {
    for i := 0; i < b.N; i++ {
        somaExplicitos(1, 2)
    }
}
```
[source code](https://crg.eti.br/en/post/benchmark-retornos-nomeados-vs-explicitos-go/benchmark_retornos_test.go)

Name the file `benchmark_retornos_test.go`. The file name matters. It must end with `_test.go` so Go can find the tests.

To run the benchmark, execute:

```bash
go test -bench=.
```

In my case, the result was:

```
goos: darwin
goarch: arm64
pkg: benchmarkRetorno
cpu: Apple M2
BenchmarkSomaNomeados-8         1000000000             0.2926 ns/op
BenchmarkSomaExplicitos-8       1000000000             0.2879 ns/op
PASS
ok      benchmarkRetorno    1.167s
```

Surprisingly, explicit returns were slightly faster across several runs. This may be an anomaly caused by Go's instrumentation. Sub-nanosecond differences can be ignored.

When compiling with `go build`, the binary code of both functions is identical.

In conclusion, named and explicit returns have the same performance. Choose between them based on code readability.

Video with the explanation (in Portuguese):

@[youtube](_88e53_K4uE)
