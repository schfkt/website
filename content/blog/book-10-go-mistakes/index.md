---
title: "Book review: 100 Go Mistakes and How to Avoid Them"
date: 2023-02-19
---

I recently read "100 Go Mistakes and How to Avoid Them" by Teiva Harsanyi, which I first heard about in the Golang
Weekly Newsletter. At first, I was skeptical that it might be just another cookbook-style book, but it turned out to be
much more.

<!--more-->

[![Book Cover](https://images.manning.com/264/352/resize/book/9/5990f3c-19fb-4945-b024-7280e616773f/Harsanyi-HI.png)](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them)

All of the mistakes are organized into different categories. Some of them are:
- Types: numbers, strings, maps, slices.
- Concurrency: scheduler's internals, context propagation, channels for synchronization and communication.
- Error handling.
- Testing and benchmarking.
- Performance optimizations.

Each of the chapters describes how a particular go feature works under the hood and how some specific edge cases can
lead to mistakes in your code. For example, have you known that maps can only grow, but not shrink? Let's say you use a
map for in-memory cache, and you keep adding elements, 10000 for example, when you delete all the elements, the internal
map structure will have the same amount of buckets as if there still were 10000 elements. In that case, you just need to
re-create the map periodically to avoid unbounded memory growth.

The last chapter, Optimisations, is the most interesting in my opinion. It goes into detail on how CPU caches work, and
what you need to keep in mind about it to write code that properly leverages them. Moreover, Teiva mentions a concept of
mechanical sympathy here, which resonates with my own experience: to better work with a language (especially go), you
need to understand how the machine works under the hood (CPU, Memory). And there's more in that chapter: stack vs heap
memory difference and how to make sure you make fewer heap allocations, built-in profiler, and tracer usage, and
compiler optimisations.

Overall, I found "100 Go Mistakes and How to Avoid Them" to be one of the most interesting software books I've read in
the past couple of years. While it's probably best suited for more experienced Go developers, I think anyone working
with Go could benefit from reading it. It provides a deep understanding of how Go works under the hood and offers
practical advice for avoiding common mistakes. I highly recommend it.
