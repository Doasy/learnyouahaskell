-- MONOIDS


-- This type class if for types whose values can be combineg together with
-- a binary operation.


-- Wrapping an Existing Type into a New Type

-- In chapter 11, we saw a couple of ways for the list type to be an
-- applicative functor. One way is using <*>:
[(+1),(*100),(*5)] <*> [1,2,3]
-- [2,3,4,100,200,400,5,10,15]

-- The second way was using ZipLists:
getZipList $ ZipList [(+1),(*100),(*5)] <*> ZipList [1,2,3]
-- [2,200,15]

-- Because [] was already an instance of Applicative, we could declare
-- ZipList as:
data ZipList a = ZipList [a]
-- it only has one constructor and it has just one field. Using record
-- syntax:
data ZipList a = ZipList { getZipList :: [a] }

-- In the libraries ZipList is defined like:
newtype ZipList a = ZipList { getZipList :: [a] }

-- Why newtype?
--
-- It was made exactly for the cases when you want to wrap a type to
-- present it as a different type.
--
-- newtype is faster... There is some overhead using data to wrap/unwrap
-- values when the program is running. Using newtype, Haskell knows you're
-- just wrapping an existing type (same internally, but different type). It
-- then can get rid of all the wrapping/unwrapping
--
-- newtype can only have one value constructor and that constructor can
-- only have one field.
--
-- newtype declarations can also derive from other type classes. But the
-- type you're wrapping must already be an instance of that class!

newtype CharList = CharList { getCharList :: [Char] } deriving (Eq, Show)

CharList "this will be shown!"
-- CharList {getCharList = "this will be shown!"}
CharList "benny" == CharList "benny"
-- True
CharList "benny" == CharList "oysters"
-- False

-- In this particular newtype, the value constructor has the following type
CharList :: [Char] -> CharList
-- getCharList has type
getCharList :: CharList -> [Char]
-- this could be thought of as wrapping/unwrapping or as converting values
-- between types


-- Using newtype to Make Type Class Instances
--
-- We sometimes want to make our type instances of certain classes, but the
-- type parameters don't match.
--
-- What if we want to make the tuple an instance of Functor such that when
-- we fmap a function over a tuple, it is applied to the first component
-- of the tuple? eg fmap (+3) (1,1) => (4,1)
newtype Pair b a = Pair { getPair :: (a,b) }

instance Functor (Pair c) where
    fmap f (Pair (x, y)) = Pair (f x, y)

:t fmap
-- fmap :: (a -> b) -> Pair c a -> Pair c b
getPair $ fmap (*100) (Pair (2,3))
-- (200,3)
getPair $ fmap reverse (Pair ("london calling",3))
-- ("gnillac nodnol",3)


-- On newtype laziness
--
-- values that are created using newtype are lazier than those that are
-- created otherwise. We can see this when using undefined.

-- trying to evaluate undefined, haskell throws an exception
undefined
-- *** Exception: Prelude.undefined

-- if we have a list with some values undefined and ask for the head
-- everything is fine as it only needs to evaluate the first element:
head [3,4,5,undefined,2,undefined]
-- 3

-- consider the following:
data CoolBool = CoolBool { getCoolBool :: Bool }
helloMe :: CoolBool -> String
helloMe (CoolBool _) = "hello"
-- helloMe returns "hello" regardless of the input being True or False

-- Instead of giving helloMe a Bool:
helloMe undefined
-- *** Exception: Prelude.undefined
-- Even though we said that it didn't matter what the parameter was in the
-- helloMe definition...
--
-- Types defined with data can have multiple value constructors (even
-- though ours has only one). So Haskell is forced to evaluate the
-- parameters just enough in order to see which constructor was used to
-- create the value

newtype CoolBool = CoolBool { getCoolBool :: Bool }
helloMe :: CoolBool -> String
helloMe (CoolBool _) = "hello"

helloMe undefined
-- "hello"
-- This worked because Haskell knows that types made with newtype can have
-- only one constructor, it doesn't need to evaluate the value passed to
-- the function to make sure it conforms to the (CoolBool _) pattern.

-- data and newtype behave similarly from the outside, but they are really
-- two different mechanisms. Data can be used to make completely new types,
-- newtype is just for making a new type out of an existing type. Pattern
-- matching on newtype values isn't like taking something out of a box (as
-- it is with data), but more like direct type conversion.


-- Type vs newtype vs data

-- type is for making type synonyms.
type IntList = [Int]
([1,2,3] :: IntList) ++ ([1,2,3] :: [Int])
-- [1,2,3,1,2,3]
-- we use type synonyms to make our type signatures more descriptive
-- eg from Chapter 7
type PhoneBook = [(String,String)]

-- newtype is for taking existing types and wrapping them in new types
-- mostly so that it's easier to make them instances of certain type
-- classes. the newtype is separate from the original type. Given:
newtype CharList = CharList { getCharList :: [Char] }
-- we can not use ++ to put together CharList and [Char]
--
-- Using record syntax in newtype declarations we get functions for
-- converting between the types: The value constructor and the extractor
-- function.

-- data is for making our own data types: Many constructors each with many
-- fields.

-- summary:
-- type: you want to just make type synonyms to look cleaner and be more
--       descriptive.
-- newtype: you want to take an existing type and wrap it in order to make
--          it an instance of a type class
-- data: you want to make something completely new.


-- About Those Monoids
--
-- A monoid is made up of an associative binary function and a value that
-- acts as an identity with respect to that function. E.g. 1 with * and [] with ++.
class Monoid m where
    mempty  :: m
    mappend :: m -> m -> m
    mconcat :: [m] -> m
    mconcat  = foldr mappend mempty

-- first: only concrete types can be made instance of Monoid. This is
-- different to Applicative and Functor.
--
-- mempty (a polymorphic constant) represents the identity value for a
-- particular monoid.
--
-- mappend is the binary function. It takes two monoid values and returns
-- a third of the same type.
--
-- mconcat takes a list of monoid values and reduces it to one value using
-- mappend. The default implementation of mconcat is fine for most cases,
-- so we generally don't worry about it.


-- The Monoid Laws
         mempty `mappend` x = x
         x `mappend` mempty = x
(x `mappend` y) `mappend` z = x `mappend` (y `mappend` z)
-- the first two state that mempty acts like the identity wrt mappend
-- the third states that mappend is associative.


-- Meet Some Monoids

-- List Are Monoids
instance Monoid [a] where
    mempty  = []
    mappend = (++)
-- remember we require a concrete type, hence [a] instead of []
[1,2,3] `mappend` [4,5,6]
-- [1,2,3,4,5,6]
("one" `mappend` "two") `mappend` "three"
-- "onetwothree"
"one" `mappend` ("two" `mappend` "three")
-- "onetwothree"
"one" `mappend` "two" `mappend` "three"
-- "onetwothree"
"pang" `mappend` mempty
-- "pang"
mconcat [[1,2],[3,6],[9]]
-- [1,2,3,6,9]
mempty :: [a]
-- []

-- Product and Sum
-- we've already noted that * and 1 together can be used as a monoid
0 + 4
-- 4
5 + 0
-- 5
(1 + 3) + 5
1 + (3 + 5)

-- we have two equally valid ways that numbers can be monads, so
-- Data.Monoid uses newtype!
newtype Product a = Product { getProduct :: a }
    deriving (Eq, Ord, Read, Show, Bounded)

instance Num a => Monoid (Product a) where
    mempty = Product 1
    Product x `mappend` Product y = Product (x * y)
-- sum is defined similarly

getProduct $ Product 3 `mappend` Product 9
-- 27
getProduct $ Product 3 `mappend` mempty
-- 3
getProduct $ Product 3 `mappend` Product 4 `mappend` Product 2
-- 24
getProduct . mconcat . map Product $ [3,4,2]
-- 24
getSum $ Sum 2 `mappend` Sum 9
-- 11
getSum $ mempty `mappend` Sum 3
-- 3
getSum . mconcat . map Sum $ [1,2,3]
-- 6