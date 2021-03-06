-- Input Redirection

import Control.Monad
import Data.Char

main = forever $ do
    l <- getLine
    putStrLn $ map toUpper l
-- run ./9_capslocker < 9_haiku.txt to see the output

-- Getting Strings from Input Streams
-- The lazy version!

import Data.Char

main = do
    contents <- getContents
    putStr $ map toUpper contents
-- run ./9_capslocker_stream

import Data.Char

main = do
    contents <- getContents
    putStr (shortLinesOnly contents)

shortLinesOnly :: String -> String
shortLinesOnly = unlines . fliter (\line -> length line < 10) . lines
-- run ./9_capslocker_stream_short


-- Transforming Input

-- taking string input, transforming with a function and outputting
-- the result is so common they made a function called interact

main = interact shortLinesOnly

shortLinesOnly :: String -> String
shortLinesOnly = unlines . filter (\line -> length line < 10) . lines
-- run ./9_shortlinesonly_interact


-- create a function that takes input and tells the user if the line is
-- a palindrome

main = interact respondPalindromes

respondPalindromes :: String -> String
respondPalindromes =
    unlines .
    map (\xs -> if isPalindrome xs then "palindrome" else "not a palindrome") .
    lines

isPalindrome :: String -> Bool
isPalindrome xs = xs == reverse xs
-- run ./9_isPalindrome

-- READING AND WRITING FILES

-- reading/writing from/to stdin/stdout is just like reading/writing to files

import System.IO

main = do
    handle <- openFile "9_girlfriend.txt" ReadMode
    contents <- hGetContents handle
    putStr contents
    hClose handle
-- run ./9_girlfriend

-- or we could do the same thing but automatically handling opening
-- and closing the file if we use withFile

:t withFile
withFile :: FilePath -> IOMode -> (Handle -> IO r) -> IO r

import System.IO

main = do
    withFile "9_girlfriend.txt" ReadMode (\handle -> do
        contents <- hGetContents handle
        putStr contents)
-- run ./9_girlfriend_withFile

-- It's Bracket Time

:t bracket
bracket :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c

-- first param acquires a resource.
-- second param releases that resource (even if an exception raised).
-- third param does something with the resource

-- So can implement withFile using bracket easily
withFile :: FilePath -> IOMode -> (Handle -> IO r) -> IO r
withFile name mode f = bracket (openFile name mode)
    (\handle -> hClose handle)
    (\handle -> f handle)


-- Grab the Handles!

-- hGetContents, hGetLine, hPutStr, hPutStrLn, hGetChar, etc all work like
-- their -h counterparts except +h versions work with handles instead of
-- standard in/out

-- Working with strings and files is common, so we can use:
-- readFile, writeFile and appendFile

import System.IO

main = do
    contents <- readFile "9_girlfriend.txt"
    putStr contents
-- run ./9_girlfriend_readFile

import System.IO
import Data.Char

main = do
    contents <- readFile "9_girlfriend.txt"
    writeFile "9_girlfriendcaps.txt" (map toUpper contents)
-- run ./9_girlfriend_writeFile


-- To-Do Lists

-- putting appendFile to use

import System.IO

main = do
    todoItem <- getLine
    appendFile "9_todo.txt" (todoItem ++ "\n")
-- run ./9_appendTodo

-- Deleting Items

-- we can add items to the todo list, now let's delete

import System.IO
import System.Directory
import Data.List

main = do
    contents <- readFile "9_todo.txt"
    let todoTasks = lines contents
        numberedTasks = zipWith (\n line -> show n ++ " - " ++ line) [0..] todoTasks
    putStrLn "These are your TO-DO items:"
    mapM_ putStrLn numberedTasks
    putStrLn "Which one do you want to delete?"
    numberString <- getLine
    let number = read numberString
        newTodoItems = unlines $ delete (todoTasks !! number) todoTasks
    (tempName, tempHandle) <- openTempFile "." "temp"
    hPutStr tempHandle newTodoItems
    hClose tempHandle
    removeFile "9_todo.txt"
    renameFile tempName "9_todo.txt"
-- run ./9_deleteTodo


-- Cleaning up

-- if the program errors after the temp file is openend then the temp file
-- does not get removed.
-- Fix this by using bracketOnError from Control.Exception
-- bracketOnError only performs the cleanup if an exception is raised.
-- bracket always performs the cleanup

import System.IO
import System.Directory
import Data.List
import Control.Exception

main = do
    contents <- readFile "9_todo.txt"
    let todoTasks = lines contents
        numberedTasks = zipWith (\n line -> show n ++ " - " ++ line) [0..] todoTasks
    putStrLn "These are your TO-DO items:"
    mapM_ putStrLn numberedTasks
    putStrLn "Which one do you want to delete?"
    numberString <- getLine
    let number = read numberString
        newTodoItems = unlines $ delete (todoTasks !! number) todoTasks
    bracketOnError (openTempFile "." "temp")
        (\(tempName, tempHandle) -> do
            hClose tempHandle
            removeFile tempName)
        (\(tempName, tempHandle) -> do
            hPutStr tempHandle newTodoItems
            hClose tempHandle
            removeFile "9_todo.txt"
            renameFile tempName "9_todo.txt")
-- run ./9_deleteTodo_bracketOnError


-- Command-Line Arguments

:t getArgs
getArgs :: IO [String]
-- gets the arguments the program was run with an yields those as a list

:t getProgName
getProgName :: IO String
-- get the program name

import System.Environment
import Data.List

main = do
    args <- getArgs
    progName <- getProgName
    putStrLn "The arguments are:"
    mapM putStrLn args
    putStrLn "The program name is:"
    putStrLn progName


-- More Fun with To-Do Lists

-- implementing an entire todo that takes user input and dispatches
-- based on the values matched.

import System.Environment
import System.Directory
import System.IO
import Data.List
import Control.Exception

dispatch :: String -> [String] -> IO ()
dispatch "add" = add
dispatch "view" = view
dispatch "remove" = remove
dispatch "bump" = bump

main = do
    (command:argList) <- getArgs
    dispatch command argList

add :: [String] -> IO ()
add [fileName, todoItem] = appendFile fileName (todoItem ++ "\n")

view :: [String] -> IO ()
view [fileName] = do
    contents <- readFile fileName
    let todoTasks = lines contents
        numberedTasks = zipWith (\n line -> show n ++ " - " ++ line)
                                [0..] todoTasks
    putStr $ unlines numberedTasks

remove :: [String] -> IO ()
remove [fileName, numberString] = do
    contents <- readFile fileName
    let todoTasks = lines contents
        number = read numberString
        newTodoItems = unlines $ delete (todoTasks !! number) todoTasks
    bracketOnError (openTempFile "." "temp")
        (\(tempName, tempHandle) -> do
            hClose tempHandle
            removeFile tempName)
        (\(tempName, tempHandle) -> do
            hPutStr tempHandle newTodoItems
            hClose tempHandle
            removeFile fileName
            renameFile tempName fileName)
-- In the book removeFile "todo.txt" & renameFile... are still hardcoded!
-- Tut. Tut. Tut.

-- adding bump as part of the above, as an exercise left by the book
bump :: [String] -> IO ()
bump [fileName, numberString] = do
    contents <- readFile fileName
    let todoTasks = lines contents
        number = read numberString
        todo = todoTasks !! number
        newTodoItems = unlines $ [todo] ++ delete todo todoTasks
    bracketOnError (openTempFile "." "temp")
        (\(tempName, tempHandle) -> do
            hClose tempHandle
            removeFile tempName)
        (\(tempName, tempHandle) -> do
            hPutStr tempHandle newTodoItems
            hClose tempHandle
            removeFile fileName
            renameFile tempName fileName)
-- In 9_todo.hs I've pulled out the duplicated bracketOnError code
-- into its own function. Much cleaner!


-- Dealing with Bad Input
-- add a catchall pattern to dispatch function on bad commands

dispatch command = doesntExist command

doesntExist :: String -> [String] -> IO ()
doesntExist command _ =
    putStrLn $ "The " ++ command ++ " command doesn't exist"
-- similar error handling have been added to add, view, remove and bump
-- in 9_todo.hs


-- Randomness

import System.Random
:t random
random :: (RandomGen g, Random a) => g -> (a, g)
-- RandomGen type class is for types that can act as sources of randomness
-- Random type class is for types whose values can be random

-- to use random we need an instance of RandomGen type class, like:
-- StdGen (exported by System.Random)

-- manually make a random generator using mkStdGen
:t mkStdGen
mkStdGen :: Int -> StdGen

random (mkStdGen 100) :: (Int, StdGen) -- need to tell Haskell which type
gen = mkStdGen 100
random gen :: (Int, StdGen) -- produces same output given same input :)

x = read "10 1" :: StdGen
random x :: (Int, StdGen)
random x :: (Int, StdGen)
random x :: (Float, StdGen) -- different type annotation, same input
random x :: (Bool, StdGen)
random x :: (Integer, StdGen)


-- Tossing a coin

import System.Random

threeCoins :: StdGen -> (Bool, Bool, Bool)
threeCoins gen =
    let (firstCoin, newGen) = random gen        -- don't need the annotation
        (secondCoin, newGen') = random newGen   -- as the type is inferred
        (thirdCoin, newGen'') = random newGen'  -- from function declaration
    in  (firstCoin, secondCoin, thirdCoin)

threeCoins (mkStdGen 100)
threeCoins (mkStdGen 94)
threeCoins (mkStdGen 56)
threeCoins (mkStdGen 68)

-- More Random Functions
:t randoms
randoms :: RandgomGen g, Random a => g -> [a]
-- randoms produces a stream of random values based on the generator

take 5 $ randoms (mkStdGen 11) :: [Int]
take 5 $ randoms (mkStdGen 11) :: [Bool]
take 5 $ randoms (mkStdGen 11) :: [Float]

randoms' :: (RandgomGen g, Random a) => g -> [a]
randoms' gen =
    let (value, newGen) = random gen
    in  value:randoms' newGen
-- because we want a stream of values, we can't pass the final generator
-- back.

-- a finite version that returns the last generator
finiteRandoms :: (RandomGen g, Random a, Num n) => n -> g -> ([a],g)
finiteRandoms 0 gen = ([], gen)
finiteRandoms n gen =
    let (value, newGen) = random gen
        (restOfList, finalGen) = finiteRandoms (n-1) newGen
    in  (value:restOfList, finalGen)

-- *** This is my work ***
-- The book says that you can't get the last generator, but you can do the
-- next best thing: pair up the value with the generator that created it!
import System.Random
infiniteRandoms :: (RandomGen g, Random a) => g -> [(a, g)]
infiniteRandoms gen =
    let (value, newGen) = random gen
    in  (value, gen):infiniteRandoms newGen
-- Infinite random values and access to the generators that created them.
-- usage example: infiniteRandoms (mkStdGen 1234) :: [(Int, StdGen)]

:t randomR
randomR :: (RandomGen g, Random a) :: (a, a) -> g -> (a, g)

randomR (1,6) (mkStdGen 359353)
randomR (1,6) (mkStdGen 35935335)

-- produce an infinite stream of random numbers in a range using randomRs
:t randomRs
randomRs :: (RandomGen g, Random a) :: (a, a) -> g -> [a]

take 10 $ randomRs ('a','z') (mkStdGen 3) :: [Char]


-- Randomness and IO

import System.Random

main = do
    gen <- getStdGen
    putStrLn $ take 20 $ randomRs ('a','z') gen
-- run ./9_random_string_1

-- using getStdGen sets the global random generator
-- so calling getStdGen returns the same generator
import System.Random

main = do
    gen <- getStdGen
    putStrLn $ take 20 $ randomRs ('a','z') gen
    putStrLn "And now calling getStdGen again produces..."
    gen2 <- getStdGen
    putStrLn $ take 20 $ randomRs ('a','z') gen2
    putStrLn "The same random output... Look at 9_random_string_3.hs"
-- run ./9_random_string_2

-- to get a different generator use newStdGen
-- it splits the current generator into two. updating the global with one
-- and returning the other as the result
-- calling getStdGen would return something different after using newStdGen
import System.Random

main = do
    gen <- getStdGen
    putStrLn $ take 20 $ randomRs ('a','z') gen
    gen2 <- newStdGen
    putStrLn $ take 20 $ randomRs ('a','z') gen2
-- run ./9_random_string_3

-- guessing a number
import System.Random
import Control.Monad (when)

main = do
    gen <- getStdGen
    askForNumber gen

askForNumber :: StdGen -> IO ()
askForNumber gen = do
    let (randNumber, newGen) = randomR (1,10) gen :: (Int, StdGen)
    putStrLn "Which number in the range from 1 to 10 am I thinking of? "
    numberString <- getLine
    when (not $ null numberString) $ do
        let number = read numberString
        if randNumber == number
            then putStrLn "You are correct!"
            else putStrLn $ "Sorry, it was " ++ show randNumber
        askForNumber newGen
-- run ./9_guess_number
-- change read to reads in you don't want the program to blow up on bad
-- input.
:t reads
reads :: Read a => ReadS a

-- another way to do the same thing
import System.Random
import Control.Monad (when)

main = do
    gen <- getStdGen
    let (randNumber, _) = randomR (1,10) gen :: (Int, StdGen)
    putStrLn "Which number in the range from 1 to 10 am I thinking of? "
    numberString <- getLine
    when (not $ null numberString) $ do
        let number = read numberString
        if randNumber == number
            then putStrLn "You are correct!"
            else putStrLn $ "Sorry, it was " ++ show randNumber
        newStdGen
        main
-- run ./9_guess_number_2
-- other one better as it does less in main and supplies a reusable function


-- Bytestrings

-- Lazy Bytestrings are stored in chunks of 64KB.
-- if you eval a lazy bytestring, the first 64K will be evaluated, and a
-- promise to compute the rest (a thunk).

-- Bytestrings are strict are stored in an array. You evaluate the whole
-- thing. You can't have infinite bytestrings.

-- documentation for Data.ByteString.Lazy will show lots of functions with
-- the same names as Data.List (but with type signature different).

-- We'll do qualified importts of bytestrings

import qualified Data.ByteString.Lazy as B      -- Lazy
import qualified Data.ByteString as S           -- Strict

:t B.pack
B.pack :: [GHC.Word.Word8] -> B.ByteString

:t S.pack
S.pack :: [GHC.Word.Word8] -> S.ByteString

-- Word8 represents an unsigned 8 bit integer ie 0 to 255
-- Word8 is also an instance of Num type class

B.pack [99,97,110]
B.pack [98..120]

:t B.unpack
B.unpack :: B.ByteString -> [GHC.Word.Word8]

by = B.pack [98,111,114,116]
B.unpack by

-- fromChunks a list of strict bytestrings and returns a lazy bytestring
:t B.fromChunks
B.fromChunks :: [S.ByteString] -> B.ByteString

-- toChunks does the reverse
:t B.toChunks
B.toChunks :: B.ByteString -> [S.ByteString]

B.fromChunks [S.pack [40,41,42], S.pack [43,44,45], S.pack [46,47,48]]
-- Chunk "()*" (Chunk "+,-" (Chunk "./0" Empty))
-- this is good if you have lots of small strict bytestrings and you want
-- to process them efficiently without joining them into one big strict
-- bytestring in memory first

-- bytestring version of : is called cons
:t B.cons
B.cons :: GHC.Word.Wordu -> B.ByteString -> B.ByteString

B.cons 85 $ B.pack [80,81,82,84]
-- Chunk "U" (Chunk "PQRT" Empty)

-- ByteString package info can be found at:
-- http://hackage.haskell.org/pacakage/bytestring/

:t B.readFile
B.readFile :: FilePath -> IO B.ByteString


-- Copying Files with Bytestrings

-- a program that takes two filenames as command-line arguments
-- copies the first file into the second.
-- System.Directory already has copyFile, but here's another implementation

import System.Environment
import System.Directory
import System.IO
import Control.Exception
import qualified Data.ByteString.Lazy as B

main = do
    (fileName1:fileName2:_) <- getArgs
    copy fileName1 fileName2

copy source dest = do
    contents <- B.readFile source
    bracketOnError
        (openTempFile "." "temp")
        (\(tempName, tempHandle) -> do
            hClose tempHandle
            removeFile tempName)
        (\(tempName, tempHandle) -> do
            B.hPutStr tempHandle contents
            hClose tempHandle
            renameFile tempName dest)
-- run ./9_bytestringcopy 9_bytestringsource.txt 9_bytestringdestination.txt


-- Whenever you need better performance in a program that reads a lot
-- of data into strings, give bytestrings a try. You might get a good
-- performance boost.

-- Write with ordinary strings first, convert to bytestrings if need be.
