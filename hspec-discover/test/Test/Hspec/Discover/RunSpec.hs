module Test.Hspec.Discover.RunSpec (main, spec) where

import           Helper

import           System.IO
import           System.Directory
import           System.FilePath
import           Data.List (sort)

import           Test.Hspec.Discover.Run hiding (Spec)
import qualified Test.Hspec.Discover.Run as Run

main :: IO ()
main = hspec spec

withTempFile :: (FilePath -> IO a) -> IO a
withTempFile action = do
  dir <- getTemporaryDirectory
  (file, h) <- openTempFile dir ""
  hClose h
  action file <* removeFile file


spec :: Spec
spec = do
  describe "run" $ do
    it "generates test driver" $ withTempFile $ \f -> do
      run ["test-data/nested-spec/Spec.hs", "", f]
      readFile f `shouldReturn` unlines [
          "{-# LINE 1 \"test-data/nested-spec/Spec.hs\" #-}"
        , "{-# LANGUAGE NoImplicitPrelude #-}"
        , "{-# OPTIONS_GHC -fno-warn-warnings-deprecations #-}"
        , "module Main where"
        , "import qualified Foo.Bar.BazSpec"
        , "import qualified Foo.BarSpec"
        , "import qualified FooSpec"
        , "import Test.Hspec.Discover"
        , "main :: IO ()"
        , "main = hspec spec"
        , "spec :: Spec"
        , "spec = " ++ unwords [
               "describe \"Foo.Bar.Baz\" Foo.Bar.BazSpec.spec"
          , ">> describe \"Foo.Bar\" Foo.BarSpec.spec"
          , ">> describe \"Foo\" FooSpec.spec"
          ]
        ]

    it "generates test driver for an empty directory" $ withTempFile $ \f -> do
      run ["test-data/empty-dir/Spec.hs", "", f]
      readFile f `shouldReturn` unlines [
          "{-# LINE 1 \"test-data/empty-dir/Spec.hs\" #-}"
        , "{-# LANGUAGE NoImplicitPrelude #-}"
        , "{-# OPTIONS_GHC -fno-warn-warnings-deprecations #-}"
        , "module Main where"
        , "import Test.Hspec.Discover"
        , "main :: IO ()"
        , "main = hspec spec"
        , "spec :: Spec"
        , "spec = return ()"
        ]

  describe "pathToModule" $ do
    it "derives module name from a given path" $ do
      pathToModule "test/Spec.hs" `shouldBe` "Spec"

  describe "getFilesRecursive" $ do
    it "recursively returns all file entries of a given directory" $ do
      getFilesRecursive "test-data" `shouldReturn` sort [
          "empty-dir/Foo/Bar/Baz/.placeholder"
        , "nested-spec/Foo/Bar/BazSpec.hs"
        , "nested-spec/Foo/BarSpec.hs"
        , "nested-spec/FooSpec.hs"
        ]

  describe "fileToSpec" $ do
    it "converts path to spec name" $ do
      fileToSpec "FooSpec.hs" `shouldBe` Just (Run.Spec "Foo")

    it "rejects spec with empty name" $ do
      fileToSpec "Spec.hs" `shouldBe` Nothing

    it "works for lhs files" $ do
      fileToSpec "FooSpec.lhs" `shouldBe` Just (Run.Spec "Foo")

    it "returns Nothing for invalid spec name" $ do
      fileToSpec "foo" `shouldBe` Nothing

    context "when spec does not have a valid module name" $ do
      it "returns Nothing" $ do
        fileToSpec "flycheck_Spec.hs" `shouldBe` Nothing

    context "when any component of a hierarchical module name is not valid"$ do
      it "returns Nothing" $ do
        fileToSpec ("Valid" </> "invalid"  </>"MiddleNamesSpec.hs") `shouldBe` Nothing

    context "when path has directory component" $ do
      it "converts path to spec name" $ do
        fileToSpec ("Foo" </> "Bar" </> "BazSpec.hs") `shouldBe` Just (Run.Spec "Foo.Bar.Baz")

      it "rejects spec with empty name" $ do
        fileToSpec ("Foo" </> "Bar" </> "Spec.hs") `shouldBe` Nothing

  describe "findSpecs" $ do
    it "finds specs" $ do
      findSpecs ("test-data" </> "nested-spec" </> "Spec.hs") `shouldReturn` [Run.Spec "Foo.Bar.Baz", Run.Spec "Foo.Bar", Run.Spec "Foo"]

  describe "driverWithFormatter" $ do
    it "generates a test driver that uses a custom formatter" $ do
      driverWithFormatter "Some.Module.formatter" "" `shouldBe` unlines [
          "import qualified Some.Module"
        , "main :: IO ()"
        , "main = hspecWithFormatter Some.Module.formatter spec"
        ]

  describe "moduleNameFromId" $ do
    it "returns the module name of a fully qualified identifier" $ do
      moduleNameFromId "Some.Module.someId" `shouldBe` "Some.Module"

  describe "importList" $ do
    it "generates imports for a list of specs" $ do
      importList [Run.Spec "Foo", Run.Spec "Bar"] "" `shouldBe` unlines [
          "import qualified FooSpec"
        , "import qualified BarSpec"
        ]
