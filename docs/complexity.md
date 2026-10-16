# Level 2 — Machine-checked recursion depth

This extension strengthens the FMSE H24 fast-doubling proof from *functional correctness* to *functional correctness plus certified recursive-step complexity*.

## What is counted?

The implementation of `FastPair(n)` now returns `(x, y, steps)`. For `n = 0`, `steps = 0`. For `n > 0`, it makes exactly one recursive call on `n / 2`, so `steps = 1 + childSteps`.

Consequently, the count measures **non-base-case recursive calls**, not elapsed wall time, CPU instructions, or the total bit-complexity of large-integer arithmetic. Total method invocations including the base case are `steps + 1`.

A separate reference function `RecursiveSteps(n)` specifies the recurrence:

```text
S(0) = 0
S(n) = 1 + S(floor(n / 2))    for n > 0
```

The postcondition `ensures steps == RecursiveSteps(n)` proves that the count returned by the *actual fast-doubling method* matches that recurrence for every input.

## Logarithmic theorem

Define `Pow2(e)` recursively with `Pow2(0) = 1` and `Pow2(e+1) = 2*Pow2(e)`.

`DepthBounds(n)` proves for every positive `n`:

```text
S(n) > 0
2^(S(n)-1) <= n < 2^S(n)
```

The inequalities uniquely characterize the binary bit length:

```text
S(n) = floor(log2(n)) + 1   for n > 0
S(0) = 0
```

In other words, there are exactly `floor(log2(n))+1` non-base-case steps, yielding **O(log n)** recursion depth and number of pair calculations under a unit-cost arithmetic model.

The machine-checked statement is the integer-power inequality; the logarithmic form is its standard mathematical consequence, not an appeal to floating-point logarithms.

## Proof sketch

Let `k = floor(n/2)`.

- If `n=0`, the count is zero.
- If `n=1`, then `k=0` and `S(n)=1`, so `1 <= n < 2`.
- For `k>0`, the induction hypothesis gives `2^(S(k)-1) <= k < 2^S(k)`. Because `2k <= n < 2(k+1)` and `S(n) = S(k)+1`, doubling these inequalities gives `2^S(k) <= n < 2^(S(k)+1)`.

This proves both bounds by strong induction over the strictly decreasing argument `k<n`.

## Examples

| n | Verified step-model S(n) | Invocations including base case |
|---:|---:|---:|
| 0 | 0 | 1 |
| 1 | 1 | 2 |
| 2 | 2 | 3 |
| 7 | 3 | 4 |
| 8 | 4 | 5 |
| 10 | 4 | 5 |
| 100 | 7 | 8 |
| 1000 | 10 | 11 |

The values follow directly from the defined recurrence, not from performance measurements.

## Reproduce

```sh
dafny verify src/FastFibonacci.dfy
```

Key proof artifacts in the file: `RecursiveSteps`, `Pow2`, `DepthBounds`, `FastPair` (instrumented), and `FastFibWithSteps`.

## Scope and limitations

This is an asymptotic bound on **the number of recursive steps / pair calculations**. Arithmetic on Fibonacci numbers becomes more expensive as the result grows. Thus the proof does **not** establish O(log n) bit-operation runtime, fixed-width safety, memory bounds, or machine-code resource usage. Level 3 could model bounded-integer overflow safety.
