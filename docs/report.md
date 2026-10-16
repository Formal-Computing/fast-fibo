# Formal Methods in Software Engineering — Homework H24

**Title:** Verified Fast Fibonacci: Functional Correctness and Logarithmic Recursion Depth

**Implementation / proof environment:** Dafny 4.11.0

**Source:** `src/FastFibonacci.dfy`

**Status:** Verified locally: 12 verified, 0 errors. GitHub CI verification runs on pushed commits.

## A. Introduction

Fibonacci numbers satisfy F(0)=0, F(1)=1, and F(n)=F(n-1)+F(n-2) for n>=2. Computing the recurrence naively repeats expensive subproblems. The *fast-doubling* algorithm reduces the index to floor(n/2) and constructs the result using two identities. This homework verifies the result for every natural number, proves termination, and extends the implementation with a certified bound on recursive steps.

## B. Specifications

Specifications use natural-number inputs and arbitrary-precision mathematical integer values.

- **S1 — Reference recurrence:** `Fib(n)` equals F(0)=0, F(1)=1, F(n)=F(n-1)+F(n-2).
- **S2 — Even doubling:** F(2k)=F(k)*(2*F(k+1)-F(k)) for k>=0.
- **S3 — Odd doubling:** F(2k+1)=F(k)^2+F(k+1)^2 for k>=0.
- **S4 — Pair correctness:** `FastPair(n)` returns `x==Fib(n)` and `y==Fib(n+1)`.
- **S5 — Public correctness:** `FastFib(n)` ensures `result==Fib(n)`.
- **S6 — Termination:** recursive calls on floor(n/2) strictly decrease n when n>0; the mathematical definitions and inductive lemma also decrease.
- **S7 — Recursive-step count:** `FastPair(n)` returns `steps == RecursiveSteps(n)`, where S(0)=0 and S(n)=1+S(floor(n/2)) for n>0.
- **S8 — Positive-count invariant:** n>0 implies steps>0; n=0 implies steps=0.
- **S9 — Lower logarithmic bound:** n>0 implies `Pow2(steps-1)<=n`.
- **S10 — Upper logarithmic bound:** n>0 implies `n<Pow2(steps)`.

S9-S10 characterize the exact number of non-base-case recursive steps and imply logarithmic depth. The cost-aware wrapper `FastFibWithSteps` exposes S5 and S7-S10 together.

## C. Encoding

### Independent mathematical specification

`Fib(n)` expresses the ordinary recurrence. The executable algorithm never calls `Fib`; only its verification contracts and proof assertions refer to that function.

### Fast-doubling identity proof

`Doubling(k)` proves S2 and S3 together by induction on k. For the inductive case put a=F(k-1), b=F(k), c=F(k+1)=a+b. The induction hypothesis gives:

```text
F(2k-2) = a*(2b-a)
F(2k-1) = a*a+b*b
```

Consequently:

```text
F(2k)   = F(2k-1)+F(2k-2)
        = a*a+b*b + a*(2b-a)
        = b*(2(a+b)-b) = b*(2c-b).

F(2k+1) = F(2k)+F(2k-1)
        = b*(2c-b)+a*a+b*b
        = b*b+c*c.
```

These steps are reflected directly in Dafny's `calc` assertions. `FastPair(n)` makes one recursive call for k=floor(n/2); S2-S3 reconstruct the pair for even and odd n.

### Verified recursion-step bound

The instrumented `FastPair` returns `steps=0` at n=0, or `childSteps+1` otherwise, and proves S7. The independent functions `RecursiveSteps` and `Pow2` express the recurrence and powers of two respectively. The lemma `DepthBounds(n)` proves S8-S10 for all n.

For n>0, let k=floor(n/2). If k=0 then n=1, steps=1, and 1<=n<2. If k>0, write d=S(k). The induction hypothesis states `2^(d-1)<=k<2^d`. Since `2k<=n<2(k+1)` and `S(n)=d+1`, we obtain `2^d<=n<2^(d+1)`. This proves the two-sided bound.

For n>0 it follows that `steps=floor(log2(n))+1`, i.e. the integer's binary bit length. The exact machine-checked claim uses integer powers, so no floating-point logarithm is required.

## D. Results

Verified on a Windows workstation using Dafny 4.11.0 (final local verification wall time: 15.86 seconds, including startup):

```text
dafny verify src/FastFibonacci.dfy
Dafny program verifier finished with 12 verified, 0 errors
```

**S1-S10: successfully verified**, with no hidden `assume`, `{:axiom}`, or `sorry` placeholders. The added verification goals cover the independent recursive count function, powers-of-two model, bound induction, and complexity-aware wrapper.

The GitHub Actions workflow runs the same command on pushes and pull requests. The code is complete for Levels 1 and 2; Level 3 is deliberately not included.

## E. Discussion

The essential design choice is to compute two consecutive Fibonacci values in a single pair, which makes the identities directly applicable. The complexity proof deliberately instruments this *same executable method*, so the returned count is demonstrably tied to its recursive execution rather than to an unrelated recurrence.

The cost theorem establishes **O(log n) recursive steps** and pair calculations assuming unit-cost arithmetic, not O(log n) bit-operation runtime: the values grow rapidly and arbitrary-precision integer multiplication has nonconstant cost. Likewise, fixed-width overflow is not addressed. This scope distinction is essential to interpreting the result correctly.

The extra verification effort consists of an independent count specification, a power-of-two function, an inductive bound lemma, additional postconditions, and a detailed explanation in `docs/complexity.md`. The next possible extension is certified overflow safety with 64-bit arithmetic.
