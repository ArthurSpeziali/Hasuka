module Util.Seq(
            Seq()

          , singleton
          , cons
          , snoc

          , Util.Seq.toList
          , appendToList
          , fromList
          , Util.Seq.concat
          ) where

import Control.Applicative
import Control.Monad (Monad, MonadPlus(..), ap, liftM)
import Data.Foldable(Foldable(..))
import Prelude hiding (toList)
import Data.Semigroup (Semigroup(..))
import Data.Monoid (Monoid(..))
import Data.Traversable (Traversable(..))
import qualified Control.Monad.Fail as Fail

newtype Seq a = Seq ([a] -> [a])

singleton :: a -> Seq a
singleton x = Seq (\ts -> x:ts)

cons :: a -> Seq a -> Seq a
cons x (Seq f) = Seq (\ts -> x:f ts)

snoc :: Seq a -> a ->  Seq a
snoc (Seq f) x = Seq (\ts -> f (x:ts))

toList :: Seq a -> [a]
toList (Seq f) = f []

appendToList :: Seq a -> [a] -> [a]
appendToList (Seq f) xs = f xs

fromList :: [a] -> Seq a
fromList xs = Seq (\ts -> xs++ts)

concat :: Seq (Seq a) -> Seq a
concat (Seq f) = (Prelude.foldr mappend mempty (f []))

instance Functor Util.Seq.Seq where
    --fmap f xs = Seq.fromList (map f (Seq.toList xs))
    fmap f (Seq xs) = Seq (\ts -> map f (xs []) ++ ts )

instance Monad Seq where
    (>>=)  = \a b -> Util.Seq.concat (fmap b a)
    return = pure

instance Fail.MonadFail Util.Seq.Seq where
    fail _ = mempty

instance Applicative Seq where
    pure = singleton
    (<*>) = ap

instance Traversable Seq where
    traverse f (Seq g) = fmap fromList (traverse f (g []))

instance Foldable Util.Seq.Seq where
    foldMap f s = mconcat (map f (Util.Seq.toList s))

instance Alternative Util.Seq.Seq where
    empty = mzero
    (<|>) = mplus

instance MonadPlus Util.Seq.Seq where
    mplus = mappend
    mzero = mempty

instance Semigroup (Seq a) where
    (Seq f) <> (Seq g) = Seq (f . g)

instance Monoid (Seq a) where
    mempty = Seq id
    mappend = (<>)
