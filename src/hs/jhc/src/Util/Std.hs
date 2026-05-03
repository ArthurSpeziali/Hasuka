-- standard modules we almost always want
module Util.Std(
        module Control.Applicative,
        module Control.Monad,
        module Control.Monad.Identity,
        module Data.Foldable,
        module Data.List,
        module Data.Maybe,
        module Data.Monoid,
        module Data.Traversable,
        module System.Environment
        )where

import Control.Applicative
import Control.Monad
import Control.Monad.Identity
import Data.List hiding (singleton, insert, delete, union, find, intersect)
import qualified Data.List as List
import qualified Data.List as List hiding(null)
import Data.Maybe
import qualified Data.Maybe as Maybe
import qualified Data.Maybe as Maybe
import Data.Monoid(Monoid(..),(<>))
import qualified System.Environment as System
import qualified System.Exit as System
import qualified System.Process as System
import System.Environment
import qualified System.Environment as System(getArgs,getProgName)
-- we want the names for deriving
import Data.Traversable(Traversable())
import Data.Foldable(Foldable())
