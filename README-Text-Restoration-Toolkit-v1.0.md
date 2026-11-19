# Text Restoration Toolkit v1.0

An AutoHotkey v2 tool that helps restore readable formatting to selected text. It is designed as the companion to **Text Formatting Toolkit v5.0** (the punctuation-removal tool).

## What it does

- Applies a small set of built-in spelling corrections.
- Fixes some common **a/an** article mistakes using simple rules.
- Capitalizes sentence beginnings and the standalone pronoun **I**.
- Fixes common punctuation spacing.
- Adds a final period when the selected text has no ending punctuation.
- Optionally sends selected text to a locally running Ollama model for more advanced spelling, grammar, punctuation, and wording corrections.

**Important:** The offline rules are intentionally limited. They are not a full spell-checker or grammar engine, and they may miss mistakes or occasionally make an incorrect correction. The local AI option is more capable but should still be proofread.

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/)
- Optional: [Ollama](https://ollama.com/) and a locally downloaded model

## Hotkeys

| Shortcut | Action |
|---|---|
| `Ctrl + Alt + O` | Turn text restoration ON or OFF |
| `Ctrl + Alt + P` | Restore the currently selected text (restoration must be ON) |
| `Ctrl + Alt + A` | Toggle local AI mode ON or OFF |

The script starts with restoration OFF. Select text before pressing `Ctrl + Alt + P`. The script copies the selection, processes it, pastes the result, and then attempts to restore the previous clipboard contents.

## Optional local AI setup (offline after model download)

1. Install Ollama from [ollama.com](https://ollama.com/).
2. Open Command Prompt or PowerShell.
3. Download a model once:

   ```powershell
   ollama pull qwen2.5:3b
   ```

4. Make sure Ollama is running on this computer.
5. Leave **Local AI mode** ON with `Ctrl + Alt + A`.

The script connects to `http://127.0.0.1:11434`, which is the local computer only. It does not send text to a cloud AI service. After the model has been downloaded, the model can run without Wi-Fi. Model size and speed depend on your computer. You can change `aiModel` near the top of the `.ahk` file if you downloaded a different Ollama model.

If Ollama is unavailable or returns an error, the script falls back to its built-in offline rules.

## Companion-tool conflict detection

For automatic conflict detection, use the **updated** `Text Formatting Toolkit v5.0.ahk` included with this release.

- When the old punctuation-removal toolkit is ON, the restoration toolkit detects it before enabling restoration and before processing selected text.
- A popup asks whether to turn the old toolkit OFF for now or cancel.
- Choosing **Yes** sends a local message to the old toolkit to switch cleaning OFF, then continues.
- Choosing **No** cancels the restoration action and leaves the old toolkit ON.
- The two scripts exchange status through a small INI file in your Windows temporary folder. No internet connection is used.

If you keep an older, unmodified copy of Text Formatting Toolkit v5.0, automatic detection and pausing will not work. Replace it with the updated companion file.

## Installation

1. Put `Text-Restoration-Toolkit-v1.0.ahk` somewhere convenient.
2. Install AutoHotkey v2 if it is not already installed.
3. Double-click the `.ahk` file.
4. To use companion detection, also replace the old v5.0 script with the updated copy supplied alongside this README.

You can run either script by itself. For best results, do not run both text-processing actions on the same selection.

## Privacy and limitations

- Built-in offline corrections stay on your computer.
- Ollama mode sends the selected text to the Ollama service running locally on your computer; this script does not use a remote API.
- Avoid processing passwords, private information, or sensitive text with any automated correction tool unless you are comfortable with the local setup.
- This script is not a substitute for careful proofreading.
- The clipboard is used to transfer selected text. Some applications may block copying or pasting, and clipboard managers may affect clipboard restoration.

## Files

- `Text-Restoration-Toolkit-v1.0.ahk` — the restoration tool.
- `Text-Formatting-Toolkit-v5.0.ahk` — updated companion cleaner with pause-message support.
- `README-Text-Restoration-Toolkit-v1.0.md` — this guide.
