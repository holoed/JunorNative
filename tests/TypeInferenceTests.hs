module TypeInferenceTests where

import qualified Data.Set as Set
import Test.Hspec
import Types
import Environment
import Infer (infer)
import Parser (parseExpr)
import Substitutions
import LiftNumbers

env :: Env
env = toEnv [("id", Set.fromList [] :=> TyLam (TyVar "a") (TyVar "a")),
            ("==", Set.fromList [IsIn "Eq" (TyVar "a")] :=> TyLam (TyVar "a") (TyLam (TyVar "a") (TyCon "Bool" []))),
            ("-",  Set.fromList [IsIn "Num" (TyVar "a")] :=> TyLam (TyVar "a") (TyLam (TyVar "a") (TyVar "a"))),
            ("+",  Set.fromList [IsIn "Num" (TyVar "a")] :=> TyLam (TyVar "a") (TyLam (TyVar "a") (TyVar "a"))),
            ("*",  Set.fromList [IsIn "Num" (TyVar "a")] :=> TyLam (TyVar "a") (TyLam (TyVar "a") (TyVar "a"))),
            ("/",  Set.fromList [IsIn "Fractional" (TyVar "a")] :=> TyLam (TyVar "a") (TyLam (TyVar "a") (TyVar "a"))),
            (">",  Set.fromList [IsIn "Ord" (TyVar "a")] :=> TyLam (TyVar "a") (TyLam (TyVar "a") (TyCon "Bool" []))),
            ("<",  Set.fromList [IsIn "Ord" (TyVar "a")] :=> TyLam (TyVar "a") (TyLam (TyVar "a") (TyCon "Bool" []))),
            ("fst", Set.fromList [] :=> TyLam (TyCon "Tuple" [TyVar "a", TyVar "b"]) (TyVar "a")),
            ("snd", Set.fromList [] :=> TyLam (TyCon "Tuple" [TyVar "a", TyVar "b"]) (TyVar "b")),
            ("fromInteger", Set.fromList [IsIn "Num" (TyVar "a")] :=> TyLam (TyCon "Int" []) (TyVar "a")),
            ("fromRational", Set.fromList [IsIn "Fractional" (TyVar "a")] :=> TyLam (TyCon "Double" []) (TyVar "a"))
     ]

typeOf :: String -> Either String (Substitutions, Qual Type)
typeOf s = parseExpr s >>= (infer env . liftN)

(-->) :: String -> String -> Expectation
(-->) x y = either id (show . snd) (typeOf x) `shouldBe` y

tests :: SpecWith ()
tests =
  describe "Type Inference Tests" $ do

    it "type of a literal" $ do
      "42" --> "Num a => a"
      "\"Hello\"" --> "String"

    it "type of simple math" $ do
      "12 + 24" --> "Num a => a"
      "2 * (3 + 2)" --> "Num a => a"
      "3 - (2 / 3)" --> "(Fractional a, Num a) => a"

    it "type of simple class constraints" $ do 
      "2 > 3" --> "Bool"
      "\\x -> (x + x) < (x * x)" --> "(Num a, Ord a) => (a -> Bool)"

    it "type of a name" $ do
      "id" --> "(a -> a)"
      "foo" --> "Name foo not found."

    it "type of identity" $
      "\\x -> x" --> "(a -> a)"

    it "type of nested lam that take 2 arg and return first" $
      "\\x -> \\y -> x" --> "(a -> (b -> a))"

    it "type of composition" $
      "\\f -> \\g -> \\x -> g (f x)" --> "((a -> b) -> ((b -> c) -> (a -> c)))"

    it "type of fmap" $
      "\\f -> \\m -> \\ctx -> f (m (ctx))" --> "((a -> b) -> ((c -> a) -> (c -> b)))"

    it "type of applying identity to Int" $
      "id 42" --> "Num a => a"

    it "type of conditionals" $ do
      "if True then 5 else 6" --> "Num a => a"
      -- TODO: Implement Context Reduction step 
      -- "if True then 5 else False" --> "Unable to unify Bool with Int"
      -- "if True then True else 5" -->  "Unable to unify Int with Bool"
      -- "if 5 then True else False" --> "Unable to unify Int with Bool"

    it "type of tuple" $ do
      "(2, True)" --> "Num a => (a, Bool)"
      "(False, 4)" --> "Num a => (Bool, a)"
      "\\x -> (x, x)" --> "(a -> (a, a))"
      "\\x -> \\y -> (y, x)" --> "(a -> (b -> (b, a)))"

    it "type of let" $ do
      "let x = 42 in x" --> "Num a => a"
      "let pair = (True, 12) in pair" --> "Num a => (Bool, a)"
      "let x = if (True) then 2 else 3 in x + 1" --> "Num a => a"
      "let foo = \\x -> x + x in foo" --> "Num a => (a -> a)"

    it "type of functions" $ do
      "let f = \\x -> x in f" --> "(a -> a)"
      "let swap = \\p -> (snd p, fst p) in swap" --> "((a, b) -> (b, a))"
      "let fix = \\f -> f (fix f) in fix" --> "((a -> a) -> a)"
      "let fac = \\n -> if (n == 0) then 1 else n * (fac (n - 1)) in fac" --> "(Eq a, Num a) => (a -> a)"
      "let f = \\x -> x in (f 5, f True)" --> "Num a => (a, Bool)"
      -- https://ghc.haskell.org/trac/ghc/blog/LetGeneralisationInGhc7
      "let f = \\x -> let g = \\y -> (x, y) in (g 3, g True) in f" --> "Num a => (b -> ((b, a), (b, Bool)))"

    it "Apply function with wrong tuple arity" $ do
      "let f = \\x -> (fst x, snd x) in f (1, 2, 3)" --> "Unable to unify (T11, T12, T13) with (aT8T10, T4T10)"
