@tool
extends EditorPlugin

var config_dock # To store the reference to the dock control

# --- Configuration UI Elements ---
var unirig_path_edit: LineEdit
var browse_button: Button
var status_label: Label
var save_config_button: Button
var config_file_dialog: EditorFileDialog 

const UNIRIG_PATH_SETTING = "unirig_plugin/unirig_installation_path"

# --- Rigging Process UI Elements ---
var input_file_edit: LineEdit
var input_browse_button: Button
var output_file_edit: LineEdit
var output_browse_button: Button
var seed_edit: LineEdit
var start_rigging_button: Button
var log_display: RichTextLabel
var rigging_file_dialog: EditorFileDialog 

# --- For OS.execute ---
var os_output_array = [] 
var os_exit_code = -1    


func _enter_tree():
    # --- Main Dock Container ---
    config_dock = VBoxContainer.new()
    config_dock.name = "UniRigPanel" 
    
    # --- Configuration Section ---
    var config_title_label = Label.new()
    config_title_label.text = "UniRig Configuration"
    config_title_label.horizontal_alignment = Label.HORIZONTAL_ALIGNMENT_CENTER
    config_dock.add_child(config_title_label)
    
    var path_hbox = HBoxContainer.new()
    config_dock.add_child(path_hbox)

    var path_label = Label.new()
    path_label.text = "UniRig Python/Installation Path:"
    path_hbox.add_child(path_label)

    unirig_path_edit = LineEdit.new()
    unirig_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    unirig_path_edit.placeholder_text = "Enter path to UniRig installation"
    unirig_path_edit.text_changed.connect(_on_unirig_path_text_changed) # Validate on text change
    path_hbox.add_child(unirig_path_edit)

    browse_button = Button.new()
    browse_button.text = "Browse"
    browse_button.pressed.connect(_on_config_browse_button_pressed) 
    path_hbox.add_child(browse_button)
    
    status_label = Label.new()
    status_label.autowrap_mode = Label.AUTOWRAP_WORD
    config_dock.add_child(status_label)

    save_config_button = Button.new()
    save_config_button.text = "Save Configuration"
    save_config_button.pressed.connect(_on_save_config_button_pressed)
    config_dock.add_child(save_config_button)

    _load_config() # This will also call _update_status_label via text_changed or directly

    # --- Separator ---
    var sep1 = HSeparator.new()
    sep1.set_custom_minimum_size(Vector2(0, 10)) 
    config_dock.add_child(sep1)


    # --- Rigging Process Section ---
    var rigging_title_label = Label.new()
    rigging_title_label.text = "Rigging Process"
    rigging_title_label.horizontal_alignment = Label.HORIZONTAL_ALIGNMENT_CENTER
    config_dock.add_child(rigging_title_label)

    # Input File Elements (and so on, no changes to this part of UI creation)
    var input_file_hbox = HBoxContainer.new()
    config_dock.add_child(input_file_hbox)
    var input_file_label = Label.new()
    input_file_label.text = "Input .glb File:"
    input_file_hbox.add_child(input_file_label)
    input_file_edit = LineEdit.new()
    input_file_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    input_file_edit.placeholder_text = "Path to input .glb file"
    input_file_hbox.add_child(input_file_edit)
    input_browse_button = Button.new()
    input_browse_button.text = "Browse"
    input_browse_button.pressed.connect(_on_input_browse_pressed)
    input_file_hbox.add_child(input_browse_button)

    var output_file_hbox = HBoxContainer.new()
    config_dock.add_child(output_file_hbox)
    var output_file_label = Label.new()
    output_file_label.text = "Output Rigged .glb File:"
    output_file_hbox.add_child(output_file_label)
    output_file_edit = LineEdit.new()
    output_file_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    output_file_edit.placeholder_text = "Path for output rigged .glb file"
    output_file_hbox.add_child(output_file_edit)
    output_browse_button = Button.new()
    output_browse_button.text = "Browse"
    output_browse_button.pressed.connect(_on_output_browse_pressed)
    output_file_hbox.add_child(output_browse_button)

    var seed_hbox = HBoxContainer.new()
    config_dock.add_child(seed_hbox)
    var seed_label = Label.new()
    seed_label.text = "Seed (Optional):"
    seed_hbox.add_child(seed_label)
    seed_edit = LineEdit.new()
    seed_edit.placeholder_text = "Enter integer seed (optional)"
    seed_hbox.add_child(seed_edit)

    start_rigging_button = Button.new()
    start_rigging_button.text = "Start Rigging"
    start_rigging_button.pressed.connect(_on_start_rigging_pressed)
    config_dock.add_child(start_rigging_button)
    
    log_display = RichTextLabel.new()
    log_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
    log_display.scroll_following = true
    log_display.focus_mode = Control.FOCUS_CLICK 
    log_display.selection_enabled = true 
    config_dock.add_child(log_display)
    log_display.add_text("UniRig Plugin initialized. Waiting for actions...\n")

    add_control_to_dock(DOCK_SLOT_LEFT_UL, config_dock)
    set_dock_tab_name(config_dock, "UniRig") 


func _exit_tree():
    if config_dock:
        remove_control_from_docks(config_dock)
        config_dock.queue_free() 
        config_dock = null
    if config_file_dialog:
        config_file_dialog.queue_free(); config_file_dialog = null
    if rigging_file_dialog:
        rigging_file_dialog.queue_free(); rigging_file_dialog = null

# --- Configuration Methods ---

func _validate_unirig_path(path_raw: String) -> String:
    if path_raw.is_empty():
        return "Status: Path not set."

    var valid_path = ProjectSettings.globalize_path(path_raw) 

    if not DirAccess.dir_exists_absolute(valid_path):
        return "Status: [color=red]ERROR[/color] - UniRig path does not exist or is not accessible: " + valid_path

    var inference_dir = valid_path.path_join("launch/inference")
    if not DirAccess.dir_exists_absolute(inference_dir):
        return "Status: [color=red]ERROR[/color] - 'launch/inference' subdirectory not found. Is this the UniRig root directory?"

    var required_scripts = ["generate_skeleton.sh", "generate_skin.sh", "merge.sh"]
    for script_name in required_scripts:
        if not FileAccess.file_exists(inference_dir.path_join(script_name)):
            return "Status: [color=red]ERROR[/color] - UniRig script '" + script_name + "' not found in 'launch/inference/'."
            
    return "Status: [color=green]UniRig path appears valid.[/color]"


func _update_status_label():
    if status_label and unirig_path_edit: # Ensure UI is ready
        status_label.text = _validate_unirig_path(unirig_path_edit.text)

func _on_unirig_path_text_changed(_new_text: String):
    _update_status_label()

func _load_config():
    if EditorSettings.has_setting(UNIRIG_PATH_SETTING):
        unirig_path_edit.text = EditorSettings.get_setting(UNIRIG_PATH_SETTING)
    else:
        unirig_path_edit.text = ""
    _update_status_label() # Update status after loading

func _save_config():
    EditorSettings.set_setting(UNIRIG_PATH_SETTING, unirig_path_edit.text)
    EditorSettings.save() 
    _update_status_label() # Update status after saving
    if log_display: log_display.add_text("Configuration saved. Path: " + unirig_path_edit.text + "\n")


func _on_config_browse_button_pressed(): 
    if config_file_dialog == null: 
        config_file_dialog = EditorFileDialog.new()
        config_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
        config_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM 
        config_file_dialog.title = "Select UniRig Installation Directory"
        config_file_dialog.dir_selected.connect(_on_config_file_dialog_dir_selected) 
        get_editor_interface().get_base_control().add_child(config_file_dialog)

    config_file_dialog.current_path = ProjectSettings.globalize_path(unirig_path_edit.text)
    config_file_dialog.popup_centered_ratio()

func _on_config_file_dialog_dir_selected(dir: String): 
    unirig_path_edit.text = dir 
    _update_status_label() # Path changed, so update status

func _on_save_config_button_pressed():
    _save_config()

# --- Rigging Process Methods ---

func _ensure_rigging_file_dialog():
    if rigging_file_dialog == null:
        rigging_file_dialog = EditorFileDialog.new()
        rigging_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
        get_editor_interface().get_base_control().add_child(rigging_file_dialog)
    
    if rigging_file_dialog.is_connected("file_selected", _on_rigging_file_dialog_file_selected_input):
        rigging_file_dialog.file_selected.disconnect(_on_rigging_file_dialog_file_selected_input)
    if rigging_file_dialog.is_connected("file_selected", _on_rigging_file_dialog_file_selected_output):
        rigging_file_dialog.file_selected.disconnect(_on_rigging_file_dialog_file_selected_output)

func _on_input_browse_pressed():
    _ensure_rigging_file_dialog()
    rigging_file_dialog.title = "Select Input .glb File"
    rigging_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
    rigging_file_dialog.clear_filters(); rigging_file_dialog.add_filter("*.glb ; GLB Binary")
    rigging_file_dialog.file_selected.connect(_on_rigging_file_dialog_file_selected_input)
    var current_input_dir = input_file_edit.text
    if not current_input_dir.is_empty() and DirAccess.dir_exists_absolute(current_input_dir.get_base_dir()):
        rigging_file_dialog.current_dir = current_input_dir.get_base_dir()
    else: rigging_file_dialog.current_dir = "res://" 
    rigging_file_dialog.popup_centered_ratio()

func _on_rigging_file_dialog_file_selected_input(path: String):
    input_file_edit.text = path 
    if log_display: log_display.add_text("Input file selected: " + path + "\n")

func _on_output_browse_pressed():
    _ensure_rigging_file_dialog()
    rigging_file_dialog.title = "Select Output Rigged .glb File Path"
    rigging_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
    rigging_file_dialog.clear_filters(); rigging_file_dialog.add_filter("*.glb ; GLB Binary")
    rigging_file_dialog.file_selected.connect(_on_rigging_file_dialog_file_selected_output)
    var current_output_dir = output_file_edit.text
    if not current_output_dir.is_empty() and DirAccess.dir_exists_absolute(current_output_dir.get_base_dir()):
        rigging_file_dialog.current_dir = current_output_dir.get_base_dir()
    else: rigging_file_dialog.current_dir = "res://" 
    rigging_file_dialog.popup_centered_ratio()

func _on_rigging_file_dialog_file_selected_output(path: String):
    output_file_edit.text = path 
    if log_display: log_display.add_text("Output file path set: " + path + "\n")

func _get_godot_error_message(error_code: int) -> String:
    match error_code:
        OK: return "OK (No error)"
        FAILED: return "FAILED (Generic error)"
        ERR_UNAVAILABLE: return "ERR_UNAVAILABLE (Unavailable)"
        ERR_UNCONFIGURED: return "ERR_UNCONFIGURED (Unconfigured)"
        ERR_UNAUTHORIZED: return "ERR_UNAUTHORIZED (Unauthorized)"
        ERR_PARAMETER_RANGE_ERROR: return "ERR_PARAMETER_RANGE_ERROR (Parameter range error)"
        ERR_OUT_OF_MEMORY: return "ERR_OUT_OF_MEMORY (Out of memory)"
        ERR_FILE_NOT_FOUND: return "ERR_FILE_NOT_FOUND (File not found)"
        ERR_FILE_BAD_DRIVE: return "ERR_FILE_BAD_DRIVE (File bad drive)"
        ERR_FILE_BAD_PATH: return "ERR_FILE_BAD_PATH (File bad path)"
        ERR_FILE_NO_PERMISSION: return "ERR_FILE_NO_PERMISSION (File no permission)"
        ERR_FILE_ALREADY_IN_USE: return "ERR_FILE_ALREADY_IN_USE (File already in use)"
        ERR_FILE_CANT_OPEN: return "ERR_FILE_CANT_OPEN (File can't open)"
        ERR_FILE_CANT_WRITE: return "ERR_FILE_CANT_WRITE (File can't write)"
        ERR_FILE_CANT_READ: return "ERR_FILE_CANT_READ (File can't read)"
        ERR_FILE_UNRECOGNIZED: return "ERR_FILE_UNRECOGNIZED (File unrecognized)"
        ERR_FILE_CORRUPT: return "ERR_FILE_CORRUPT (File corrupt)"
        ERR_FILE_MISSING_DEPENDENCIES: return "ERR_FILE_MISSING_DEPENDENCIES (File missing dependencies)"
        ERR_FILE_EOF: return "ERR_FILE_EOF (File End-Of-File)"
        ERR_CANT_OPEN: return "ERR_CANT_OPEN (Can't open)"
        ERR_CANT_CREATE: return "ERR_CANT_CREATE (Can't create)"
        ERR_QUERY_FAILED: return "ERR_QUERY_FAILED (Query failed)"
        ERR_ALREADY_IN_USE: return "ERR_ALREADY_IN_USE (Already in use)"
        ERR_LOCKED: return "ERR_LOCKED (Locked)"
        ERR_TIMEOUT: return "ERR_TIMEOUT (Timeout)"
        ERR_CANT_CONNECT: return "ERR_CANT_CONNECT (Can't connect)"
        ERR_CANT_RESOLVE: return "ERR_CANT_RESOLVE (Can't resolve)"
        ERR_CONNECTION_ERROR: return "ERR_CONNECTION_ERROR (Connection error)"
        ERR_CANT_ACQUIRE_RESOURCE: return "ERR_CANT_ACQUIRE_RESOURCE (Can't acquire resource)"
        ERR_CANT_FORK: return "ERR_CANT_FORK (Can't fork process)"
        ERR_INVALID_DATA: return "ERR_INVALID_DATA (Invalid data)"
        ERR_INVALID_PARAMETER: return "ERR_INVALID_PARAMETER (Invalid parameter)"
        ERR_ALREADY_EXISTS: return "ERR_ALREADY_EXISTS (Already exists)"
        ERR_DOES_NOT_EXIST: return "ERR_DOES_NOT_EXIST (Does not exist)"
        ERR_DATABASE_CANT_READ: return "ERR_DATABASE_CANT_READ (Database can't read)"
        ERR_DATABASE_CANT_WRITE: return "ERR_DATABASE_CANT_WRITE (Database can't write)"
        ERR_COMPILATION_FAILED: return "ERR_COMPILATION_FAILED (Compilation failed)"
        ERR_METHOD_NOT_FOUND: return "ERR_METHOD_NOT_FOUND (Method not found)"
        ERR_LINK_FAILED: return "ERR_LINK_FAILED (Link failed)"
        ERR_SCRIPT_FAILED: return "ERR_SCRIPT_FAILED (Script failed)"
        ERR_CYCLIC_LINK: return "ERR_CYCLIC_LINK (Cyclic link)"
        ERR_INVALID_DECLARATION: return "ERR_INVALID_DECLARATION (Invalid declaration)"
        ERR_DUPLICATE_SYMBOL: return "ERR_DUPLICATE_SYMBOL (Duplicate symbol)"
        ERR_PARSE_ERROR: return "ERR_PARSE_ERROR (Parse error)"
        ERR_BUSY: return "ERR_BUSY (Busy)"
        ERR_SKIP: return "ERR_SKIP (Skip)"
        ERR_HELP: return "ERR_HELP (Help)"
        ERR_BUG: return "ERR_BUG (Bug)"
        ERR_PRINTER_ON_FIRE: return "ERR_PRINTER_ON_FIRE (Printer on fire!)" # lol
        _: return "Unknown Error Code (" + str(error_code) + ")"


func _run_unirig_script(script_name: String, script_args: Array, log_prefix: String) -> bool:
    log_display.add_text(log_prefix + "Preparing to run " + script_name + "...\n")

    var unirig_base_path_raw = unirig_path_edit.text # Validation already done by caller
    var unirig_base_path = ProjectSettings.globalize_path(unirig_base_path_raw) 
    if not unirig_base_path.ends_with("/"): unirig_base_path += "/"
    var script_dir_path = unirig_base_path + "launch/inference/"
    var full_script_path = script_dir_path + script_name
    
    # These checks are somewhat redundant if _validate_unirig_path was called, but good for safety.
    if not DirAccess.dir_exists_absolute(script_dir_path) or not FileAccess.file_exists(full_script_path): 
        log_display.push_color(Color.RED)
        log_display.append_text(log_prefix + "CRITICAL ERROR: Script path or directory invalid. This should have been caught by UniRig Path validation.\n")
        log_display.append_text(log_prefix + "Attempted script path: " + full_script_path + "\n")
        log_display.pop()
        return false

    var command_to_log = full_script_path
    var final_script_args = [] 
    for arg in script_args:
        var arg_str = str(arg)
        final_script_args.append(arg_str)
        command_to_log += " \"" + arg_str + "\"" # Enclose args in quotes for logging clarity
        
    log_display.append_text(log_prefix + "Executing: " + command_to_log + "\n")
    
    os_output_array.clear(); os_exit_code = -1 

    var err_code = OS.execute(full_script_path, final_script_args, os_output_array, os_exit_code, true) 

    if err_code != OK:
        var err_msg = _get_godot_error_message(err_code)
        log_display.push_color(Color.RED)
        log_display.append_text(log_prefix + "CRITICAL ERROR: Failed to start script " + script_name + ".\n")
        log_display.append_text(log_prefix + "OS.execute returned: " + err_msg + " (Code: " + str(err_code) + ").\n")
        log_display.pop()
        return false

    for line in os_output_array:
        log_display.append_text(log_prefix + str(line).strip_edges() + "\n")

    if os_exit_code == 0:
        log_display.push_color(Color.GREEN)
        log_display.append_text(log_prefix + script_name + " completed successfully.\n")
        log_display.pop()
        return true
    else:
        log_display.push_color(Color.RED)
        log_display.append_text(log_prefix + "CRITICAL ERROR: " + script_name + " failed with exit code: " + str(os_exit_code) + ".\n")
        log_display.pop()
        return false

func _cleanup_temp_files(paths_to_delete: Array):
    log_display.add_text("\n[Cleanup] Attempting to delete temporary files...\n")
    # ... (implementation as before)
    var all_deleted = true
    for file_path_raw in paths_to_delete:
        var file_path = ProjectSettings.globalize_path(file_path_raw)
        if FileAccess.file_exists(file_path):
            var err = DirAccess.remove_absolute(file_path) 
            if err == OK:
                log_display.append_text("[Cleanup] Deleted: " + file_path + "\n")
            else:
                log_display.push_color(Color.YELLOW)
                log_display.append_text("[Cleanup] WARNING: FAILED to delete: " + file_path + " (Error: " + _get_godot_error_message(err) + ")\n")
                log_display.pop()
                all_deleted = false
        else:
            log_display.append_text("[Cleanup] File not found, skipping delete: " + file_path + "\n")
    if all_deleted:
        log_display.append_text("[Cleanup] Temporary file cleanup process completed.\n")
    else:
        log_display.append_text("[Cleanup] Some temporary files could not be deleted. See logs above.\n")


func _on_start_rigging_pressed():
    log_display.clear()
    log_display.add_text("[b]Starting FULL rigging workflow...[/b]\n")
    log_display.add_text("------------------------------------\n")

    # --- 1. Validations ---
    var unirig_path_validation_msg = _validate_unirig_path(unirig_path_edit.text)
    if not unirig_path_validation_msg.begins_with("Status: [color=green]UniRig path appears valid.[/color]"):
        log_display.push_color(Color.RED)
        log_display.append_text("ERROR: UniRig path validation failed. Cannot start rigging.\n")
        log_display.append_text(unirig_path_validation_msg.replace("Status: ", "") + "\n") # Show detailed message from validator
        log_display.pop()
        log_display.add_text("Aborting workflow.\n------------------------------------\n")
        return

    var input_glb_raw = input_file_edit.text
    if input_glb_raw.is_empty():
        log_display.push_color(Color.RED)
        log_display.append_text("ERROR: Input .glb file not selected.\nAborting workflow.\n------------------------------------\n")
        log_display.pop()
        return
    
    var output_glb_raw = output_file_edit.text 
    if output_glb_raw.is_empty():
        log_display.push_color(Color.RED)
        log_display.append_text("ERROR: Output .glb file path not specified.\nAborting workflow.\n------------------------------------\n")
        log_display.pop()
        return

    var global_input_glb = ProjectSettings.globalize_path(input_glb_raw)
    if not FileAccess.file_exists(global_input_glb):
        log_display.push_color(Color.RED)
        log_display.append_text("ERROR: Input .glb file not found at resolved path: " + global_input_glb + "\n")
        log_display.append_text("(Original path was: " + input_glb_raw + ")\n")
        log_display.pop()
        log_display.add_text("Aborting workflow.\n------------------------------------\n")
        return

    var global_output_glb = ProjectSettings.globalize_path(output_glb_raw)
    var output_dir = global_output_glb.get_base_dir()
    if not DirAccess.dir_exists_absolute(output_dir):
        log_display.append_text("Output directory '" + output_dir + "' does not exist. Attempting to create...\n")
        var mk_err = DirAccess.make_dir_recursive_absolute(output_dir)
        if mk_err != OK:
             log_display.push_color(Color.RED)
             log_display.append_text("ERROR: Output directory does not exist and cannot be created: " + output_dir + "\n")
             log_display.append_text("Godot Error: " + _get_godot_error_message(mk_err) + "\n")
             log_display.pop()
             log_display.add_text("Aborting workflow.\n------------------------------------\n")
             return
        else:
             log_display.push_color(Color.GREEN)
             log_display.append_text("Successfully created output directory: " + output_dir + "\n")
             log_display.pop()


    # --- 2. Temporary Directory and Paths ---
    # ... (as before, no changes here)
    var temp_dir_path = "user://unirig_temp"
    var abs_temp_dir_path = ProjectSettings.globalize_path(temp_dir_path)
    if not DirAccess.dir_exists_absolute(abs_temp_dir_path):
        var mk_err = DirAccess.make_dir_recursive_absolute(abs_temp_dir_path)
        if mk_err != OK:
            log_display.push_color(Color.RED)
            log_display.append_text("ERROR: Could not create temporary directory: " + abs_temp_dir_path + ". Error: " + _get_godot_error_message(mk_err) + "\n")
            log_display.pop()
            return
        else:
            log_display.push_color(Color.GREEN)
            log_display.append_text("Created temporary directory: " + abs_temp_dir_path + "\n")
            log_display.pop()
    var global_temp_skeleton_fbx = ProjectSettings.globalize_path(temp_dir_path + "/temp_skeleton.fbx")
    var global_temp_skin_fbx = ProjectSettings.globalize_path(temp_dir_path + "/temp_skin.fbx")
    var temp_files_to_clean = [global_temp_skeleton_fbx, global_temp_skin_fbx]


    # --- 3. Step 1: Generate Skeleton ---
    log_display.append_text("\n[b][Skeleton][/b] Starting skeleton generation (generate_skeleton.sh)...\n")
    var skeleton_args = ["--input", global_input_glb, "--output", global_temp_skeleton_fbx]
    var seed_text = seed_edit.text.strip_edges()
    if not seed_text.is_empty():
        if seed_text.is_valid_int():
            skeleton_args.append("--seed"); skeleton_args.append(seed_text)
        else:
            log_display.push_color(Color.YELLOW)
            log_display.append_text("WARNING: Seed value '" + seed_text + "' is not a valid integer. Ignoring seed for skeleton generation.\n")
            log_display.pop()

    var skeleton_success = _run_unirig_script("generate_skeleton.sh", skeleton_args, "[Skeleton] ")
    if not skeleton_success:
        log_display.push_color(Color.RED)
        log_display.append_text("ERROR: Skeleton generation failed. Stopping workflow.\n------------------------------------\n")
        log_display.pop()
        # _cleanup_temp_files(temp_files_to_clean) 
        return

    # --- 4. Step 2: Generate Skinning Weights ---
    log_display.append_text("\n[b][Skinning][/b] Starting skinning weight generation (generate_skin.sh)...\n")
    if not FileAccess.file_exists(global_temp_skeleton_fbx):
        log_display.push_color(Color.RED)
        log_display.append_text("CRITICAL ERROR: Skeleton output file ('%s') not found after skeleton generation. Cannot proceed with skinning.\n" % global_temp_skeleton_fbx)
        log_display.pop()
        log_display.add_text("Aborting workflow.\n------------------------------------\n")
        # _cleanup_temp_files(temp_files_to_clean)
        return

    var skin_args = ["--input", global_temp_skeleton_fbx, "--output", global_temp_skin_fbx]
    var skin_success = _run_unirig_script("generate_skin.sh", skin_args, "[Skinning] ")
    if not skin_success:
        log_display.push_color(Color.RED)
        log_display.append_text("ERROR: Skinning weight generation failed. Stopping workflow.\n------------------------------------\n")
        log_display.pop()
        # _cleanup_temp_files(temp_files_to_clean)
        return

    # --- 5. Step 3: Merge Results ---
    log_display.append_text("\n[b][Merge][/b] Starting merge process (merge.sh)...\n")
    if not FileAccess.file_exists(global_temp_skin_fbx):
        log_display.push_color(Color.RED)
        log_display.append_text("CRITICAL ERROR: Skinning output file ('%s') not found after skinning. Cannot proceed with merging.\n" % global_temp_skin_fbx)
        log_display.pop()
        log_display.add_text("Aborting workflow.\n------------------------------------\n")
        # _cleanup_temp_files(temp_files_to_clean)
        return
        
    var merge_args = ["--source", global_temp_skin_fbx, "--target", global_input_glb, "--output", global_output_glb]
    var merge_success = _run_unirig_script("merge.sh", merge_args, "[Merge] ")
    if not merge_success:
        log_display.push_color(Color.RED)
        log_display.append_text("ERROR: Merge process failed.\n------------------------------------\n")
        log_display.pop()
        # _cleanup_temp_files(temp_files_to_clean)
        return

    # --- 6. Final Message ---
    log_display.push_color(Color.GREEN)
    log_display.append_text("\n[b]SUCCESS: Rigging workflow completed![/b]\n")
    log_display.pop()
    log_display.append_text("Output saved to: " + output_file_edit.text + " (resolved to " + global_output_glb + ")\n")
    log_display.add_text("------------------------------------\n")
    
    # --- 7. Cleanup (Optional) ---
    # _cleanup_temp_files(temp_files_to_clean) 

# Ensure this script is saved in addons/UniRigPlugin/unirig_plugin.gd
