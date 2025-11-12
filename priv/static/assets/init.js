setTimeout(()=>{
    window.editor = ace.edit("block-editor-text");
    editor.setTheme("ace/theme/monokai");
    editor.session.setMode("ace/mode/elixir");
    editor.setOptions({
        printMarginColumn: 98
    });
    const StatusBar = ace.require("ace/ext/statusbar").StatusBar;
    window.editor_status_bar = new StatusBar(editor, document.getElementById("editor-status-bar"));
}, 1000)
