setTimeout(()=>{
    bobot_editor.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') e.preventDefault();
    });
    window.editor = ace.edit("bobot-editor-text");
    editor.setTheme("ace/theme/monokai");
    editor.session.setMode("ace/mode/elixir");
    editor.setOptions({
        printMarginColumn: 98,
        fixedWidthGutter: true,
        newLineMode: 'unix'
    });
    editor.session.setOptions({
        tabSize: 2,       // Set the number of spaces for indentation (e.g., 4)
        useSoftTabs: true // Use spaces for indentation instead of tabs
    });
    editor.setKeyboardHandler("ace/keyboard/vscode");
    editor.commands.addCommand({
        name: 'commit',
        bindKey: {
            win: 'Ctrl-S',
            mac: 'Command-S'
        },
        exec: function(editor) {
            let e = new MouseEvent('click', {bubbles: true, cancelable: true})
            bobot_editor.querySelector('button.commit').dispatchEvent(e);
        },
        readOnly: false 
    });    
    editor.commands.addCommand({
        name: 'cancel',
        bindKey: {
            win: 'Esc',
            mac: 'Esc'
        },
        exec: function(editor) {
            let e = new MouseEvent('click', {bubbles: true, cancelable: true})
            bobot_editor.querySelector('button.cancel').dispatchEvent(e);
        },
        readOnly: false 
    });
    editor.commands.addCommand({
        name: 'cancel2',
        bindKey: {
            win: 'Ctrl-Esc',
            mac: 'Command-Esc'
        },
        exec: function(editor) {
            let e = new MouseEvent('click', {bubbles: true, cancelable: true, ctrlKey: true})
            bobot_editor.querySelector('button.cancel').dispatchEvent(e);
        },
        readOnly: false 
    });
    const StatusBar = ace.require("ace/ext/statusbar").StatusBar;
    window.editor_status_bar = new StatusBar(editor, document.getElementById("editor-status-bar"));
}, 1000)
