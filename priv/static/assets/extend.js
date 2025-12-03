function confirm_action(message, action, onconfirm) {
    box_confirm_action.querySelector('#action').value = action;
    box_confirm_action.querySelector('#message').innerHTML = message;
    const form = box_confirm_action.querySelector('form');
    form.onsubmit = onconfirm ?? function(){};
    form.onsubmit.bind(form);
    box_confirm_action.showModal();
}

function editor_open(title, text, readonly = false) {
    editor_set_text(text);
    editor_set_title(title);
    bobot_editor.showModal();
    editor.selection.clearSelection();
    editor_set_readonly(readonly);
    editor_gotoline(0);
    setTimeout(() => {
        editor.focus();
        document.querySelector('.ace_text-input')?.focus();
    }, 100);
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
        editor.focus();
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
    editor.gotoLine(...[nline].flat());
    if (select_line) editor.selection.selectLine();
    editor.focus();
}

function open_connect(el) {
    el.disabled = true;
    const block = el.closest('.defblock');
    block.style.filter = 'grayscale(1)';
    block.style.opacity = '0.5';
    otherBlocks = siblings(block);
    otherBlocks.forEach( b => {
        const div = b.querySelector('div')
        div.classList.add('block-selectable');
        const button = div.querySelector('.connect');
        button.setAttribute('onclick', 'close_connect(this)');
        const icon = button.querySelector('span');
        icon.classList.add('hero-plus-circle-solid');
        icon.classList.remove('hero-arrow-down-circle');
    });
    window.connect_from = el.value;
}

function close_connect(el) {
    const block = el.closest('.defblock');
    block.style.filter = null;
    block.style.opacity = null;
    otherBlocks = [...siblings(block), block];
    otherBlocks.forEach( b => {
        b.style.filter = null;
        b.style.opacity = null;
        const div = b.querySelector('div')
        div.classList.remove('block-selectable');
        const button = div.querySelector('.connect');
        button.disabled = false;
        button.setAttribute('onclick', 'open_connect(this)');
        const icon = button.querySelector('span');
        icon.classList.remove('hero-plus-circle-solid');
        icon.classList.add('hero-arrow-down-circle');
    });
    block_connect(connect_from, el.value);    
}

function block_connect(b1, b2, color = '#a855f7', update = true) {
    const from = document.querySelector(`[data-block-name="${b1}"]`);
    const to = document.querySelector(`[data-block-name="${b2}"]`);
    let line = new LeaderLine(
        from,
        LeaderLine.areaAnchor(to, {color: 'transparent', width: '100%', height: '100%'}),
        // to,
        {
            startPlug: 'square',
            endPlug: 'arrow1',
            color: color, 
            size: 3,
            path: 'magnet',
            dash: {animation: true}
        }
    );

    from.lines = from.lines ?? [];
    from.lines.push(line);
    to.lines = to.lines ?? [];
    to.lines.push(line);
    
    leaderLines[line._id].svg.addEventListener('click', function(e) {
        if (e.ctrlKey) line.remove();
        from.lines = from.lines.filter(l => l != line)
        to.lines = to.lines.filter(l => l != line)
        window.connections = window.connections.filter(l => l != line);
    });
    leaderLines[line._id].svg.addEventListener('mouseover', function(e) {
        line.middleLabel = "Ctrl+CLICK to remove";
    });
    leaderLines[line._id].svg.addEventListener('mouseout', function(e) {
        line.middleLabel = "";
    });
    leaderLines[line._id].from = from;
    leaderLines[line._id].to = to;
    
    window.connections.push(line);

    if (update) update_connections.click();
}

function block_connects_remove(block_name) {
    const b = document.querySelector(`[data-block-name="${block_name}"]`);
    b.lines.forEach( l => {
        l.remove();
        window.connections = window.connections.filter(line => line != l);
    })    

    update_connections.click();
}

function remove_block_connections() {
    if (window.connections) {
        window.connections.forEach(l => l.remove());
        window.connections = [];
    }
}

function add_pseudo_block(text, name, pos) {
    name = name ?? random_name();
    const span = document.querySelector('span.block');
    span.innerHTML += `
    <span class="pseudo-defblock" data-block-name="${name}"
          style="${pos ? 'transform: '+pos : ''};">
      <div class="flex-none inline-block w-full h-full relative text-xs m-2 p-2
                  border-2 border-purple-400 bg-white rounded-lg" 
           style="text-align: center; align-content: center; rotate: -45deg;">
        <button type="button" 
                class="connect absolute right-10 top-2 text-purple-600 hover:text-purple-800 hover:scale-110 " 
                value="${name}" title="Connect with..." onclick="open_connect(this)">
          <span class="h-3 w-3 hero-arrow-down-circle"></span>
        </button>
        <div style="rotate: 45deg;">
          ${text}
        </div>
      </div>
    </span>
    `;
}

function serialize_block_connections() {
    return JSON.stringify(
        Object.values(leaderLines).map( l => 
            [l.from.getAttribute('data-block-name'), l.to.getAttribute('data-block-name')]
        )
    );
}

function serialize_block_positions() {
    return JSON.stringify(
        (Array.from(document.querySelectorAll('span[data-block-name]'))||[])
            .reduce((a,b) => (a[b.getAttribute('data-block-name')] = b.style.transform, a), {})
    )
}

function serialize_bot() {
    return `{ 
        "positions": ${serialize_block_positions()},
        "connections": ${serialize_block_connections()}
    }`;
}

// utils
const siblings = n => [...n.parentElement.children].filter(c=>c.nodeType == 1 && c!=n)
const random_name = () => 
    String.fromCharCode(Math.round(Math.random()*26)+97) + Math.random().toString().slice(2,8);
