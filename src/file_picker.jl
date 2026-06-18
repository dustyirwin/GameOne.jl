
@kwdef mutable struct FilePickerState
    current_dir::String
    selected_file::String
    window_open::Bool = false
    save_mode::Bool = false  # true for save dialog, false for open dialog
    filename_buffer::String = ""
end

"""
    get_available_drives() -> Vector{String}

Return a sorted list of available drive letters (e.g. ["C:\\", "D:\\"]) on Windows,
or an empty vector on other platforms.
"""
function get_available_drives()::Vector{String}
    drives = String[]
    try
        # On Windows, `readdir("C:\\")` works for any drive root.
        # We enumerate letters A-Z and test if the drive exists.
        for c in 'A':'Z'
            drive = "$(c):\\\\"
            try
                if !isempty(readdir(drive)) || isdir(drive)
                    push!(drives, drive)
                end
            catch
                # Drive doesn't exist or isn't accessible (e.g. empty CD-ROM)
                # Try isdir as fallback since readdir may throw on empty drives
                try
                    if isdir(drive)
                        push!(drives, drive)
                    end
                catch
                    nothing
                end
            end
        end
    catch
        # Not on Windows or some other error — return empty
    end
    return sort(drives)
end

"""
    is_drive_root(dir::String) -> Bool

Check if `dir` is a drive root (e.g. "C:\\" on Windows).
"""
function is_drive_root(dir::String)::Bool
    # Match patterns like "C:\\", "D:\\", etc.
    return occursin(r"^[A-Za-z]:\\?$", dir)
end

function setup_file_picker_state!(
    gs::Dict, 
    key::Symbol; 
    start_dir::String=abspath(homedir()), 
    save_mode::Bool=false
    )
    
    if !haskey(gs, key)
        gs[key] = FilePickerState(
            current_dir = start_dir,
            selected_file = "",
            window_open = true,
            save_mode = save_mode,
            filename_buffer = ""
        )
    end
end

function ShowFilePicker(gs::Dict, state_key::Symbol; file_extensions=String[], as_popup::Bool=false)
    if state_key ∉ keys(gs)
        setup_file_picker_state!(gs, state_key)
    end
    fp = gs[state_key]
    
    if fp.window_open
        # Initialize current directory to a reasonable default if empty
        if isempty(fp.current_dir) || !isdir(fp.current_dir)
            fp.current_dir = abspath(homedir())
        end
        
        if as_popup
            CImGui.OpenPopup("File Picker")
            CImGui.SetNextWindowSize(CImGui.ImVec2(600, 400), CImGui.ImGuiCond_Always)
            CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowRounding, 8.0)
            if CImGui.BeginPopupModal("File Picker", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
                # Content here
            else
                fp.window_open = false
                return
            end
        else
            CImGui.Separator()
            CImGui.Text("File Browser:")
            # Create a child window for the file browser
            if !CImGui.BeginChild("FileBrowser", CImGui.ImVec2(0, 300), true)
                return
            end
        end
        
        CImGui.TextWrapped("Current directory: " * fp.current_dir)

        
        # Parent directory navigation
        # button width set to 150 for ".." button
        if CImGui.Button(" Up a level .. ", CImGui.ImVec2(150, 0))
            parent_dir = dirname(fp.current_dir)
            # Check if we're at a drive root — if so, enumerate drives instead
            if is_drive_root(fp.current_dir)
                drives = get_available_drives()
                if !isempty(drives)
                    # Cycle to the next available drive
                    idx = findfirst(d -> d == fp.current_dir, drives)
                    if idx !== nothing && idx < length(drives)
                        fp.current_dir = drives[idx + 1]
                    elseif idx !== nothing
                        # Wrap around to first drive
                        fp.current_dir = drives[1]
                    end
                end
            elseif parent_dir != fp.current_dir && !isempty(parent_dir)
                fp.current_dir = parent_dir
            end
        end

        # Show available drives when at a drive root
        drives = String[]
        if is_drive_root(fp.current_dir)
            drives = get_available_drives()
        end
        
        files = try
            all_files = sort(readdir(fp.current_dir))
            # Show all files and directories (no extension filtering)
            filter(f -> begin
                fullpath = joinpath(fp.current_dir, f)
                # Filter out hidden files (starting with .)
                !startswith(f, ".")
            end, all_files)
        catch e
            @warn "Error reading directory $(fp.current_dir): $e"
            String[]
        end

        # Separate directories and files, then sort each group alphabetically
        dirs = String[]
        file_list = String[]
        for f in files
            fullpath = joinpath(fp.current_dir, f)
            try
                if isdir(fullpath)
                    push!(dirs, f)
                else
                    push!(file_list, f)
                end
            catch
                push!(file_list, f)
            end
        end
        sort!(dirs)
        sort!(file_list)
        
        # Prepend drive entries if we're at a drive root and have other drives available
        if !isempty(drives) && length(drives) > 1
            # Show other drives as selectable items before the directory listing
            for d in drives
                if d != fp.current_dir
                    label = replace(d, "\\" => "\\\\")  # Escape backslashes for display
                    if CImGui.Selectable("[DRIVE] $label", false)
                        fp.current_dir = d
                        break
                    end
                end
            end
        end

        if isempty(dirs) && isempty(file_list) && isempty(drives)
            CImGui.TextColored(ImVec4(1,1,0.5,1), "No files or folders found in this directory.")
        else
            # Render directories first, then files
            for f in vcat(dirs, file_list)
                fullpath = joinpath(fp.current_dir, f)
                is_directory = f in dirs
                
                if is_directory

                    if CImGui.Selectable("[DIR] $f", false)
                        try
                            # Test if we can access the directory before navigating
                            readdir(fullpath)
                            fp.current_dir = fullpath
                        catch e
                            @warn "Cannot access directory $fullpath: $e"
                        end
                        break
                    end
                else
                    if CImGui.Selectable(f, fp.selected_file == fullpath)
                        fp.selected_file = fullpath
                        # In save mode, populate the filename buffer when clicking a file
                        if fp.save_mode
                            fp.filename_buffer = f
                        end
                        # For open mode, if not popup, close immediately
                        if !fp.save_mode && !as_popup
                            fp.window_open = false
                        end
                    end
                end
            end
        end
        
        if as_popup
            CImGui.Separator()
            if CImGui.Button("OK")
                fp.window_open = false
                CImGui.CloseCurrentPopup()
            end
            CImGui.SameLine()
            if CImGui.Button("Cancel")
                fp.selected_file = ""  # Clear any selection
                fp.window_open = false
                CImGui.CloseCurrentPopup()
            end
        end
        
        if !as_popup
            CImGui.EndChild()
        end
        
        # Add filename input for save mode
        if fp.save_mode
            CImGui.Separator()
            @cstatic filename_input=""*"\0"^256 begin
                # Sync buffer with state
                if !isempty(fp.filename_buffer)
                    filename_input = fp.filename_buffer * "\0"^(256 - length(fp.filename_buffer))
                end
                
                CImGui.Text("Filename:")
                CImGui.SameLine()
                CImGui.SetNextItemWidth(300)
                if CImGui.InputText("##filename", filename_input, length(filename_input))
                    fp.filename_buffer = rstrip(string(filename_input), '\0')
                end
            end
            
            # Update selected_file with the full path
            if !isempty(fp.filename_buffer)
                fp.selected_file = joinpath(fp.current_dir, fp.filename_buffer)
            end
        end
        
        if as_popup
            CImGui.EndPopup()
            CImGui.PopStyleVar(1)
        end
    end
end

"""
    ShowSaveFileDialog(gs::Dict, key::Symbol; default_filename="", file_extensions=String[])

Opens a save file dialog. Returns the selected file path when user confirms, or empty string if cancelled.
Set gs[:ig_file_picker_state].window_open = true to activate.
"""
function ShowSaveFileDialog(gs::Dict, key::Symbol; default_filename="", file_extensions=String[])
    if !haskey(gs, key)
        gs[key] = FilePickerState(
            current_dir = abspath(homedir()),
            selected_file = "",
            window_open = true,
            save_mode = true,
            filename_buffer = default_filename
        )
    end
    
    fp = gs[key]
    fp.save_mode = true
    
    if !isempty(default_filename) && isempty(fp.filename_buffer)
        fp.filename_buffer = default_filename
    end
    
    ShowFilePicker(gs, :ig_deck_file_picker_state, file_extensions=file_extensions)
    
    return fp.selected_file
end

export ShowFilePicker, ShowSaveFileDialog, FilePickerState