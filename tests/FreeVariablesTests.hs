module FreeVariablesTests where

import Test.Hspec ( describe, it, shouldBe, SpecWith )
import Fixpoint ( Fix(In) )
import Annotations ( Ann(Ann) )
import Primitives ( Prim(I) )
import Ast
    ( ExpF(Var, MkTuple, App, Lam, Let, Lit, IfThenElse),
      lit,
      var,
      app,
      lam,
      leT,
      ifThenElse,
      mkTuple )
import FreeVariables ( freeVars )
import Data.Set ( empty, fromList )

tests :: SpecWith ()
tests =
  describe "Free Variables Tests" $ do

    it "Free vars of a literal" $
      freeVars empty (lit $ I 42) `shouldBe` In (Ann (fromList []) (Lit $ I 42))

    it "Free vars of a variable" $
      freeVars empty (var "x") `shouldBe` In (Ann (fromList ["x"]) (Var "x"))

    it "Free vars of a tuple" $
      freeVars empty (mkTuple [var "x", var "y"]) `shouldBe`
        In (Ann (fromList ["x", "y"]) $ MkTuple [In (Ann (fromList ["x"]) (Var "x")), In (Ann (fromList ["y"]) (Var "y"))])

    it "Free vars of an application" $
      freeVars empty (app (var "f") (var "x")) `shouldBe`
        In (Ann (fromList ["f", "x"]) $ App (In (Ann (fromList ["f"]) (Var "f"))) (In (Ann (fromList ["x"]) (Var "x"))))

    it "Free vars of a lambda" $ do
      freeVars empty (lam "x" (var "x")) `shouldBe` In (Ann (fromList []) (Lam "x" (In (Ann (fromList ["x"]) (Var "x")))))
      freeVars empty (lam "x" (lam "y" (var "x"))) `shouldBe`
        In (Ann (fromList []) (Lam "x" (In (Ann (fromList ["x"]) (Lam "y" (In (Ann (fromList ["x"]) (Var "x"))))))))

    it "Free vars of a let" $ do
      freeVars empty (leT "x" (lit $ I 42) (var "x")) `shouldBe`
        In (Ann (fromList []) (Let "x" (In (Ann (fromList []) (Lit $ I 42))) (In (Ann (fromList ["x"]) (Var "x")))))
      freeVars empty (leT "x" (lit $ I 42) (leT "y" (lit $ I 24) (var "x"))) `shouldBe`
        In (Ann (fromList []) (Let "x" (In (Ann (fromList []) (Lit $ I 42)))
          (In (Ann (fromList ["x"]) (Let "y" (In (Ann (fromList []) (Lit $ I 24))) (In (Ann (fromList ["x"]) (Var "x"))))))))

    it "Free vars of if then else" $
      freeVars empty (ifThenElse (var "x") (var "y") (var "z")) `shouldBe`
        In (Ann (fromList ["x", "y", "z"]) (IfThenElse (In (Ann (fromList ["x"]) (Var "x")))
                                                       (In (Ann (fromList ["y"]) (Var "y")))
                                                       (In (Ann (fromList ["z"]) (Var "z")))))
