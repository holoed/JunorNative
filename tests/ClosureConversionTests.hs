module ClosureConversionTests where

import Test.Hspec
import Fixpoint
import ClosedAst
import ClosureConversion (convert)
import Parser (parseExpr)

close :: String -> Either String (Fix ClosedExpF)
close s = parseExpr s >>= convert

(-->) :: String -> String -> Expectation
(-->) x y = either id show (close x) `shouldBe` y

tests :: SpecWith ()
tests =
  describe "Closure Conversion Tests" $ do

    it "close a literal" $
      "42" --> "(Inl (Lit (I 42)))"

    it "close a lambda with no free vars" $
      "\\x -> x" --> "(Inr (MakeClosure (Inr (MakeEnv [])) (Inl (Lam \"x\" (Inl (Var \"x\"))))))"

    it "close a lambda with a free vars" $
      "\\x -> \\y -> x" --> "(Inr (MakeClosure (Inr (MakeEnv [])) (Inl (Lam \"x\" (Inr (MakeClosure (Inr (MakeEnv [(Inl (Var \"x\"))])) (Inl (Lam \"y\" (Inl (Var \"x\"))))))))))"