module Test.Hspec.UtilSpec (main, spec) where

import           Test.Hspec.Meta

import qualified Control.Exception as E
import           Test.Hspec.Util

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "quantify" $ do
    it "returns an amount and a word given an amount and word" $ do
      quantify 1 "thing" `shouldBe` "1 thing"

    it "returns a singular word given the number 1" $ do
      quantify 1 "thing" `shouldBe` "1 thing"

    it "returns a plural word given a number greater than 1" $ do
      quantify 2 "thing" `shouldBe` "2 things"

    it "returns a plural word given the number 0" $ do
      quantify 0 "thing" `shouldBe` "0 things"

  describe "safeEvaluate" $ do
    it "returns Right on success" $ do
      Right e <- safeEvaluate (return 23 :: IO Int)
      e `shouldBe` 23

    it "returns Left on exception" $ do
      Left e <- safeEvaluate (E.throwIO E.DivideByZero :: IO Int)
      show e `shouldBe` "divide by zero"

    it "re-throws AsyncException" $ do
      safeEvaluate (E.throwIO E.UserInterrupt :: IO Int) `shouldThrow` (== E.UserInterrupt)

  describe "filterPredicate" $ do
    it "tries to match a pattern against a list of descriptions and a requirement" $ do
      let p = filterPredicate "foo/bar/example 1"
      p ["foo", "bar"] "example 1" `shouldBe` True
      p ["foo", "bar"] "example 2" `shouldBe` False

    it "is ambiguous" $ do
      let p = filterPredicate "foo/bar/baz"
      p ["foo", "bar"] "baz" `shouldBe` True
      p ["foo"] "bar/baz" `shouldBe` True

    it "accepts partial matches" $ do
      let p = filterPredicate "bar/baz"
      p ["foo", "bar", "baz"] "example 1" `shouldBe` True
