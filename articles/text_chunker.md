---
title: "Goのiterパッケージで作るRAG向けオーバーラップ付きテキストチャンカー"
emoji: "✂️"
type: "tech"
topics: ["go", "rag", "iterator", "llm"]
published: true
---

In a RAG (*Retrieval-Augmented Generation*) pipeline the first step is almost always the same: take a large text and break it into pieces before vectorizing. The pieces can't be too big, because the model has a context limit, nor too small, because then the embedding loses semantics. And neighbors need to overlap, otherwise an answer that lands right on the boundary gets squeezed between two chunks and the retriever misses.

The *chunker* needs to:

- Break the text into windows of up to N runes.
- Support configurable overlap.
- Never cut a word in half.
- Be consumable with a `for-range`, without loading the whole list into memory.

The last item is trivial since Go 1.23 with the `iter` package. The function returns an `iter.Seq[string]` and the consumer iterates over it like anything else:

```go
for chunk := range Chunker(text, 60, 15) {
    // embed, index, send to the LLM
}
```

The window moves in runes, not bytes.

Text with multibyte characters, an emoji in the middle of a paragraph: counting bytes gives the wrong size and risks splitting a character in half.

I pay for the `[]rune(text)` conversion once and work with rune indices from then on.

The step between windows is `size - overlap`. If that comes out `<= 0` the configuration is absurd (overlap greater than or equal to the size) and the iterator ends without emitting anything:

```go
func Chunker(text string, size, overlap int) iter.Seq[string] {
    return func(yield func(string) bool) {
        runes := []rune(text)
        n := len(runes)
        step := size - overlap
        if n == 0 || size <= 0 || step <= 0 {
            return
        }
        // ...
    }
}
```

To avoid cutting a word, just back the end of the window up to the last word boundary (any whitespace). If the word is so long that it fills the entire chunk by itself, then cut at the limit anyway.

It's the only way to make progress:

```go
cut := end
for cut > i && !unicode.IsSpace(runes[cut]) {
    cut--
}
if cut == i {
    cut = end
}
```

Emit the chunk and respect the `iter.Seq` protocol: if `yield` returns `false`, the consumer left the loop (`break`, `return`) and we leave with them:

```go
if !yield(strings.TrimSpace(string(runes[i:cut]))) {
    return
}
```

The next window starts at `cut - overlap`. That index can land in the middle of a word, so I advance past the partial word and then skip the whitespace to start clean:

```go
i = max(cut-overlap, 0)
if i > 0 && !unicode.IsSpace(runes[i-1]) {
    for i < n && !unicode.IsSpace(runes[i]) {
        i++
    }
}
for i < n && unicode.IsSpace(runes[i]) {
    i++
}
```

When the end of the window goes past the end of the text, deliver the rest and finish:

```go
if end >= n {
    if last := strings.TrimSpace(string(runes[i:n])); last != "" {
        yield(last)
    }
    return
}
```

Running with `size=60`, `overlap=15`:

```
document: 174 runes | size=60 overlap=15
------------------------------------------------------------
[01] "The Go programming language favors standard libraries and"
[02] "libraries and simple tools. The use of iterators, introduced"
[03] "introduced in recent versions, simplifies the construction"
[04] "construction of complex pipelines."
```

Each chunk starts by repeating the end of the previous one.

That repetition is what gives the retriever a chance to match a query whose answer landed right on the boundary between two chunks.

The cost is more vectors in the index and the chance of the same passage showing up twice in the top-k. For production RAG it's worth it. LangChain and LlamaIndex default to something in that range: `size` of 500 to 1000 tokens, overlap of 10% to 20%.

This chunker is dumb on purpose. It doesn't know sentences, doesn't know paragraphs, doesn't know semantics. For a serious pipeline you'll probably want to cut at sentence boundaries, or go with a semantic chunker that looks at sentence embeddings and splits where similarity drops.

[Full source code](https://crg.eti.br/post/text_chunker/main.go)

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
