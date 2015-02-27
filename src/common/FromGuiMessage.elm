module FromGuiMessage where

-- Elm standard library
import Maybe

-- local source
import CommonState (..)

type alias FromGuiMessage =
    { setLog           : Maybe (List String)
    , getState         : Maybe ()
    , startImportMedia : Maybe FileId
    , startMemManage   : Maybe ()
    , endMemManage     : Maybe ()
    , saveMemManage    : Maybe MemInfoData
    }

emptyFromGuiMessage =
    { setLog           = Nothing
    , getState         = Nothing
    , startImportMedia = Nothing
    , startMemManage   = Nothing
    , endMemManage     = Nothing
    , saveMemManage    = Nothing
    }

encode : CommonAction -> FromGuiMessage
encode action =
    let e = emptyFromGuiMessage
    in case action of
        SetLog l           -> {e | setLog <- Just l}
        StartImportMedia p -> {e | startImportMedia <- Just p}
        StartMemManage     -> {e | startMemManage <- Just ()}
        EndMemManage       -> {e | endMemManage <- Just ()}
        SaveMemManage d    -> {e | saveMemManage <- Just d}
        _                  -> e

decode :  FromGuiMessage -> CommonAction
decode msg =
    let decode' =
        Maybe.oneOf
            [ Maybe.map SetLog msg.setLog
            , Maybe.map StartImportMedia msg.startImportMedia
            , Maybe.map (\_ -> GetState) msg.getState
            , Maybe.map (\_ -> StartMemManage) msg.startMemManage
            , Maybe.map (\_ -> EndMemManage) msg.endMemManage
            , Maybe.map SaveMemManage msg.saveMemManage
            ]
    in Maybe.withDefault CommonNoOp decode'
