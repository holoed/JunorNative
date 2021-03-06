{-# LANGUAGE QuasiQuotes #-}
module InterpreterTests where

import Data.String.Interpolate ( i )
import Test.Hspec ( describe, it, shouldBe, SpecWith, Expectation)
import Primitives ( Prim(I, B) )
import Interpreter (interpretModule, Result(..), InterpreterEnv)
import Parser (parseExpr)
import SynExpToExp (toExp)
import Location ( PString )
import Data.Map (fromList, member, (!?))
import Data.Maybe ( maybeToList )
import PAst ( SynExp, SynExpF(VarPat, Let) )
import Annotations ( Ann(Ann) )
import Fixpoint ( Fix(In) )


env :: InterpreterEnv
env = fromList [
    ("==", Function(\(Value x) -> return $ Function (\(Value y) -> return $ Value (B (x == y))))),
    ("*", Function(\(Value (I x)) -> return $ Function (\(Value (I y)) -> return $ Value (I (x * y))))),
    ("-", Function(\(Value (I x)) -> return $ Function (\(Value (I y)) -> return $ Value (I (x - y))))),
    ("+", Function(\(Value (I x)) -> return $ Function (\(Value (I y)) -> return $ Value (I (x + y))))),
    (":", Function(\x -> return $ Function (\(List xs) -> return $ List (x:xs) ))),
    ("head", Function(\(List xs) -> return $ head xs)),
    ("tail", Function(\(List xs) -> return $ List (tail xs))),
    ("null", Function(\(List xs) -> return $ Value (B $ null xs))),
    ("[]", List [])
 ]

extractName :: SynExp -> Maybe String
extractName (In (Ann _ (Let (In (Ann _ (VarPat n)):_) _ _))) = Just n
extractName _ = Nothing

run :: String -> Either PString [Result]
run code = do ast <- parseExpr code
              env' <- interpretModule env (toExp <$> ast)
              return $ getItem ast env'
    where getItem ast xs = maybeToList $
           if member "it" xs then xs!?"it"
           else extractName (last ast) >>= (xs!?)

(-->) :: String -> String -> Expectation
(-->) code v  = either show show (run code) `shouldBe` v

tests :: SpecWith ()
tests =
  describe "Interpreter tests" $ do

    it "Literal" $ do
        "42" --> "[42]"

    it "let Value" $ do
        "let x = 42" --> "[42]"

    it "let Function" $ do
        "let f x = x" --> "[<function>]"

    it "Applied function" $ do
        "let fac n = if n == 0 then 1 else n * (fac (n - 1)) in fac 5" --> "[120]"

    it "Two dependent bindings" $ do
        [i|let x = 42
           let y = x + 1|] --> "[43]"

    it "Recursive higher order function" $ do
        [i|let foldl f v xs =
                 if (null xs) then v
                else foldl f (f v (head xs)) (tail xs)
  
           let main = foldl (*) 1 (1:2:3:4:5:[])  |] --> "[120]"
