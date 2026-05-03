module Name.Binary() where

import Data.Monoid
import Data.Maybe
import qualified Data.Maybe as Maybe
import qualified Data.Maybe as Maybe

import Data.Binary
import GenUtil(replicateM)
import Name.Id
import Name.Internals
import qualified Support.MapBinaryInstance as MB

instance Binary IdSet where
    put ids = do
        MB.putList [ id | id <- idSetToList ids, isNothing (fromId id)]
        MB.putList [ n | id <- idSetToList ids, n <- fromId id]
    get = do
        (idl:: [Id])   <- MB.getList
        (ndl:: [Name]) <- MB.getList
        return (idSetFromDistinctAscList idl `mappend` idSetFromList (map toId ndl))

instance Binary a => Binary (IdMap a) where
    put ids = do
        MB.putList [ x | x@(id,_) <- idMapToList ids, isNothing (fromId id)]
        MB.putList [ (n,v) | (id,v) <- idMapToList ids, n <- fromId id]
    get = do
        idl <- MB.getList
        ndl <- MB.getList
        return (idMapFromDistinctAscList idl `mappend` idMapFromList [ (toId n,v) | (n,v) <- ndl ])
