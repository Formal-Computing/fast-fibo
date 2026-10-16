// FMSE H24: fast doubling, functional correctness, and a logarithmic
// recursive-depth bound. Mathematical integers are unbounded.
module FastFibonacci {
  // Independent mathematical specification.
  function Fib(n: nat): int
    decreases n
  {
    if n < 2 then n else Fib(n - 1) + Fib(n - 2)
  }

  // The fast-doubling identities are proved by induction on k.
  lemma Doubling(k: nat)
    ensures Fib(2 * k) == Fib(k) * (2 * Fib(k + 1) - Fib(k))
    ensures Fib(2 * k + 1) == Fib(k) * Fib(k) + Fib(k + 1) * Fib(k + 1)
    decreases k
  {
    if k == 0 {
      assert Fib(0) == 0;
      assert Fib(1) == 1;
    } else {
      Doubling(k - 1);

      var a := Fib(k - 1);
      var b := Fib(k);
      var c := Fib(k + 1);
      assert c == a + b;

      assert 2 * (k - 1) == 2 * k - 2;
      assert 2 * (k - 1) + 1 == 2 * k - 1;
      assert Fib(2 * k - 2) == a * (2 * b - a);
      assert Fib(2 * k - 1) == a * a + b * b;

      assert Fib(2 * k) == Fib(2 * k - 1) + Fib(2 * k - 2);
      calc {
        Fib(2 * k);
        ==
        (a * a + b * b) + a * (2 * b - a);
        ==
        b * (2 * (a + b) - b);
        ==
        b * (2 * c - b);
      }

      assert Fib(2 * k + 1) == Fib(2 * k) + Fib(2 * k - 1);
      calc {
        Fib(2 * k + 1);
        ==
        b * (2 * c - b) + (a * a + b * b);
        ==
        b * b + c * c;
      }
    }
  }

  // RecursiveSteps measures the number of non-base-case calls made by
  // fast doubling. Total invocations are RecursiveSteps(n) + 1.
  function RecursiveSteps(n: nat): nat
    decreases n
  {
    if n == 0 then 0 else 1 + RecursiveSteps(n / 2)
  }

  function Pow2(e: nat): int
    decreases e
  {
    if e == 0 then 1 else 2 * Pow2(e - 1)
  }

  // Precise logarithmic bound, avoiding floating-point logarithms:
  // for n > 0, 2^(steps-1) <= n < 2^steps.
  // Hence steps is exactly the binary bit length of n.
  lemma DepthBounds(n: nat)
    ensures n == 0 ==> RecursiveSteps(n) == 0
    ensures n > 0 ==> RecursiveSteps(n) > 0
    ensures n > 0 ==> Pow2(RecursiveSteps(n) - 1) <= n
    ensures n > 0 ==> n < Pow2(RecursiveSteps(n))
    decreases n
  {
    if n == 0 {
      assert RecursiveSteps(n) == 0;
    } else {
      var k := n / 2;
      assert 2 * k <= n < 2 * k + 2;
      assert k < n;

      if k == 0 {
        assert n == 1;
        assert RecursiveSteps(n) == 1;
        assert Pow2(0) == 1;
        assert Pow2(1) == 2;
      } else {
        DepthBounds(k);
        var d := RecursiveSteps(k);
        assert d > 0;
        assert Pow2(d - 1) <= k;
        assert k < Pow2(d);
        assert RecursiveSteps(n) == d + 1;
        assert Pow2(d) == 2 * Pow2(d - 1);
        assert Pow2(d + 1) == 2 * Pow2(d);

        // Lower bound: n >= 2k >= 2 * 2^(d-1) = 2^d.
        assert 2 * Pow2(d - 1) <= 2 * k;
        assert Pow2(d) <= n;

        // Upper bound: n <= 2k+1 < 2*(k+1) <= 2*2^d.
        assert k + 1 <= Pow2(d);
        assert n < 2 * (k + 1);
        assert n < 2 * Pow2(d);
      }
    }
  }

  // The existing verified algorithm is now instrumented with an *actual*
  // counter returned by each recursive invocation. This is not a
  // stand-alone cost model disconnected from the implementation.
  method FastPair(n: nat) returns (x: int, y: int, steps: nat)
    ensures x == Fib(n)
    ensures y == Fib(n + 1)
    ensures steps == RecursiveSteps(n)
    decreases n
  {
    if n == 0 {
      x, y, steps := 0, 1, 0;
      return;
    }

    var k := n / 2;
    assert k < n;
    var a, b, childSteps := FastPair(k);

    Doubling(k);
    var even := a * (2 * b - a);
    var odd := a * a + b * b;
    assert even == Fib(2 * k);
    assert odd == Fib(2 * k + 1);

    if n % 2 == 0 {
      assert n == 2 * k;
      x, y := even, odd;
    } else {
      assert n == 2 * k + 1;
      assert Fib(2 * k + 2) == Fib(2 * k + 1) + Fib(2 * k);
      x, y := odd, even + odd;
    }

    steps := childSteps + 1;
  }

  // Preserve the public Level 1 result-only interface.
  method FastFib(n: nat) returns (result: int)
    ensures result == Fib(n)
  {
    var following: int;
    var steps: nat;
    result, following, steps := FastPair(n);
  }

  // The complexity-aware API certifies the exact observed step count
  // and its two-sided, logarithmic (binary bit-length) bound.
  method FastFibWithSteps(n: nat) returns (result: int, steps: nat)
    ensures result == Fib(n)
    ensures steps == RecursiveSteps(n)
    ensures n == 0 ==> steps == 0
    ensures n > 0 ==> steps > 0
    ensures n > 0 ==> Pow2(steps - 1) <= n
    ensures n > 0 ==> n < Pow2(steps)
  {
    var next: int;
    result, next, steps := FastPair(n);
    DepthBounds(n);
  }
}
