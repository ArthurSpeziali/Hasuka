{-# LANGUAGE TypeFamilies #-}
module Util.ContextMonad where

import qualified Control.Monad.Fail as Fail

import Control.Applicative
import Control.Monad
import Control.Monad.Error

class Monad m => ContextMonad m where
    type ContextOf m
    withContext :: ContextOf m -> m a -> m a

instance Error [String] where
    noMsg = []
    strMsg s = [s]

newtype ContextEither a = ContextEither (Either [String] a)
    deriving(Functor)

runContextEither (ContextEither a) = a

instance Monad ContextEither where
    ContextEither x >>= y = case x of
        Left ss -> ContextEither (Left ss)
        Right v -> y v
    return x = ContextEither (Right x)

instance Fail.MonadFail ContextEither where
    fail s = ContextEither (Left [s])

instance ContextMonad ContextEither where
    type ContextOf ContextEither = String
    withContext s (ContextEither (Left ss)) = ContextEither (Left (s:ss))
    withContext _ r = r

runSimpleContextMonad :: ContextEither a -> a
runSimpleContextMonad (ContextEither (Left ss)) = error $ unlines ss
runSimpleContextMonad (ContextEither (Right x)) = x
instance Applicative ContextEither where { pure = return; (<*>) = ap }
instance Alternative ContextEither where { empty = ContextEither (Left []); ContextEither (Left _) <|> r = r; l <|> _ = l }
