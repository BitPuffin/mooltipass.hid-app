var emptyToGuiMessage =
    { setLog          : []
    , setDeviceStatus : 0
    , setImportInfo   : [0,"",0,0]
    , setMemInfo      : [0,null]
    , setKbInfo       : null
    , getKbInfo       : null
    , settingsInfo    : { keyboard: 0x93, timeout: 3 }
    };

var emptyFromGuiMessage =
    { setLog           : null
    , getState         : null
    , startImportMedia : null
    , startMemManage   : null
    , endMemManage     : null
    , saveMemManage    : null
    , setKeyboard      : null
    , getKeyboard      : null
    };

messageHasValue = function (message) {
    var hasValue = false;
    for (var prop in message) {
        hasValue |= message[prop] !== null;
    }
    return hasValue;
}
