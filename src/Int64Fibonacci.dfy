// Level 3: Certified signed-64-bit bounds for fast Fibonacci.
// This file is verified alongside FastFibonacci.dfy via include.
include "FastFibonacci.dfy"

module Int64Fibonacci {
  import opened FastFibonacci

  const MAX64: int := 9223372036854775807
  const MIN64: int := -9223372036854775808

  // A refinement (subset) type; an expression may enter this type only
  // after Dafny proves that it is in the signed 64-bit range.
  type I64 = x: int | MIN64 <= x <= MAX64 witness 0

  // Independent arithmetic fact: Fibonacci numbers are nonnegative.
  lemma FibNonnegative(n: nat)
    ensures 0 <= Fib(n)
    decreases n
  {
    if n >= 2 {
      FibNonnegative(n - 1);
      FibNonnegative(n - 2);
    }
  }

  lemma FibMonotone(n: nat)
    ensures Fib(n) <= Fib(n + 1)
  {
    if n > 0 {
      FibNonnegative(n - 1);
      assert Fib(n + 1) == Fib(n) + Fib(n - 1);
    }
  }

  lemma FibOrder(n: nat, top: nat)
    requires n <= top
    ensures Fib(n) <= Fib(top)
    decreases top - n
  {
    if n < top {
      FibOrder(n + 1, top);
      FibMonotone(n);
    }
  }

  // Check only low indices directly. Fast doubling proves values at
  // 46/47 and 92/93 without expanding a 93-step recurrence.
  lemma BoundaryValues()
    ensures Fib(46) == 1836311903
    ensures Fib(47) == 2971215073
    ensures Fib(92) == 7540113804746346429
    ensures Fib(93) == 12200160415121876738
    ensures Fib(92) <= MAX64
    ensures MAX64 < Fib(93)
  {
    assert Fib(0) == 0;
    assert Fib(1) == 1;
    assert Fib(2) == 1;
    assert Fib(3) == 2;
    assert Fib(4) == 3;
    assert Fib(5) == 5;
    assert Fib(6) == 8;
    assert Fib(7) == 13;
    assert Fib(8) == 21;
    assert Fib(9) == 34;
    assert Fib(10) == 55;
    assert Fib(11) == 89;
    assert Fib(12) == 144;
    assert Fib(13) == 233;
    assert Fib(14) == 377;
    assert Fib(15) == 610;
    assert Fib(16) == 987;
    assert Fib(17) == 1597;
    assert Fib(18) == 2584;
    assert Fib(19) == 4181;
    assert Fib(20) == 6765;
    assert Fib(21) == 10946;
    assert Fib(22) == 17711;
    assert Fib(23) == 28657;
    assert Fib(24) == 46368;
    Doubling(23);
    assert Fib(46) == Fib(23) * (2 * Fib(24) - Fib(23));
    assert Fib(47) == Fib(23) * Fib(23) + Fib(24) * Fib(24);
    Doubling(46);
    assert Fib(92) == Fib(46) * (2 * Fib(47) - Fib(46));
    assert Fib(93) == Fib(46) * Fib(46) + Fib(47) * Fib(47);
  }

  // The pair (F(n), F(n+1)) is representable only through n=91.
  // Every intermediate operation is assigned to I64 only after its
  // representable range is proved.
  method FastPair64(n: nat) returns (x: I64, y: I64)
    requires n <= 91
    ensures x == Fib(n)
    ensures y == Fib(n + 1)
    decreases n
  {
    if n == 0 {
      x, y := 0, 1;
      return;
    }

    var k := n / 2;
    assert k < n;
    assert k <= 45;
    var a, b := FastPair64(k);

    BoundaryValues();
    FibNonnegative(k);
    FibNonnegative(k + 1);
    FibMonotone(k);
    assert 0 <= a <= b;
    FibOrder(k + 1, 47);
    assert b <= Fib(47);

    // Bound every arithmetic intermediate (not just the final answer).
    assert 0 <= 2 * b <= 2 * Fib(47);
    assert 2 * Fib(47) <= MAX64;
    var twice: I64 := 2 * b;
    assert 0 <= twice - a <= twice;
    var difference: I64 := twice - a;

    Doubling(k);
    FibOrder(2 * k, 92);
    FibNonnegative(2 * k);
    assert a * difference == Fib(2 * k);
    assert 0 <= a * difference <= MAX64;
    var even: I64 := a * difference;

    FibOrder(2 * k + 1, 92);
    FibNonnegative(2 * k + 1);
    assert a * a + b * b == Fib(2 * k + 1);
    assert 0 <= a * a;
    assert 0 <= b * b;
    assert a * a <= a * a + b * b <= MAX64;
    assert b * b <= a * a + b * b <= MAX64;
    var aa: I64 := a * a;
    var bb: I64 := b * b;
    var odd: I64 := aa + bb;

    if n % 2 == 0 {
      assert n == 2 * k;
      x, y := even, odd;
    } else {
      assert n == 2 * k + 1;
      assert n + 1 == 2 * k + 2;
      FibOrder(n + 1, 92);
      FibNonnegative(n + 1);
      assert Fib(n + 1) == Fib(2 * k) + Fib(2 * k + 1);
      assert 0 <= even + odd <= MAX64;
      var next: I64 := even + odd;
      x, y := odd, next;
    }
  }

  // Result-only interface reaches F(92) without computing F(93).
  // n<=91 uses the safe pair; the n=92 branch computes only F(92).
  method FastFib64(n: nat) returns (result: I64)
    requires n <= 92
    ensures result == Fib(n)
  {
    if n <= 91 {
      var following: I64;
      result, following := FastPair64(n);
    } else {
      assert n == 92;
      var a, b := FastPair64(46);
      BoundaryValues();
      assert 0 <= a <= b;
      assert 2 * b <= MAX64;
      var twice: I64 := 2 * b;
      assert 0 <= twice - a <= MAX64;
      var difference: I64 := twice - a;
      Doubling(46);
      assert a * difference == Fib(92);
      assert 0 <= Fib(92) <= MAX64;
      result := a * difference;
    }
  }

  // Maximal signed-64-bit domain of the value F(n), for natural n.
  lemma ExactResultDomain(n: nat)
    ensures n <= 92 ==> 0 <= Fib(n) <= MAX64
    ensures n >= 93 ==> Fib(n) > MAX64
  {
    BoundaryValues();
    if n <= 92 {
      FibNonnegative(n);
      FibOrder(n, 92);
    } else {
      FibOrder(93, n);
    }
  }

  // The pair requires representability of F(n+1), making 91
  // the maximum safe index for a complete pair.
  lemma ExactPairDomain(n: nat)
    ensures n <= 91 ==> 0 <= Fib(n + 1) <= MAX64
    ensures n >= 92 ==> Fib(n + 1) > MAX64
  {
    ExactResultDomain(n + 1);
  }
  // The returned consecutive pair cannot fit when n=92 because
  // its second component would be F(93)>MAX64.
  lemma PairCannotFitAt92()
    ensures Fib(92) <= MAX64
    ensures Fib(93) > MAX64
  {
    BoundaryValues();
  }
}
