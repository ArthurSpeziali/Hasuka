module Grin.Show where

import Doc.Pretty
import Doc.DocLike
import StringTable.Atom as Atom
import {-# SOURCE #-} Grin.Grin

prettyFun :: (Atom.Atom,Grin.Grin.Lam) -> Doc.Pretty.Doc
prettyExp :: Doc.Pretty.Doc -> Grin.Grin.Exp -> Doc.Pretty.Doc
prettyVal :: DocLike d => Grin.Grin.Val -> d
