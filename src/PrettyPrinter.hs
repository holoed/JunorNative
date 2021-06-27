module PrettyPrinter where

import Primitives ( Prim(U, I, D, B, S) )
import PAst ( SynExp, SynExpF(IfThenElse, Lit, Var, VarPat, Lam, InfixApp, MkTuple, TuplePat, Let) )
import Operators ( Operator, Fixity(Infix, Postfix, Prefix), Associativity(..), lamOp, minOp )
import RecursionSchemes ( cataRec )
import Data.List ( intersperse )
import Text.PrettyPrint ( (<+>), (<>), char, hcat, parens, render, text, Doc )
import Control.Monad.Writer ( runWriter, MonadWriter(tell, listen), Writer )
import Prelude hiding (Left, Right, (<>), pi)
import Annotations ( unwrap )

parenthesize :: Doc -> Doc
parenthesize d = text "(" <> d <> text ")"

noparens ::Operator -> Operator -> Associativity -> Bool
noparens (_, pi, fi) (_, po, fo) side = pi > po || other fi side
  where other Postfix Left  = True
        other Prefix  Right = True
        other (Infix Left) Left = pi == po && fo == Infix Left
        other (Infix Right) Right = pi == po && fo == Infix Right
        other _ NonAssoc = fi == fo
        other _ _ = False

bracket :: Associativity -> Operator -> [Operator] -> Doc -> Doc
bracket _ _ [] doc = doc
bracket side outer (inner:_) doc =
  if noparens inner outer side then doc else parenthesize doc

alg :: SynExpF (Writer [Operator] Doc) -> Writer [Operator] Doc
alg (Lit (I v)) =
   return $ text (show v)
alg (Lit (D v)) =
   return $ text (show v)
alg (Lit (B b)) =
   return $ text (show b)
alg (Lit (S s)) =
   return $ text s
alg (Lit U) =
   return $ text "()"
alg (VarPat x) =
   return $ if x == "++"
   then text "(" <> text x <> text ")"
   else text x
alg (Var x) =
   return $ if x == "++"
   then text "(" <> text x <> text ")"
   else text x
alg (Lam ns e) = do
  ns' <- sequence ns
  e' <- e
  _ <- tell [lamOp]
  return $ char '\\' <> head ns' <+> text "->" <+> e'
alg (InfixApp op@(opName, _, _) e1 e2) = do
    (e1', l) <- listen e1
    (e2', r) <- listen e2
    _ <- tell [op]
    let opTxt = if opName == " " then opName else " " ++ opName ++ " "
    return (bracket Left op l e1' <> text opTxt <> bracket Right op r e2')
alg (MkTuple es) = do
  es' <- sequence es
  return $ parens $ hcat $ intersperse (text ", ") es'
alg (TuplePat es) = do
  es' <- sequence es
  return $ parens $ hcat $ intersperse (text ", ") es'
alg (Let [n] v b) = do
  n' <- n
  v' <- v
  b' <- b
  _ <- tell [minOp]
  if b' == n' then return $ text "let" <+> n' <+> char '=' <+> v'
  else return $ text "let" <+> n' <+> char '=' <+> v' <+> text "in" <+> b'
alg (Let ns v b) = do
  ns' <- sequence ns
  let n:xs = ns'
  v' <- v
  b' <- b
  _ <- tell [minOp]
  if b' == n then return $ text "let" <+> n <+> foldr (flip (<+>)) (head xs) (tail xs) <+> char '=' <+> v'
  else return $ text "let" <+> n <+> foldr (flip (<+>)) (head xs) (tail xs) <+> char '=' <+> v' <+> text "in" <+> b'
alg (IfThenElse q t f) = do
  q' <- q
  t' <- t
  f' <- f
  _ <- tell [minOp]
  return $ text "if" <+> q' <+> text "then" <+> t' <+> text "else" <+> f'
alg _ = error "Undefined"

pretty :: SynExp -> String
pretty = render . fst . runWriter . cataRec alg . unwrap
