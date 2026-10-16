// FMSE H24: verified fast Fibonacci using the fast-doubling identities.
// Everything below uses unbounded mathematical integers.
module FastFibonacci {
  // Independent mathematical specification.
  function Fib(n: nat): int
    decreases n
  {
    if n < 2 then n else Fib(n - 1) + Fib(n - 2)
  }

  // The algebraic heart of fast doubling:
  // F(2k)   = F(k) * (2*F(k+1) - F(k))
  // F(2k+1) = F(k)^2 + F(k+1)^2.
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

      // Induction hypotheses from k - 1.
      assert 2 * (k - 1) == 2 * k - 2;
      assert 2 * (k - 1) + 1 == 2 * k - 1;
      assert Fib(2 * k - 2) == a * (2 * b - a);
      assert Fib(2 * k - 1) == a * a + b * b;

      // Prove the even identity.
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

      // Prove the odd identity.
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

  // Logarithmic-depth algorithm; never calls specification Fib at runtime.
  method FastPair(n: nat) returns (x: int, y: int)
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
    var a, b := FastPair(k);

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
  }

  method FastFib(n: nat) returns (result: int)
    ensures result == Fib(n)
  {
    var following: int;
    result, following := FastPair(n);
  }
}
