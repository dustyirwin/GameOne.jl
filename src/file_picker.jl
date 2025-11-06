
@kwdef mutable struct FilePickerState
    current_dir::String
    selected_file::String
    window_open::Bool = false
    save_mode::Bool = false  # true for save dialog, false for open dialog
    filename_buffer::String = ""
end

function ShowFilePicker(gs::Dict; file_extensions=String[])
    fp = gs[:ig_file_picker_state]
    
    # Show as a child window instead of popup to avoid modal conflicts
    if fp.window_open
        # Initialize current directory to a reasonable default if empty
        if isempty(fp.current_dir) || !isdir(fp.current_dir)
            fp.current_dir = abspath(homedir())
        end
        
        CImGui.Separator()
        CImGui.Text("File Browser:")
        
        # Create a child window for the file browser
        if CImGui.BeginChild("FileBrowser", CImGui.ImVec2(0, 300), true)
            CImGui.TextWrapped("Current directory: " * fp.current_dir)

            # Parent directory navigation
            if CImGui.Button("..")
                parent_dir = dirname(fp.current_dir)
                # Don't navigate above the root (avoid going from C:\ to empty string)
                if parent_dir != fp.current_dir && !isempty(parent_dir)
                    fp.current_dir = parent_dir
                end
            end

            files = try
                all_files = sort(readdir(fp.current_dir))
                # Filter to show directories and specified file types
                if isempty(file_extensions)
                    # Default to image files if no extensions specified
                    default_extensions = [".png", ".jpg", ".jpeg", ".webp", ".bmp", ".txt",".mox"]
                    filter(f -> begin
                        fullpath = joinpath(fp.current_dir, f)
                        try
                            isdir(fullpath) || lowercase(splitext(f)[2]) in default_extensions
                        catch
                            # If we can't check the file, include it anyway (might be permissions issue)
                            true
                        end
                    end, all_files)
                else
                    filter(f -> begin
                        fullpath = joinpath(fp.current_dir, f)
                        try
                            isdir(fullpath) || lowercase(splitext(f)[2]) in file_extensions
                        catch
                            # If we can't check the file, include it anyway (might be permissions issue)
                            true
                        end
                    end, all_files)
                end
            catch e
                @warn "Error reading directory $(fp.current_dir): $e"
                String[]
            end

            if isempty(files)
                CImGui.TextColored(ImVec4(1,1,0.5,1), "No files or folders found in this directory.")
            else
                for f in files
                    fullpath = joinpath(fp.current_dir, f)
                    is_directory = false
                    try
                        is_directory = isdir(fullpath)
                    catch
                        # If we can't determine if it's a directory, assume it's a file
                        is_directory = false
                    end
                    
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
                        end
                    end
                end
            end
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
    end
end

"""
    ShowSaveFileDialog(gs::Dict; default_filename="", file_extensions=String[])

Opens a save file dialog. Returns the selected file path when user confirms, or empty string if cancelled.
Set gs[:ig_file_picker_state].window_open = true to activate.
"""
function ShowSaveFileDialog(gs::Dict; default_filename="", file_extensions=String[])
    if !haskey(gs, :ig_file_picker_state)
        gs[:ig_file_picker_state] = FilePickerState(
            current_dir = abspath(homedir()),
            selected_file = "",
            window_open = true,
            save_mode = true,
            filename_buffer = default_filename
        )
    end
    
    fp = gs[:ig_file_picker_state]
    fp.save_mode = true
    
    if !isempty(default_filename) && isempty(fp.filename_buffer)
        fp.filename_buffer = default_filename
    end
    
    ShowFilePicker(gs; file_extensions=file_extensions)
    
    return fp.selected_file
end

export ShowFilePicker, ShowSaveFileDialog, FilePickerState