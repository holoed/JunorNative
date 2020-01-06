module Types where

import Data.List (intercalate)
import Data.Set (Set, empty, union, singleton, null, foldl)
import Prelude hiding (null)

-- Qualified 

data Pred = IsIn String Type deriving (Eq, Ord)

data Qual t = Set Pred :=> t deriving Eq

instance Show Pred where
  show (IsIn n t) = n ++ " " ++ show t 

instance Show a => Show (Qual a) where
  show (ps :=> t) = 
    if (null ps) then show t
    else (Data.Set.foldl (\acc x -> acc ++ (show x)) "" ps) ++ " => " ++ show t

-- Type

data Type = TyCon String [Type]
          | TyVar String
          | TyLam Type Type deriving (Eq, Ord)

instance Show Type where
  show (TyCon name []) = name
  show (TyCon "Tuple" xs) = "(" ++ intercalate ", " (fmap show xs) ++ ")"
  show (TyVar name) = name
  show (TyLam t1 t2) = "(" ++ show t1 ++ " -> " ++ show t2 ++ ")"
  show _ = error "Not yet supported"

-- Type Schemes

data TypeScheme = ForAll (Set String) (Qual Type)
                | Identity (Qual Type)

getTVarsOfType :: Type -> Set String
getTVarsOfType (TyVar n) = singleton n
getTVarsOfType (TyLam t1 t2) = getTVarsOfType t1 `union` getTVarsOfType t2
getTVarsOfType (TyCon _ args) = Prelude.foldl (\ acc t -> acc `union` getTVarsOfType t) empty args
