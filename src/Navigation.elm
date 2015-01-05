module Navigation where
import Graphics.Element (..)
import Graphics.Input (..)
import Signal (..)
import List

import Layout (..)
import State (..)

navigation : (Int, Int) -> State -> Element
navigation (w,h) state =
    flow right
        [ container (round (toFloat w * 0.85)) heights.nav midLeft
            (flow right [navSpacer 38, tabs state])
        , container (round (toFloat w * 0.15)) heights.nav midRight
            (flow left [navSpacer 32, statusIcon state.connect, navSpacer 9000])
        ]

statusIcon : ConnectState -> Element
statusIcon c =
    let aspect          = 1.3285316308250572
        width           = round (toFloat heights.icon * aspect)
        img color       = image width heights.icon
                            ("images/status_icon-" ++ color ++ ".svg")
        clickIcon color = clickable (send actions ClickIcon) (img color)
        icon            = case c of
            Connected    -> clickIcon "blue"
            NotConnected -> clickIcon "red"
            NoCard       -> clickIcon "orange"
            NoPin        -> clickIcon "purple"
    in flow down [icon, spacer 1 heights.iconPadding, navLine width]

navSpacer w = container w heights.tab bottomLeft (navLine w)
navLine w = tiledImage w 1 "images/tab_spacer_pixel.png"

tabs : State -> Element
tabs state =
    let disabled = case state.connect of
            Connected    -> []
            NotConnected -> [Settings, Manage, Developer]
            NoCard       -> [Settings, Manage]
            NoPin        -> [Settings, Manage]
    in flow right <| [ tab Log      state.activeTab disabled
                     , navSpacer 5
                     , tab Settings state.activeTab disabled
                     , navSpacer 5
                     , tab Manage   state.activeTab disabled
                     ] ++ ( if state.devEnabled
                            then [ navSpacer 5
                                 , tab Developer state.activeTab disabled
                                 ]
                            else [] )
                     ++ [navSpacer 9000]

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
    in  if  | List.member t disabled -> disabledButton
            | t == active            -> activeButton
            | otherwise              -> button
