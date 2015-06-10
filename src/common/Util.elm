module Util where

import List exposing (..)

pairToList : (a,a) -> List a
pairToList (x,y) = [x,y]

isJust : Maybe a -> Bool
isJust x = case x of
    (Just _) -> True
    Nothing  -> False

fromJust : Maybe a -> a
fromJust (Just a) = a

last : List a -> Maybe a
last xs = case xs of
    (x::[]) -> Just x
    (x::xs) -> last xs
    _       -> Nothing

maybeHead : List a -> Maybe a
maybeHead xs = case xs of
    (x::_) -> Just x
    _      -> Nothing

unsafeHead : List a -> a
unsafeHead xs = case xs of
    (x::_) -> x

unsafeTail : List a -> List a
unsafeTail xs = case xs of
    (x::xs') -> xs'
    []      -> []

justs : List (Maybe a) -> List a
justs = filterMap identity

mapOnce : (a -> Maybe a) -> List a -> List a
mapOnce f (x::xs) = case f x of
        Nothing -> x :: if xs /= [] then mapOnce f xs else []
        Just y  -> y :: xs

replaceFirst : a -> a -> List a -> List a
replaceFirst old new items =
    let check item = if item == old then Just new else Nothing
    in mapOnce check items

stripNothing : List (Maybe a) -> List (Maybe a)
stripNothing =
    foldr (\x z -> if z == [] && x == Nothing then z else x::z) []

truncateNull : List Int -> List Int
truncateNull = reverse << fst << foldl
    (\x (z,continue) ->
        if continue && not (x == 0) then (x::z,True) else (z,False))
    ([],True)

isOk : Result a b -> Bool
isOk r = case r of
    Ok _ -> True
    _    -> False
