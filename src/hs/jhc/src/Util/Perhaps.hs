module Util.Perhaps where

import Data.Typeable
import Data.Monoid
import Data.Semigroup (Semigroup(..))

data Perhaps = No | Maybe | Yes
    deriving(Show,Read,Typeable,Eq,Ord)


-- the greatest lower bound was chosen as the Monoid
-- the least upper bound is just the maximum under Ord

instance Semigroup Perhaps where
    Yes <> Yes = Yes
    No  <> No  = No
    _   <> _   = Maybe

