{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE TypeOperators #-}
module ClosedAst where

import Ast
import CoProduct
import Fixpoint

data ClosureF a = LookupEnv a Int
                | MakeEnv [a]
                | MakeClosure a a deriving (Show, Eq, Functor, Traversable, Foldable)

type ClosedExpF = ExpF :+: ClosureF

type ClosedExp = Fix ClosedExpF

mkClosure :: ClosedExp -> ClosedExp -> ClosedExp
mkClosure env clam = In (Inr (MakeClosure env clam))

mkEnv :: [ClosedExp] -> ClosedExp
mkEnv vars = In (Inr (MakeEnv vars))

cLam :: String -> ClosedExp -> ClosedExp
cLam s e = In (Inl (Lam s e))

cVar :: String -> ClosedExp
cVar s = In (Inl (Var s))
