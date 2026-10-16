# Fast Fibonacci — FMSE Homework H24

A small formally verified implementation of **fast doubling** in Dafny 4.11.0.

## Goal

Implement Fibonacci with logarithmic recursion depth, and **prove**, for every natural number `n`, that the computed result equals the ordinary recursive Fibonacci specification.

The executable implementation `FastPair(n)` computes `(F(n), F(n+1))` from `FastPair(n/2)`. The specification `Fib` is independent of the algorithm.

## Verification

Install [Dafny](https://dafny.org/latest/Installation) (tested with version **4.11.0**) and run:

```bash
dafny verify src/FastFibonacci.dfy
```

**Local verification result (Windows, Dafny 4.11.0): 6 verified, 0 errors.** GitHub Actions reruns the verifier after each pull request or push to `main`.

## Structure

- `src/FastFibonacci.dfy` — definition of `Fib`, inductive doubling lemma, verified `FastPair` method and `FastFib` entry point
- `docs/report.md` — FMSE report, sections A–E
- `.github/workflows/verify.yml` — reproducible Dafny CI

## Specification

`Fib(0)=0`, `Fib(1)=1`, and `Fib(n)=Fib(n-1)+Fib(n-2)` for `n>=2`.

For `a=F(k)` and `b=F(k+1)`:

```text
F(2k)   = a * (2*b - a)
F(2k+1) = a*a + b*b
```

The returned pair from `FastPair(n)` satisfies:

```dafny
ensures x == Fib(n)
ensures y == Fib(n + 1)
```

and the public `FastFib(n)` satisfies `ensures result == Fib(n)`.

## Scope

This repository covers **Level 1: functional correctness and termination**. Mathematical integers are unbounded; machine overflow and formal time-complexity bounds are **not** proved here. The depth is logarithmic by inspection of the `n/2` recurrence, but a machine-checked complexity theorem is reserved for Level 2.

The report documents the mathematical argument, proof strategy, verification results, and limitations.
