#InstallKeybdHook
SendMode, Event  ; 用 SendEvent，IME 下較穩


; —— Alt + 數字 ——（用 Numpad，已測可行）
!1::SendNumLang("1")
!2::SendNumLang("2")
!3::SendNumLang("3")
!4::SendNumLang("4")
!5::SendNumLang("5")
!6::SendNumLang("6")
!7::SendNumLang("7")
!8::SendNumLang("8")
!9::SendNumLang("9")
!0::SendNumLang("0")


; ; —— Alt + 符號 ——（用 vk，避開 IME 組字）
!-::SendNumLang("-")
!,::SendNumLang(",") 
!.::SendNumLang(".")
!/::SendNumLang("/")  
!;::SendNumLang(";") 


SendNumLang(n) {
    prev := GetCurrentHKL()                 ; 記住目前語系
    hklEN := LoadHKL("00000409")            ; 英文(美式)
    PostMessage, 0x50, 0, %hklEN%, , A      ; WM_INPUTLANGCHANGEREQUEST
    ; Sleep, 10                               ; 需要時再放開
    SendInput, {Text}%n%
    if (prev) {
        PostMessage, 0x50, 0, %prev%, , A    ; 切回來
    }
}

GetCurrentHKL() {
    WinGet, hWnd, ID, A
    thread := DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "UInt*", 0, "UInt")
    return DllCall("GetKeyboardLayout", "UInt", thread, "Ptr")
}
LoadHKL(hklStr) {
    return DllCall("LoadKeyboardLayout", "Str", hklStr, "UInt", 1, "Ptr")
}
