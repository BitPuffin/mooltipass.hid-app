import Color
import Graphics.Collage(..)
import Graphics.Element(..)
import Graphics.Input(..)
import List
import Mouse
import Signal(..)
import Text
import Window
import CustomGraphics (roundedRect)

main : Signal Element
main = scene <~ Window.dimensions
             ~ (foldp update defaultState (subscribe actions))

-- State
type Tab = Log | Settings | Manage | Developer
type ConnectState = NotConnected | Connected | NoCard | NoPin

{-| The entire application state -}
type alias State =
    { connect     : ConnectState
    , activeTab   : Tab
    , iconClicked : Int
    , devEnabled  : Bool
    , log         : String
    }

defaultState : State
defaultState =
    { connect     = Connected
    , activeTab   = Log
    , iconClicked = 0
    , devEnabled  = True
    , log         = "connecting ..."
    }

{-| All actions that can be performed to change state -}
type Action = ChangeTab Tab
            | ClearLog
            | ClickIcon
            | NoOp
            | SetConnected ConnectState

{-| Transform the state to a new state according to an action -}
update : Action -> State -> State
update action s =
    case action of
        (ChangeTab t)    -> {s | activeTab   <- t}
        (SetConnected c) -> {s | connect     <- c}
        ClearLog         -> {s | log         <- ""}
        -- clicking the icon 7 times toggles developer tab visibility
        ClickIcon        -> if s.iconClicked >= 6
                            then { s | iconClicked <- 0
                                     , devEnabled <- not s.devEnabled
                                     , activeTab <- if s.activeTab == Developer
                                                        && s.devEnabled
                                                    then Log else s.activeTab
                                 }

                            else {s | iconClicked <- s.iconClicked + 1}
        NoOp             -> s

actions : Channel Action
actions = channel NoOp

-- Scene
scene : (Int,Int) -> State -> Element
scene dims state = layers [layer1 dims state]

layer1 : (Int, Int) -> State -> Element
layer1 dims state =
    flow down [ spacer 1 heights.marginTop
              , navigation dims state
              , content dims state
              ]

heights =
    { marginTop      = 16
    , tab            = 32
    , icon           = 32
    , nav            = 42
    , consoleButton  = 28
    , consoleToolbar = 48
    , marginBottom   = 3
    }

statusIcon : ConnectState -> Element
statusIcon c =
    let aspect          = 1.3285316308250572
        icon color      = image (round (toFloat heights.icon * aspect)) heights.icon
                            ("images/status_icon-" ++ color ++ ".svg")
        clickIcon color = clickable (send actions ClickIcon) (icon color)
    in case c of
        Connected    -> clickIcon "blue"
        NotConnected -> clickIcon "red"
        NoCard       -> clickIcon "orange"
        NoPin        -> clickIcon "purple"

-- Navigation
navigation : (Int, Int) -> State -> Element
navigation (w,h) state =
    flow right
        [ container (round (toFloat w * 0.85)) heights.nav midLeft
            (flow right [spacer 38 38, tabs state])
        , container (round (toFloat w * 0.15)) heights.nav midRight
            (flow right [statusIcon state.connect, spacer 32 38])
        ]

tabs : State -> Element
tabs state =
    let disabled = case state.connect of
            Connected    -> []
            NotConnected -> [Settings, Manage, Developer]
            NoCard       -> [Settings, Manage]
            NoPin        -> [Manage]
        spacer' = fittedImage 5 heights.tab ("images/tab_spacer.svg")
    in flow right <| [ tab Log      state.activeTab disabled
                     , spacer'
                     , tab Settings state.activeTab disabled
                     , spacer'
                     , tab Manage   state.activeTab disabled
                     ] ++ if state.devEnabled
                          then [ spacer'
                               , tab Developer state.activeTab disabled
                               ]
                          else []


tab : Tab -> Tab -> (List Tab) -> Element
tab t active disabled =
    let aspect         = 3.094594610699232
        name = case t of
            Log       -> "log"
            Settings  -> "settings"
            Manage    -> "manage"
            Developer -> "developer"
        img t =
            image (round (toFloat heights.tab * aspect))
                heights.tab
                    ("images/tab_" ++ name ++ "-" ++ t ++ ".svg")
        up             = img "inactive"
        hover          = img "hover"
        down           = img "inactive"
        disabledButton = img "disabled"
        activeButton   = img "active"
        button         = customButton (send actions (ChangeTab t)) up hover down
    in  if List.member t disabled
        then disabledButton
        else if t == active
             then activeButton
             else button

-- Content
content : (Int, Int) -> State -> Element
content (w,h) state =
    let h' = h - heights.marginTop - heights.nav - heights.marginBottom
        w' = w - (32 * 2)
    in container w h' middle <| console (w',h')

console : (Int, Int) -> Element
console (w,h) =
    let (w',h')  = (toFloat w, toFloat h)
        screenH  = h - heights.consoleToolbar
        screenH' = toFloat screenH
        screen   = collage w screenH [filled grey <| roundedRect w' screenH' (max w' h'/80)]
        toolbar  = container w heights.consoleToolbar middle clearButton
    in flow down [screen, toolbar]

clearButton : Element
clearButton =
    let aspect = 2.96658357613427
        img t =
            image (round (toFloat heights.consoleButton * aspect))
                heights.consoleButton
                    ("images/button_clear" ++ "-" ++ t ++ ".svg")
        up     = img "up"
        hover  = img "hover"
        down   = img "down"
    in  customButton (send actions ClearLog) up hover down

grey : Color.Color
grey = Color.rgb 0x1A 0x1A 0x1A

blue : Color.Color
blue = Color.rgb 0x0C 0xFE 0xFF

