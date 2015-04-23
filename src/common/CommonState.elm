module CommonState where

-- Elm standard library
import List (..)
import String

-- local source
import Byte (..)
import KeyboardLayout(..)

import Debug (log)

{-| The background state excluding gui components -}
type alias CommonState =
    { deviceStatus : DeviceStatus
    , log          : List String
    , importInfo   : ImportInfo
    , memoryInfo   : MemInfo
    -- , setKeyboard  : Int
    , setParameter : Maybe (Parameter, Byte)
    , getKeyboard  : Maybe ()
    , settingsInfo : SettingsInfo
    , forceUpdate  : Bool
    }

default : CommonState
default =
    { deviceStatus = NotConnected
    , log          = []
    , importInfo   = NoImport
    , memoryInfo   = NoMemInfo
    -- , setKeyboard  = 0
    , setParameter = Nothing
    , getKeyboard  = Nothing
    , settingsInfo = defaultSettingsInfo
    , forceUpdate  = True
    }

type alias Favorite = Maybe (FlashAddress, FlashAddress)

maxFavs = 14

emptyFavorites : List Favorite
emptyFavorites = repeat maxFavs Nothing

{-| Set-able parameters. Only some of these will be exposed to the user -}
type Parameter = UserInitKey
               | KeyboardLayout
               | UserInterTimeout
               | LockTimeoutEnable
               | LockTimeout
               | TouchDi
               | TouchWheelOs
               | TouchProxOs
               | OfflineMode

encodeParameter : Parameter -> Int
encodeParameter p = case p of
    UserInitKey        -> 0x00
    KeyboardLayout     -> 0x01
    UserInterTimeout   -> 0x02
    LockTimeoutEnable  -> 0x03
    LockTimeout        -> 0x04
    TouchDi            -> 0x05
    TouchWheelOs       -> 0x06
    TouchProxOs        -> 0x07
    OfflineMode        -> 0x08
    _                  -> 0xFF

decodeParameter : Int -> Parameter
decodeParameter i = case i of
    0x00 -> UserInitKey       
    0x01 -> KeyboardLayout
    0x02 -> UserInterTimeout
    0x03 -> LockTimeoutEnable
    0x04 -> LockTimeout
    0x05 -> TouchDi
    0x06 -> TouchWheelOs
    0x07 -> TouchProxOs
    _    -> OfflineMode


type MemInfo =
      MemInfo MemInfoData
    | MemInfoRequest
    | MemInfoSave MemInfoData
    | MemInfoWaitingForUser
    | MemInfoWaitingForDevice
    | MemInfoUnknownCardInserted
    | MemInfoUnknownCardWaitingForCpz
    | MemInfoUnknownCardCpz   ByteArray
    | MemInfoUnknownCardAdd   Card
    | MemInfoUnknownCardError ByteArray
    | NoMemInfo

type alias SettingsInfo =
    { keyboard  : Int
    , timeout   : Int
    }

defaultSettingsInfo : SettingsInfo
defaultSettingsInfo = SettingsInfo defaultKeyboard 3

updateSettingsInfo : Parameter -> Byte -> SettingsInfo -> SettingsInfo
updateSettingsInfo p b s = case p of
  KeyboardLayout   -> { s | keyboard <- b }
  UserInterTimeout -> { s | timeout <- b }
  _                -> s

type alias ServiceName =
    { address    : FlashAddress
    , flags      : (Byte,Byte)
    , service    : ByteString
    }

type alias Login =
    { address      : FlashAddress
    , flags        : (Byte,Byte)
    , ctr          : (Byte, Byte, Byte)
    , description  : ByteString
    , login        : ByteString
    , password     : ByteArray
    , dateCreated  : (Byte, Byte)
    , dateLastUsed : (Byte, Byte)
    }

type alias Service = (ServiceName, List Login)

type alias MemInfoData =
    { credentials : List Service
    , favorites   : List Favorite
    , addresses   : List FlashAddress
    , ctr         : (Byte,Byte,Byte)
    , cards       : List Card
    , curCardCpz  : ByteArray
    }

type alias Card = { cpz : ByteArray
                  , ctrNonce : ByteArray
                  }

type DeviceStatus = NotConnected | Unlocked | NoCard | Locked | ManageMode | UnknownCard

type ImportInfo =
      ImportRequested FileId
    | Importing FileId Int Int
    | Imported FileId
    | ImportError String
    | NoImport

type alias FileId = String

fileName : FileId -> String
fileName id = case String.split ":" id of
    [_,name] -> name
    _ -> ""

connectToLog : DeviceStatus -> String
connectToLog c = case c of
    NotConnected -> "device disconnected"
    Unlocked     -> "device status: unlocked"
    NoCard       -> "device status: no card present"
    Locked       -> "device status: locked"
    ManageMode   -> "device status: memory management mode"
    UnknownCard  -> "device status: unknown card present"

{-| All actions that can be performed to change the common state -}
type CommonAction = SetLog (List String)
                  | SetDeviceStatus DeviceStatus
                  | AppendToLog String
                  | GetState
                  | SetImportInfo ImportInfo
                  | StartImportMedia FileId
                  | SetMemInfo MemInfo
                  | StartMemManage
                  | SaveMemManage MemInfoData
                  | EndMemManage
                  -- | SendDeviceMessage DeviceMessage
                  -- | SetKeyboard Int
                  | SetParameter (Maybe (Parameter, Byte))
                  | GetKeyboard (Maybe ())
                  | ReceiveKeyboard Int
                  | CommonSettings SettingsInfo
                  | CommonNoOp

{-| Transform the state to a new state according to an action -}
update : CommonAction -> CommonState -> CommonState
update action s =
    case action of
        SetLog l            -> {s | log <- l}
        AppendToLog str     -> if length s.log < 5000
                               then {s | log <- str::s.log}
                               else {s | log <- take 5000 (str::s.log)}
        SetDeviceStatus c   -> {s | deviceStatus <- c}
        SetImportInfo i     -> {s | importInfo <- i}
        StartImportMedia id -> {s | importInfo <- ImportRequested id}
        SetMemInfo i        -> {s | memoryInfo <- i}
        StartMemManage      -> {s | memoryInfo <- MemInfoRequest}
        SaveMemManage d     -> {s | memoryInfo <- MemInfoSave d}
        EndMemManage        -> {s | memoryInfo <- NoMemInfo}
        -- SetKeyboard kb      -> log ("common.CommonState.update: Set kb to " ++ toString kb) <| {s | setKeyboard <- kb}
        SetParameter mpb    -> log ("common.CommonState.update: Set param?") <|
                               {s | setParameter <- mpb}
        GetKeyboard i       -> log ("common.CommonState.update: Get kb") <| {s | getKeyboard <- i}
        ReceiveKeyboard kb  -> log ("common.CommonState update: Rcv kb " ++ toString kb) <| {s | settingsInfo <- updateSettings action s.settingsInfo}
        CommonSettings settings   -> log ("common.CommonState update: Settings") <| {s | settingsInfo <- settings}
        -- GetState just twiddles the forceUpdate bit to make the state seem
        -- changed. This is so we can dropRepeats on the state signal but force
        -- an update through if we need to (like when the GUI is newly opened
        -- and definetely needs the state).
        GetState            -> {s | forceUpdate <- not s.forceUpdate}
        CommonNoOp          -> s

updateSettings : CommonAction -> SettingsInfo -> SettingsInfo
updateSettings action s =
    case action of
        ReceiveKeyboard i -> { s | keyboard <- i}
        _                 -> s

apply : List CommonAction -> CommonState -> CommonState
apply actions state = foldr update state actions
