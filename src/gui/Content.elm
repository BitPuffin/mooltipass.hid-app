module Content where

-- Elm standard library
import Color
import Graphics.Collage (..)
import Graphics.Element (..)
import Maybe

-- local source
import CustomGraphics (..)
import Layout (..)
import GuiState (..)
import LogTab (..)
import DeveloperTab (..)
import ManageTab (..)
import CommonState (..)

{-| Renders the window the window dimensions and application state to the
    element that is below the tab navigation. -}
content : (Int, Int) -> GuiState -> Element
content (w,h) state =
    let h' = h - heights.marginTop - heights.nav
        background =
            collage w h' [filled darkGrey <| rect (toFloat w) (toFloat h)]
        withBackground e = layers [background, e]
    in case state.activeTab of
        Log       -> withBackground <| logTab (w, h') state.common.log
        Developer -> withBackground <| developerTab (w, h') state.common.importInfo
        Manage    -> withBackground <| manageTab (w, h') (Maybe.withDefault emptyMemoryInfo state.unsavedMemInfo)
        _         -> empty
