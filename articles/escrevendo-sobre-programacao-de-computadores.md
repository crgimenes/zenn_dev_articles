---
title: "プログラミングについて書くときに意識していること"
emoji: "✍️"
type: "idea"
topics: ["writing", "programming", "opinion"]
published: true
---

Writing about programming and computing is challenging. These topics are complex, and it is hard to build a narrative that is both understandable and interesting.

On top of that, Portuguese is a demanding language. I tend to write the way I speak, which results in texts that are hard to read.

To make things easier, I created a few rules that serve as a guide. They are not strict, just guidelines in no particular order.

- **Get straight to the point.** Avoid unnecessary embellishments and go directly to the subject.
- **Avoid unnecessary anglicisms.** Use Portuguese terms whenever possible. We have adopted some anglicisms such as "mouse" and "kernel". [Here are some useful substitutions](https://www.ime.usp.br/~kon/ResearchStudents/traducao.html).
- **Avoid technical jargon.** If you must use it, explain it or include a link to a definition.
- **Include examples.** Demonstrating a concept with a code snippet helps clarify ideas. For example, when explaining the `sort.Slice` function in Go (Go 1.23 or later):

    ```go
    package main

    import (
        "fmt"
        "sort"
    )

    func main() {
        // Exemplo simples de ordenação de inteiros
        numbers := []int{42, 7, 19, 3, 15}
        sort.Slice(numbers, func(i, j int) bool {
            return numbers[i] < numbers[j]
        })
        fmt.Println(numbers) // Saída esperada: [3 7 15 19 42]
    }
    ```

- **Include references and links.** Cite reliable sources, such as the [official Go documentation](https://go.dev/doc/) or the ["Effective Go"](https://go.dev/doc/effective_go) guide, to support your arguments and guide the reader.
- **Illustrate with images.** Use diagrams, interface screenshots, or logic flows. A simple software architecture diagram can make the text more accessible.
- **Use lists, bold text, and other elements to highlight important information.** This helps break up the text and makes it easier to read.
- **Keep paragraphs short.** Paragraphs of at most 3 lines keep the reader from getting tired.
- **Review and edit.** Read the text out loud; if it sounds strange, the text is bad.

I usually write for myself. The best way to learn something is to try to explain it to someone, so writing about computing and trying to explain what I am doing serves as notes for the future, writing practice, and study.
