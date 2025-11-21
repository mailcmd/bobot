function confirm_action(message, action) {
    box_confirm_action.querySelector('#action').value = action
    box_confirm_action.querySelector('#message').innerHTML = message
    box_confirm_action.showModal();
}

function editor_open(title, text, readonly = false) {
    editor_set_text(text);
    editor_set_title(title);
    bobot_editor.showModal();
    editor.selection.clearSelection();
    editor_set_readonly(readonly);
    editor.focus();
    editor_gotoline(0);
}

function editor_set_readonly(readonly) {
    editor.setReadOnly(readonly);
    if (readonly) {
        bobot_editor.querySelectorAll('.editing').forEach( b => b.style.display = 'none');
        bobot_editor.querySelectorAll('.reading').forEach( b => b.style.display = '');
        bobot_editor.classList.add('readonly');
        editor_set_status_bar('Readonly!');
        editor.renderer.$cursorLayer.element.style.display = 'none';
    } else {
        bobot_editor.querySelectorAll('.reading').forEach( b => b.style.display = 'none');
        bobot_editor.querySelectorAll('.editing').forEach( b => b.style.display = '');
        bobot_editor.classList.remove('readonly');
        editor_set_status_bar('');
        editor.renderer.$cursorLayer.element.style.display = 'block';
    }    
}

function editor_set_text(text) {
    editor.setValue(text);
}

function editor_set_title(title) {
    bobot_editor.setAttribute('data-title', title)
}

function editor_set_status_bar(text, goto_line = null, select_line = true) {
    document.querySelector('#editor-status-bar > .info').innerHTML = text;
    if (goto_line) setTimeout(() => editor_gotoline(goto_line, select_line), 500);
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

function block_connect(b1, b2, color = '#a855f7') {
    new LeaderLine(
        document.querySelector(`[data-block-name="${b1}"]`),
        LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b1}"]`)),
        {
            startPlug: 'square',
            endPlug: 'disc',
            color: color, 
            size: 2
        }
    );
    new LeaderLine(
        LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b1}"]`)),
        LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b2}"]`)),
        {
            startPlug: 'disc',
            endPlug: 'disc',
            color: color, 
            size: 2
        }
    );
    new LeaderLine(
        LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b2}"]`)),
        document.querySelector(`[data-block-name="${b2}"]`),
        {
            startPlug: 'disc',
            endPlug: 'arrow1',
            color: color, 
            size: 2
        }
    );

}