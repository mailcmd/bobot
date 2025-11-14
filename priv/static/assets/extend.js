function confirm_action(message, action) {
    box_confirm_action.querySelector('#action').value = action
    box_confirm_action.querySelector('#message').innerHTML = message
    box_confirm_action.showModal();
}

function editor_open(title, text, readonly = false) {
    editor_set_text(text);
    editor_set_title(title);
    block_editor.showModal();
    editor.selection.clearSelection();
    editor.setReadOnly(readonly);
    if (readonly) {
        block_editor.querySelectorAll('.editing').forEach( b => b.style.display = 'none')
        block_editor.querySelectorAll('.reading').forEach( b => b.style.display = '')
    } else {
        block_editor.querySelectorAll('.reading').forEach( b => b.style.display = 'none')
        block_editor.querySelectorAll('.editing').forEach( b => b.style.display = '')
    }
}

function editor_set_text(text) {
    editor.setValue(text);
}

function editor_set_title(title) {
    block_editor.setAttribute('data-title', title)
}

function editor_set_status_bar(text, goto_line = null, select_line = true) {
    document.querySelector('#editor-status-bar > .info').innerHTML = text;
    if (goto_line) editor_gotoline(goto_line, select_line);
}

function editor_clear_status_bar() {
    document.querySelector('#editor-status-bar > .info').innerHTML = '';
}

function editor_set_operation(e, ope) {
    operation.value = ope;
    ctrl.value = e.ctrlKey    
}

function editor_gotoline(nline, select_line = false) {
    editor.gotoLine(nline);
    if (select_line) editor.selection.selectLine();
    editor.focus();
}