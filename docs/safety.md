# Level 3 — Formally verified signed-64-bit representability

This extension formally establishes the domain in which fast-doubling Fibonacci operations can be performed **without signed 64-bit arithmetic overflow**.

## Model

Dafny's mathematical `int` values have arbitrary precision. To reason about *representability* in a signed 64-bit integer, we use the subset type:

```dafny
const MAX64: int := 9223372036854775807
const MIN64: int := -9223372036854775808
type I64 = x: int | MIN64 <= x <= MAX64 witness 0
```

Every checked intermediate expression is assigned to an `I64` variable. Dafny can only accept those assignments after establishing the range predicate. This is a mathematical proof of the safety of **those particular operations** under 64-bit *checked* integer arithmetic; it is **not** a hardware overflow experiment, nor a compiler-level proof about a specific machine language.

## Precise bounds

| Quantity | Value | Fits signed 64-bit? |
|---|---:|---|
| `MAX64` | 9,223,372,036,854,775,807 | maximum |
| `F(91)` | 4,660,046,610,375,530,309 | yes |
| `F(92)` | 7,540,113,804,746,346,429 | yes |
| `F(93)` | 12,200,160,415,121,876,738 | no |

There are two different interfaces and two different maximal safe domains:

- `FastPair64(n)` returns `(F(n), F(n+1))`. It accepts **0 <= n <= 91**: at n=92 its second result would be F(93), which is not representable.
- `FastFib64(n)` returns only `F(n)`. It accepts **0 <= n <= 92**. For n=92, it computes a smaller safe pair and then evaluates *only* the even-index doubling formula, avoiding the unrepresentable F(93).

Both maximal bounds are proved, not merely based on testing. The signed 64-bit model is for **nonnegative Fibonacci indices**.

## What is proved?

The extended module `src/Int64Fibonacci.dfy` includes the original Level 1–2 source and defines:

- `FibNonnegative`, `FibMonotone`, and `FibOrder`: support nonnegativity and monotonicity for arbitrary natural indices.
- `BoundaryValues`: proves F(46), F(47), F(92), and F(93) *exactly* using the already verified doubling theorem. It also proves F(92) <= MAX64 < F(93).
- `FastPair64`: computes Fibonacci pairs with all intermediate operations represented in `I64` and proves both results correct.
- `FastFib64`: implements the maximum safe **result-only** computation through n=92, with a correctness postcondition.
- `ExactResultDomain`: proves for all n that `n<=92` is safe for F(n), and `n>=93` exceeds MAX64.
- `ExactPairDomain`: proves the exact corresponding boundary for F(n+1) at n=91/92.

The assignments to `I64` explicitly cover:

1. `2*b` (doubling the second component).
2. `2*b-a` (the difference).
3. `a*(2*b-a)` (even-index result).
4. `a*a` and `b*b` (the two odd-index products).
5. `a*a+b*b` (odd-index result).
6. `even+odd` (the next Fibonacci value in the odd branch).

The exceptional n=92 result-only branch checks its own `2*b`, `2*b-a`, and product, and deliberately does not construct an odd-index counterpart.

## How the 64-bit limit is established

We prove initial values F(0) through F(24) by recurrence (a finite symbolic calculation), then use the previously proved fast-doubling identities at k=23 and k=46:

```text
F(46) = 1,836,311,903
F(47) = 2,971,215,073
F(92) = 7,540,113,804,746,346,429
F(93) = 12,200,160,415,121,876,738
```

Given nonnegativity and Fibonacci monotonicity, the exact boundary values establish both safe-domain theorems.

## Reproduce

Requires Dafny 4.11.0.

```sh
dafny verify src/FastFibonacci.dfy
dafny verify src/Int64Fibonacci.dfy
```

The first command independently checks Levels 1 and 2. The second command checks Level 3, with the original file included as a dependency.

## Scope

The source uses `I64` as a **refinement of mathematical integers**, so the verifier proves every explicitly represented intermediate fits within the signed 64-bit range. It does not prove equivalent behavior for unchecked wrapping arithmetic, compiler optimizations, memory allocation, or a particular C#/C/Rust binary. It also does not cover `n>92`, since F(93) itself exceeds the representable maximum. The earlier logarithmic theorem counts recursion steps, not machine-level big-integer cost.
