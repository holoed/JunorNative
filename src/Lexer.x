{
{-# LANGUAGE FlexibleContexts #-}
module Lexer (
  Token(..),
  scanTokens
) where

import PAst
import Primitives

import Control.Monad.Except

}

%wrapper "basic"

$digit = 0-9
$alpha = [a-zA-Z]
$eol   = [\n]
$graphic = $printable # $white
@string = \" ($graphic # \")* \"

tokens :-

  -- Whitespace insensitive
  $eol                          ;
  $white+                       ;

  -- Comments
  "#".*                         ;

  -- Syntax
  let                           { \s -> TokenLet }
  True                          { \s -> TokenTrue }
  False                         { \s -> TokenFalse }
  if                            { \s -> TokenIf }
  then                          { \s -> TokenThen }
  else                          { \s -> TokenElse }
  in                            { \s -> TokenIn }
  $digit+                       { \s -> TokenNum (I $ read s) }
  @string                       { \s -> TokenString (S s) }
  "->"                          { \s -> TokenArrow }
  "=="                          { \s -> TokenEql }
  \=                            { \s -> TokenEq }
  \\                            { \s -> TokenLambda }
  [\+]                          { \s -> TokenAdd }
  [\-]                          { \s -> TokenSub }
  [\*]                          { \s -> TokenMul }
  [\/]                          { \s -> TokenDiv }
  [\>]                          { \s -> TokenGt  }
  [\<]                          { \s -> TokenLt  }
  \(                            { \s -> TokenLParen }
  \)                            { \s -> TokenRParen }
  ","                           { \s -> TokenComma }
  $alpha [$alpha $digit \_ \']* { \s -> TokenSym s }

{

data Token
  = TokenLet
  | TokenIf
  | TokenThen
  | TokenElse
  | TokenIn
  | TokenLambda
  | TokenTrue
  | TokenFalse
  | TokenNum Prim
  | TokenString Prim
  | TokenSym String
  | TokenArrow
  | TokenEq
  | TokenEql
  | TokenAdd
  | TokenSub
  | TokenMul
  | TokenDiv
  | TokenGt
  | TokenLt
  | TokenLParen
  | TokenRParen
  | TokenComma
  | TokenEOF
  deriving (Eq,Show)

scanTokens :: String -> Except String [Token]
scanTokens str = go ('\n',[],str) where
  go inp@(_,_bs,str) =
    case alexScan inp 0 of
     AlexEOF -> return []
     AlexError _ -> throwError "Invalid lexeme."
     AlexSkip  inp' len     -> go inp'
     AlexToken inp' len act -> do
      res <- go inp'
      let rest = act (take len str)
      return (rest : res)

}
