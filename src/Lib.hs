{-# LANGUAGE TupleSections #-}

module Lib
  ( module System.IO
  , module Data.List.Split
  , module Data.List
  , module Text.RawString.QQ
  , module Text.Printf
  , module M -- Data.Map
  , module MS -- Data.Map.Strict
  , Tag(..)
  , readLines
  , readWords
  , input
  , inputfile
  , cols
  , slide
  , zips
  , zip3s
  , zip3Withs
  , order
  , groupBy'
  , groupM'
  , group'
  , tag
  , tagM
  , tag'
  , tagM'
  , tagMg'
  , tagT
  , tagT'
  , tagN
  , tagN'
  , tagNs
  , tagNs'
  , unTag
  , unTag'
  , unTagL
  , unTagL'
  , chunkTag
  , chunkTagM
  , concatChkTM
  , mergeBy
  , mergeBy'
  , merge
  , mergeDefault
  , mergeDefault'
  , mergeDefaultWith
  , mergeDefaultWith'
  , mergeFull
  , mergeFullM
  , mergeRight
  , mergeRightM
  , mergeLeft
  , mergeLeftM
  , tup
  , tup3
  , tup4
  , tup5
  , tup'
  , tupM'
  , tupN'
  , tupNs
  , trd
  , frh
  , ffh
  , sxh
  , svh
  , eth
  , nth
  ) where

import           Data.List
import           Data.List.Split
import qualified Data.Map          as M
import qualified Data.Map.Strict   as MS
import           Data.Maybe
import           System.Directory
import           System.IO
import           Text.Printf
import           Text.RawString.QQ

readLines :: String -> IO [String]
readLines name = lines <$> readFile name

readWords :: String -> IO [[String]]
readWords name = map words <$> readLines name

cols :: [String] -> [[String]]
cols = map words

zips = uncurry zip . slide

zip3s = uncurry3 zip3 . slide3

zip3Withs f = uncurry3 (zipWith3 f) . slide3

slide l@(_:xs) = (l, xs)

slide3 l@(_:xs) = (l, fy, sy)
  where
    (fy, sy) = slide xs

uncurry3 f (x, y, z) = f x y z

-- convert instance of Ord to Ordering, helper of sort
order :: Ord a => a -> a -> Ordering
order x y
  | x > y = GT
  | x == y = EQ
  | otherwise = LT

-- tuple helpers
fst3 (x, _, _) = x

snd3 (_, x, _) = x

trd (_, _, x) = x

frh (_, _, _, x) = x

ffh (_, _, _, _, x) = x

sxh (_, _, _, _, _, x) = x

svh (_, _, _, _, _, _, x) = x

eth (_, _, _, _, _, _, _, x) = x

nth (_, _, _, _, _, _, _, _, x) = x

-- auto sort group by
groupBy' :: Ord a => (a -> a -> Bool) -> [a] -> [[a]]
groupBy' eq = groupBy eq . sortBy order

-- auto sort group with map
groupM' f = groupBy (\x y -> f x == f y) . sortBy order

-- auto sort group
group' :: Ord a => [a] -> [[a]]
group' = group . sortBy order

-- convert from list to tuple for helper of tagged tuple
tup :: [a] -> (a, a)
tup [x, y]  = (x, y)
tup (x:y:_) = (x, y)

tup3 :: [a] -> (a, a, a)
tup3 (x:xs) = (x, fst tx, snd tx)
  where
    tx = tup xs

tup4 :: [a] -> (a, a, a, a)
tup4 (x1:x2:xs) = (x1, x2, fst tx, snd tx)
  where
    tx = tup xs

tup5 :: [a] -> (a, a, a, a, a)
tup5 (x1:x2:x3:xs) = (x1, x2, x3, fst tx, snd tx)
  where
    tx = tup xs

tup' :: [a] -> (a, [a])
tup' [x]   = (x, [])
tup' (x:y) = (x, y)

tupN' :: Int -> [a] -> ([a], [a])
tupN' n xs = (take n xs, drop n xs)

tupNs :: [Int] -> [a] -> ([a], [a])
tupNs ns xs = (keys ns xs, vals ns xs)
  where
    keys ns xs = map (xs !!) ns
    vals ns xs =
      catMaybes $
      foldl (\z x -> take x z ++ [Nothing] ++ drop (x + 1) z) (Just <$> xs) ns

tupM' :: [[a]] -> [(a, [a])]
tupM' = map tup'

tupNM' :: Int -> [[a]] -> [([a], [a])]
tupNM' n = map (tupN' n)

-- list of Tuple [(a, b1),(a, b2)] to container list of tagged tuple (tag, [])
data Tag a b
  = Tag (a, [b])
  | TagS (String, [b])
  | TagList [Tag a b]
  deriving (Show)

tag :: [(a, b)] -> (a, [b])
tag [(x, y)] = (x, [y])
tag (x:xs) = (fst tx, snd tx ++ (snd . tag $ xs))
  where
    tx = tag [x]

tagM :: [[(a, b)]] -> [(a, [b])]
tagM = map tag

tag' :: [[a]] -> (a, [a])
tag' = tag . map tup

tagM' :: [[[a]]] -> [(a, [a])]
tagM' = map tag'

tagMg :: (Ord a, Ord b) => [(a, [b])] -> [(a, [[b]])]
tagMg = tagM . groupM' fst

tagMg' :: (Ord a, Ord b) => (c -> (a, b)) -> [c] -> [(a, [b])]
tagMg' f = tagM . groupM' fst . map f

-- tag from line
tagT :: [String] -> [(String, [[String]])]
tagT = tagN 0

-- tag from table
tagT' :: Ord a => [[a]] -> [(a, [[a]])]
tagT' = tagMg' tup'

-- tag N col from line
tagN :: Int -> [String] -> [(String, [[String]])]
tagN n = tagN' n . map words

-- tag N col from table
tagN' :: Ord a => Int -> [[a]] -> [(a, [[a]])]
tagN' n = tagT' . map toHead
  where
    toHead xs = [xs !! n] ++ take n xs ++ drop (n + 1) xs

-- tag Ns cols from line
tagNs :: [Int] -> [String] -> [([String], [[String]])]
tagNs ns = tagNs' ns . map words

-- tag Ns cols from table
tagNs' :: Ord a => [Int] -> [[a]] -> [([a], [[a]])]
tagNs' = tagMg' . tupNs

-- line from tag
unTagL :: [(String, [[String]])] -> [[String]]
unTagL = map unTag

-- table from tag
unTagL' :: [(a, [[a]])] -> [[[a]]]
unTagL' = map unTag'

-- line from tag 1
unTag :: (String, [[String]]) -> [String]
unTag = map (intercalate "\t") . unTag'

-- table from tag 1
unTag' :: (a, [[a]]) -> [[a]]
unTag' (x, y) = map ((:) x) y

chunkTag :: Int -> [(a, b)] -> [(a, [b])]
chunkTag 0 [(x, _)] = [(x, [])]
chunkTag _ [(x, y)] = [(x, [y])]
chunkTag i xs = map (fst t, ) . chunksOf i $ snd t
  where
    t = tag xs

chunkTagM :: Int -> [[(a, b)]] -> [[(a, [b])]]
chunkTagM = map . chunkTag

concatChkTM :: Int -> [[(a, b)]] -> [(a, [b])]
concatChkTM i = concat . chunkTagM i

-- set operation, likely Data.Map and Data.Map.Strict without maybe.
mergeBy ::
     ((a, [c]) -> (b, [c]) -> Bool) -> [(a, [c])] -> [(b, [c])] -> [(a, [c])]
mergeBy f xs ys = [(fst x, snd x ++ snd y) | x <- xs, y <- ys, f x y]

-- sort by key for mergeBy
mergeBy' ::
     Eq a1 => ((a2, [c]) -> a1) -> [(a2, [c])] -> [(a2, [c])] -> [(a2, [c])]
mergeBy' op = mergeBy (\x y -> op x == op y)

merge :: Eq a => [(a, [c])] -> [(a, [c])] -> [(a, [c])]
merge = mergeBy' fst

-- fill default value if key not found in ys.
mergeDefault :: Ord a => [c] -> [(a, [c])] -> [(a, [c])] -> [(a, [c])]
mergeDefault z = mergeDefaultWith (const z)

-- sort by key for mergeDefault
mergeDefault' :: Ord a => [c] -> [(a, [c])] -> [(a, [c])] -> [(a, [c])]
mergeDefault' z xs ys = sortOn fst $ mergeDefault z xs ys

-- fill default with func if key not found in ys.
mergeDefaultWith ::
     Eq a => ((a, [c]) -> [c]) -> [(a, [c])] -> [(a, [c])] -> [(a, [c])]
mergeDefaultWith f xs ys = unionBy (\x y -> fst x == fst y) merged mergeDs
  where
    merged = merge xs ys
    ds = map (\(k, x) -> (k, f (k, x))) xs
    mergeDs = merge xs ds

-- sort by key for mergeDefaultWith
mergeDefaultWith' ::
     Ord a => ((a, [c]) -> [c]) -> [(a, [c])] -> [(a, [c])] -> [(a, [c])]
mergeDefaultWith' f xs ys = sortOn fst $ mergeDefaultWith f xs ys

-- sql full join like.
mergeFull :: (Ord a, Ord c) => [(a, c)] -> [(a, c)] -> [(a, Maybe c, Maybe c)]
mergeFull xs ys =
  concatMap
    (\xs ->
       if length xs > 1
         then filter (\(_, x, y) -> isJust x && isJust y) xs
         else xs) $
  groupM' fst3 $
  nub
    [ if z == fst x && z == fst y
      then (z, Just $ snd x, Just $ snd y)
      else if z == fst x
             then (z, Just $ snd x, Nothing)
             else (z, Nothing, Just $ snd y)
    | z <- zs
    , x <- xs
    , y <- ys
    , eqKey z x || eqKey z y
    ]
  where
    keys xs ys = nub . sort $ map fst xs ++ map fst ys
    zs = keys xs ys
    eqKey z x = z == fst x

-- sql left outer join like
mergeLeft :: (Ord a, Ord c) => [(a, c)] -> [(a, c)] -> [(a, Maybe c, Maybe c)]
mergeLeft xs ys = filter (\(_, x, _) -> isJust x) $ mergeFull xs ys

-- sql right outer join like
mergeRight :: (Ord a, Ord c) => [(a, c)] -> [(a, c)] -> [(a, Maybe c, Maybe c)]
mergeRight = flip mergeLeft

-- sql join like and map f to result
mergeFullM ::
     (Ord a, Ord c)
  => ((a, Maybe c, Maybe c) -> b)
  -> [(a, c)]
  -> [(a, c)]
  -> [b]
mergeFullM f = mergeInnerM f mergeFull

mergeLeftM ::
     (Ord a, Ord c)
  => ((a, Maybe c, Maybe c) -> b)
  -> [(a, c)]
  -> [(a, c)]
  -> [b]
mergeLeftM f = mergeInnerM f mergeLeft

mergeRightM ::
     (Ord a, Ord c)
  => ((a, Maybe c, Maybe c) -> b)
  -> [(a, c)]
  -> [(a, c)]
  -> [b]
mergeRightM f = mergeInnerM f mergeRight

mergeInnerM ::
     (Ord a, Ord c)
  => ((a, Maybe c, Maybe c) -> b)
  -> ([(a, c)] -> [(a, c)] -> [(a, Maybe c, Maybe c)])
  -> [(a, c)]
  -> [(a, c)]
  -> [b]
mergeInnerM f m xs ys = map f $ m xs ys

inputfile = "input"

input =
  doesFileExist inputfile >>= \c ->
    if c
      then readLines inputfile
      else return []
