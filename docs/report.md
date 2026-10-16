# Formal Methods in Software Engineering — Homework H24

**Title:** Verified Fast Fibonacci by Fast Doubling  
**Implementation language:** Dafny 4.11.0  
**Verification target:** `src/FastFibonacci.dfy`  
**Status:** Locally verified: 6 verified, 0 errors

## A. Introduction

The Fibonacci recurrence is defined by F(0)=0, F(1)=1, and F(n)=F(n-1)+F(n-2) for n>=2. The naive recursive implementation repeats computations. The *fast-doubling* method obtains F(2k) and F(2k+1) directly from F(k) and F(k+1), reducing the argument by half at each step.

**Proven result:** The Dafny procedure `FastFib(n)` terminates for every natural-number input and returns the value of the independently specified Fibonacci function `Fib(n)`.

## B. Specifications

- **S1 — Mathematical reference:** `Fib(n: nat): int` implements F(0)=0, F(1)=1, and F(n)=F(n-1)+F(n-2).
- **S2 — Doubling (even index):** for all k>=0, F(2k)=F(k)*(2*F(k+1)-F(k)).
- **S3 — Doubling (odd index):** for all k>=0, F(2k+1)=F(k)^2+F(k+1)^2.
- **S4 — Pair correctness:** `FastPair(n)` returns `(x,y)` with `x==Fib(n)` and `y==Fib(n+1)`.
- **S5 — Public correctness:** `FastFib(n)` returns `result==Fib(n)`.
- **S6 — Termination:** `Fib` and `Doubling` decrease their natural-number argument; `FastPair` recursively calls itself on `n/2`, strictly smaller than n whenever n>0.

**Domain:** n is a natural number (non-negative integer). Computation uses unbounded mathematical integers; no machine-width overflow claim is made.

## C. Encoding and proof

The Dafny function `Fib` is the reference specification. It is deliberately **not used by the executable algorithm**, avoiding circular correctness reasoning.

The auxiliary lemma `Doubling(k)` establishes S2 and S3 simultaneously by induction on k.

At k=0, F(0)=0 and F(1)=1 establish both identities. In the induction step, let a=F(k-1), b=F(k), and c=F(k+1)=a+b. The induction hypothesis gives:

```text
F(2k-2) = a(2b-a)
F(2k-1) = a^2+b^2
```

Consequently,

```text
F(2k)   = F(2k-1)+F(2k-2)
        = a^2+b^2+a(2b-a)
        = b(2(a+b)-b) = b(2c-b).

F(2k+1) = F(2k)+F(2k-1)
        = b(2c-b)+(a^2+b^2)
        = b^2+c^2.
```

The implementation `FastPair(n)` recursively obtains a=F(k) and b=F(k+1) for k=floor(n/2). The lemma guarantees that the two calculated expressions equal F(2k) and F(2k+1). For even n, these are exactly F(n) and F(n+1). For odd n, F(2k+2)=F(2k)+F(2k+1) gives the second output. The method contracts guarantee S4; `FastFib` extracts the first component to obtain S5.

Termination is proved with Dafny's `decreases` clauses (S6). The key induction and algebra steps appear explicitly as Dafny lemma calls, assertions, and `calc` blocks.

## D. Results

The file was checked on a Windows workstation running **Dafny 4.11.0**:

```text
dafny verify src/FastFibonacci.dfy
Dafny program verifier finished with 6 verified, 0 errors
```

The verifier reported **zero errors**. There are no `assume`, `{:axiom}`, or `sorry` placeholders in the source. The resulting status for S1–S6 is complete, under Dafny's usual formal semantics and arithmetic model.

**Reproducibility:** GitHub Actions runs the same verification command on every pull request and push to `main`. Platform-dependent verification timings are not used as correctness evidence; the runtime measured during the final verification run can be recorded separately.

## E. Discussion

The strongest modelling decision was to compute pairs `(F(n),F(n+1))` instead of F(n) alone, because the doubling formula requires two consecutive terms. Proving the two doubling identities together yields a compact inductive argument. The key challenge is algebraic reasoning involving products of Fibonacci numbers; Dafny's `calc` blocks expose intermediate equalities.

An important distinction is that the specification uses the ordinary recurrence, whereas the executable algorithm only invokes fast doubling. The verified postconditions therefore compare two different formulations of Fibonacci rather than merely restating the algorithm.

**Limitations:** The proof models unbounded integers rather than a fixed-width runtime type. It verifies functional correctness and termination, not an instrumented complexity bound or compiler-level resource usage. Those can be independent extensions without weakening the completed H24 proof.
