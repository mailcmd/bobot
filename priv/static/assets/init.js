setTimeout(()=>{
    if (window.bobot_editor) {
        bobot_editor.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' || e.key === 'F2') e.preventDefault();
        });
        window.editor = ace.edit("bobot-editor-text");
        editor.setTheme("ace/theme/monokai");
        editor.session.setMode("ace/mode/elixir");
        editor.setKeyboardHandler("ace/keyboard/vscode");
        editor.setOptions({
            printMarginColumn: 98,
            fixedWidthGutter: true,
            newLineMode: 'unix',
            enableBasicAutocompletion: true,
            enableSnippets: true,
            enableLiveAutocompletion: true,
            tabSize: 2,       // Set the number of spaces for indentation (e.g., 4)
            useSoftTabs: true // Use spaces for indentation instead of tabs
        });

        // Keyboard Commands
        editor.commands.addCommand({
            name: 'commit',
            bindKey: {
                win: 'Ctrl-S',
                mac: 'Command-S'
            },
            exec: function(editor) {
                let e = new MouseEvent('click', {bubbles: true, cancelable: true})
                let btn = bobot_editor.querySelector('button.commit')
                btn.dispatchEvent(e);
                setTimeout(()=>editor.focus(), 200);
            },
            readOnly: false 
        });    
        editor.commands.addCommand({
            name: 'commit2',
            bindKey: {
                win: 'F2'
            },
            exec: function(editor) {
                let e = new MouseEvent('click', {bubbles: true, cancelable: true})
                let btn = bobot_editor.querySelector('button.commit')
                btn.dispatchEvent(e);
                setTimeout(()=>editor.focus(), 200);
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

        // Status Bar
        const StatusBar = ace.require("ace/ext/statusbar").StatusBar;
        window.editor_status_bar = new StatusBar(editor, document.getElementById("editor-status-bar"));

        // Autocompletion
        // window.lang_tools = ace.require("ace/ext/language_tools");
        // lang_tools.addCompleter({
        //     getCompletions: function(editor, session, pos, prefix, callback) {
        //         // Logic to generate Elixir-specific suggestions based on `prefix`
        //         // For example, you could provide suggestions for common Elixir modules or functions.
        //         var elixirWords = ["def", "defblock", "defcall", "fn", "module", "import", "use", "alias", "with", "case", "cond", "if", "unless"];
        //         console.log(elixirWords.map(function(word) {
        //             return { caption: word, value: word, meta: "Elixir keyword" };
        //         }))
        //         callback(null, elixirWords.map(function(word) {
        //             return { caption: word, value: word, meta: "Elixir keyword" };
        //         }));
        //     }
        // });
    }

    window.addEventListener('keydown', function(e) {
        let keyb = e.key;
        if (e.ctrlKey) keyb = 'CTRL+' + keyb;
        let bt = document.querySelector('*[keyb="'+keyb+'"]');
        // console.log(e.key, e.ctrlKey, bt);
        
        if (bt) {
            e.preventDefault();
            bt.focus();
            bt.click()
            if (bt.tagName == 'SELECT') {
                bt.showPicker();
            }
        }
    });

}, 1000)
