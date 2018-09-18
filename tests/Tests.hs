module Main where

import Test.Hspec
import qualified AlphaRenameTests
import qualified TypeInferenceTests
import qualified AnnotationsTests
import qualified FreeVariablesTests
import qualified ClosureConversionTests


main :: IO ()
main = hspec $ do
    AlphaRenameTests.tests
    TypeInferenceTests.tests
    AnnotationsTests.tests
    FreeVariablesTests.tests
    ClosureConversionTests.tests
