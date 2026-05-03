module DataConstructors where


import Control.Monad.Fail (MonadFail(..))
import E.E
import Name.Name

data DataTable
followAliases :: DataTable -> E -> E
followAlias :: (Monad m, MonadFail m) => DataTable -> E -> m E
typesCompatable :: (Monad m, MonadFail m) => E -> E -> m ()
updateLit :: DataTable -> Lit e t -> Lit e t
slotTypes :: DataTable -> Name -> E -> [E]
mktBox :: E -> E
