#Requires AutoHotkey v2.0
#SingleInstance Force

; Text Restoration Toolkit v1.0
; Ctrl+Alt+O = turn restoration ON/OFF
; Ctrl+Alt+P = restore ONLY the currently selected text (when ON)
; Ctrl+Alt+A = toggle local AI mode ON/OFF
;
; Offline mode provides conservative basic fixes and a small typo dictionary.
; Optional local AI mode connects ONLY to Ollama running on this computer.
; No cloud API, account, subscription, or internet connection is used by this script.
;
; For local AI: install Ollama, download a model (default: qwen2.5:3b),
; then make sure Ollama is running. Change aiModel below if needed.

restorationEnabled := false
localAIEnabled := true
aiModel := "qwen2.5:3b"
ollamaUrl := "http://127.0.0.1:11434/api/generate"
cleanerStatusFile := A_Temp "\TextToolkitCleanerStatus.ini"
disableCleanerMsg := DllCall("RegisterWindowMessage", "Str", "TextToolkit_DisableCleaner", "UInt")

; --- STARTUP GUIDE ---
Guide := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Text Restoration Toolkit v1.0")
Guide.SetFont("s10", "Segoe UI")
Guide.Add("Text", "w390", "Text Restoration Toolkit v1.0 is loaded!")
Guide.Add("Text", "w390", "Ctrl+Alt+O: turn restoration ON/OFF`nCtrl+Alt+P: restore selected text`nCtrl+Alt+A: toggle local AI ON/OFF")
Guide.Add("Text", "w390", "Offline mode fixes basic spelling, capitalization, a/an, and simple punctuation. Local AI mode uses Ollama on this PC if it is installed and running.")
Guide.Add("Button", "w100 x150 y+12 Default", "Got it").OnEvent("Click", CloseGuide)
Guide.Show("w420")
ShowStatus("Restoration Toolkit loaded - restoration is OFF", 2200)

^!o::
{
    global restorationEnabled
    if !restorationEnabled && !CheckCleanerConflict()
        return
    restorationEnabled := !restorationEnabled
    ShowStatus(restorationEnabled ? "Restoration: ON" : "Restoration: OFF")
}

^!a::
{
    global localAIEnabled
    localAIEnabled := !localAIEnabled
    ShowStatus(localAIEnabled ? "Local AI mode: ON (Ollama required)" : "Local AI mode: OFF (offline rules only)")
}

^!p::
{
    global restorationEnabled, localAIEnabled, aiModel, ollamaUrl

    if !restorationEnabled
    {
        ShowStatus("Restoration is OFF - press Ctrl+Alt+O first")
        return
    }

    if !CheckCleanerConflict()
        return

    savedClipboard := ClipboardAll()
    A_Clipboard := ""
    Send "^c"

    if !ClipWait(2)
    {
        A_Clipboard := savedClipboard
        ShowStatus("No text selected, or copying was blocked")
        return
    }

    originalText := A_Clipboard
    if (Trim(originalText) = "")
    {
        A_Clipboard := savedClipboard
        ShowStatus("The selection is empty")
        return
    }

    restoredText := ""
    usedAI := false

    if localAIEnabled
    {
        try
        {
            restoredText := RestoreWithOllama(originalText, ollamaUrl, aiModel)
            usedAI := (Trim(restoredText) != "")
        }
        catch
        {
            restoredText := ""
        }
    }

    if !usedAI
        restoredText := RestoreOffline(originalText)

    A_Clipboard := restoredText
    Send "^v"
    Sleep 350
    A_Clipboard := savedClipboard

    if usedAI
        ShowStatus("Text restored with local AI!")
    else if localAIEnabled
        ShowStatus("Offline fixes applied (Ollama unavailable)")
    else
        ShowStatus("Offline fixes applied!")
}

RestoreOffline(text)
{
    ; Conservative spelling replacements. Add more entries as needed.
    typoMap := Map(
        "teh", "the",
        "thier", "their",
        "recieve", "receive",
        "beleive", "believe",
        "definately", "definitely",
        "seperate", "separate",
        "becuase", "because",
        "agian", "again",
        "wierd", "weird",
        "freind", "friend",
        "occured", "occurred",
        "untill", "until",
        "doesnt", "doesn't",
        "didnt", "didn't",
        "isnt", "isn't",
        "wasnt", "wasn't",
        "werent", "weren't",
        "cant", "can't",
        "wont", "won't",
        "shouldnt", "shouldn't",
        "wouldnt", "wouldn't",
        "couldnt", "couldn't"
    )

    for wrong, right in typoMap
        text := RegExReplace(text, "i)\b" wrong "\b", right)

    ; Fix a/an before common vowel-sound words using a practical heuristic.
    ; Exceptions such as "a university" and "an hour" are handled explicitly.
    text := RegExReplace(text, "i)\ba\s+(hour|honest|honor|heir|herb)\b", "an $1")
    text := RegExReplace(text, "i)\ban\s+(university|unicorn|user|usual|useful|European|one)\b", "a $1")
    text := RegExReplace(text, "i)\ba\s+(?!university\b|unicorn\b|user\b|usual\b|useful\b|European\b|one\b)([aeiou][a-z]+)\b", "an $1")
    text := RegExReplace(text, "i)\ban\s+(?!hour\b|honest\b|honor\b|heir\b|herb\b)([bcdfghjklmnpqrstvwxyz][a-z]+)\b", "a $1")

    text := FixSentenceCapitalization(text)
    text := FixCommonCommaSpacing(text)

    ; Add a final period only when the last non-space character has no ending punctuation.
    trimmed := RTrim(text)
    if (trimmed != "" && !RegExMatch(trimmed, '[.!?"”’)]$'))
        text := trimmed "." SubStr(text, StrLen(trimmed) + 1)

    return text
}

FixSentenceCapitalization(text)
{
    result := ""
    atSentenceStart := true
    Loop Parse, text
    {
        ch := A_LoopField
        if atSentenceStart
        {
            if RegExMatch(ch, "\s")
            {
                result .= ch
                continue
            }
            result .= StrUpper(ch)
            atSentenceStart := false
        }
        else
            result .= ch

        if (ch = "." || ch = "!" || ch = "?")
            atSentenceStart := true
    }

    ; The pronoun I should always be uppercase.
    result := RegExReplace(result, "i)(?<![A-Za-z])i(?![A-Za-z])", "I")
    return result
}

FixCommonCommaSpacing(text)
{
    ; Remove spaces before punctuation and ensure one space after commas/periods
    ; when another word follows. Does not attempt to guess every comma location.
    text := RegExReplace(text, "\s+([,.;!?])", "$1")
    text := RegExReplace(text, "([,;:])(?=[A-Za-z0-9])", "$1 ")
    text := RegExReplace(text, "([.!?])(?=[A-Za-z])", "$1 ")
    return text
}

RestoreWithOllama(text, url, model)
{
    prompt := "Correct the text's spelling, grammar, capitalization, punctuation, and article use (a/an). Add natural commas and sentence-ending punctuation where appropriate. Preserve the original meaning, wording, tone, and paragraph breaks. Do not add facts, explanations, headings, or quotation marks. Return ONLY the corrected text.`n`nTEXT:`n" text
    payload := "{" 
        . "`"model`":`"" JsonEscape(model) "`"," 
        . "`"prompt`":`"" JsonEscape(prompt) "`"," 
        . "`"stream`":false," 
        . "`"options`":{" 
        . "`"temperature`":0.1," 
        . "`"num_predict`":2048}}"

    request := ComObject("WinHttp.WinHttpRequest.5.1")
    request.SetTimeouts(1200, 1200, 1200, 30000)
    request.Open("POST", url, false)
    request.SetRequestHeader("Content-Type", "application/json")
    request.Send(payload)

    if (request.Status != 200)
        throw Error("Ollama request failed")

    response := request.ResponseText
    if !RegExMatch(response, 's)"response"\s*:\s*"((?:\\.|[^"\\])*)"', &match)
        throw Error("Could not read Ollama response")

    answer := JsonUnescape(match[1])
    return Trim(answer, "`r`n`t " )
}

JsonEscape(value)
{
    value := StrReplace(value, "\", "\\")
    value := StrReplace(value, '"', '\"')
    value := StrReplace(value, "`r", "\r")
    value := StrReplace(value, "`n", "\n")
    value := StrReplace(value, "`t", "\t")
    return value
}

JsonUnescape(value)
{
    value := StrReplace(value, "\n", "`n")
    value := StrReplace(value, "\r", "`r")
    value := StrReplace(value, "\t", "`t")
    value := StrReplace(value, '\"', '"')
    value := StrReplace(value, "\\", "\")
    return value
}

ShowStatus(message, duration := 1600)
{
    ToolTip message
    SetTimer () => ToolTip(), -duration
}

CloseGuide(*)
{
    global Guide
    Guide.Destroy()
}


; Check whether the older punctuation-removal toolkit is currently enabled.
; If it is, ask whether to turn that toolkit OFF before continuing.
CheckCleanerConflict()
{
    global cleanerStatusFile, disableCleanerMsg

    if !FileExist(cleanerStatusFile)
        return true

    try
    {
        cleanerEnabled := IniRead(cleanerStatusFile, "Cleaner", "Enabled", "0")
        cleanerPid := IniRead(cleanerStatusFile, "Cleaner", "PID", "0")
        cleanerHwnd := IniRead(cleanerStatusFile, "Cleaner", "HWND", "0")
    }
    catch
        return true

    if (cleanerEnabled != "1" || !ProcessExist(Integer(cleanerPid)))
        return true

    answer := MsgBox(
        "The Text Formatting Toolkit (punctuation remover) is currently ON.`n`n"
        . "Would you like to turn it OFF for now and continue restoring text?`n`n"
        . "Yes = turn the other toolkit OFF and continue`nNo = cancel this restoration action",
        "Another Text Toolkit Is Enabled",
        "YesNo Icon! Default2"
    )

    if (answer != "Yes")
    {
        ShowStatus("Restoration cancelled - other toolkit is still ON")
        return false
    }

    try
    {
        SendMessage disableCleanerMsg, 0, 0,, "ahk_id " Integer(cleanerHwnd),,,, 1500
        Sleep 120
        cleanerEnabledNow := IniRead(cleanerStatusFile, "Cleaner", "Enabled", "0")
        if (cleanerEnabledNow = "1")
        {
            MsgBox "Could not turn off the other toolkit. Please turn it off manually, then try again.", "Could Not Disable Other Toolkit", "Iconx"
            return false
        }
    }
    catch
    {
        MsgBox "Could not contact the other toolkit. Please turn it off manually, then try again.", "Could Not Contact Other Toolkit", "Iconx"
        return false
    }

    ShowStatus("Other toolkit turned OFF - continuing")
    return true
}
