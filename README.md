# Verified Fast Fibonacci — FMSE H24

A Dafny 4.11.0 implementation of the **fast-doubling Fibonacci algorithm**, with machine-checked functional correctness, termination, and exact logarithmic recursion-step bounds.

## Reproduce the verification

Install Dafny 4.11.0, then run:

```sh
dafny verify src/FastFibonacci.dfy
```

**Local result:** 12 verified, 0 errors (Windows, Dafny 4.11.0). The GitHub Actions workflow executes the same verification command on every push to `main` and every pull request.

## Level 1: functional correctness

- `Fib(n)`: independent recursive specification, F(0)=0, F(1)=1, F(n)=F(n-1)+F(n-2).
- `Doubling(k)`: proves the two fast-doubling identities for all natural numbers.
- `FastPair(n)`: computes F(n) and F(n+1) through one recursive call on n/2.
- `FastFib(n)`: retains its original public interface and guarantees `result == Fib(n)`.

The required doubling identities are:

```text
a = F(k), b = F(k+1)
F(2k)   = a * (2*b - a)
F(2k+1) = a*a + b*b
```

## Level 2: verified logarithmic recursion depth

The **same `FastPair` implementation** returns a third value, `steps`, counting non-base-case recursive calls (including base case, total invocations = steps + 1). The independently specified cost function is:

```text
S(0) = 0
S(n) = 1 + S(floor(n / 2)), for n > 0
```

Dafny proves `steps == S(n)` and, for all n>0:

```text
2^(steps-1) <= n < 2^steps
```

Therefore `steps = floor(log2(n)) + 1` for n>0, and `steps = 0` for n=0. This establishes logarithmic recursion depth and number of pair calculations (under the unit-cost arithmetic model).

The original `FastFib(n)` API is unchanged. For the certified count, call:

```dafny
method FastFibWithSteps(n: nat) returns (result: int, steps: nat)
```

## Project files

- [`src/FastFibonacci.dfy`](src/FastFibonacci.dfy) — algorithm, two doubling identities, count model, inductive bound and contracts
- [`docs/report.md`](docs/report.md) — course report, sections A-E
- [`docs/complexity.md`](docs/complexity.md) — detailed logarithmic proof and examples
- [`.github/workflows/verify.yml`](.github/workflows/verify.yml) — reproducible CI

## Limits

Arithmetic is on **unbounded mathematical integers**. The proof establishes functional correctness, termination, and the number of recursive steps, but **does not** establish O(log n) bit-operation runtime, bounded-integer overflow freedom, or a wall-time bound. These require additional models, and overflow safety is the proposed Level 3.
