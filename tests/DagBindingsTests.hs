{-# LANGUAGE QuasiQuotes #-}
module DagBindingsTests where

import Parser (parseExpr)
import DagBindings ( deps, chunks )
import SynExpToExp ( toExp )
import Data.String.Interpolate ( i )
import Data.Set (Set, fromList)
import Test.Hspec ( it, describe, shouldBe, SpecWith )

globals :: Set [Char]
globals = fromList ["+", "-", "/", "++", "==", ">", "<", "hd", "tl", "null", "empty", "cons", "singleton"]

tests :: SpecWith ()
tests = do
  describe "Build dependencies" $ do

   let build code = deps globals $ toExp <$> either error id (parseExpr code)
   let (-->) x y = build x `shouldBe` y

   it "No deps" $ "let x = 42" --> [("x", [])]

   it "One dep" $ "let foo = fac 5" --> [("foo", ["fac"])]

   it "Many deps" $ [i|let quicksort f xs =
                        if (null xs) then xs else  
                        let lessThan = filter (\\x -> f x < f (hd xs)) (tl xs) in 
                        let greaterThan = filter (\\x -> f x > f (hd xs)) (tl xs) in
                        (quickSort f lessThan) ++ singleton (hd xs) ++ (quickSort f greaterThan)
                    |] --> [("quicksort",["filter","quickSort"])]

   it "Multi bindings deps" $ [i| let x = 12
                                  let y = 32
                                  let z = x + y |] --> [("z",["x","y"]),("y",[]),("x",[])]

  describe "Build chunks" $ do

    let build code = chunks globals $ toExp <$> either error id (parseExpr code)
    let (-->) x y = build x `shouldBe` y

    it "single node" $ "let x = 42" --> [[("x",[])]]

    it "two indipendent nodes" $ 
               [i| let x = 12
                   let y = 32 |] --> [[("y", []), ("x", [])]]

    it "two dependent nodes" $ 
               [i| let x = 12
                   let y = x + 1 |] --> [[("x", [])],[("y", ["x"])]]

    it "one node depending on two" $ 
               [i| let x = 12
                   let y = 32
                   let z = x + y |] --> [[("y", []), ("x", [])],[("z", ["x", "y"])]]

    it "Many nodes" $ [i|       
                      let foldr f v xs = 
                         if (null xs) then v 
                         else f (hd xs) (foldr f v (tl xs)) 

                      let concat xs ys = foldr cons ys
                     
                      let filter p = foldr (\\x -> \\xs -> if (p x) then cons x xs else xs) empty
                    
                      let quicksort f xs =
                        if (null xs) then xs else  
                        let lessThan = filter (\\x -> f x < f (hd xs)) (tl xs) in 
                        let greaterThan = filter (\\x -> f x > f (hd xs)) (tl xs) in
                        concat (concat (quicksort f lessThan) (singleton (hd xs))) (quicksort f greaterThan)
                      |] --> [[("foldr",[])],[("filter",["foldr"]),("concat",["foldr"])],[("quicksort",["concat","filter"])]]
                       

