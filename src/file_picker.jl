
@kwdef mutable struct FilePickerState
    current_dir::String
    selected_file::String
    window_open::Bool = false
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
        CImGui.ImText("File Browser:")
        
        # Create a child window for the file browser
        if CImGui.BeginChild("FileBrowser", CImGui.ImVec2(0, 200), true)
            CImGui.ImText("Current directory: " * fp.current_dir)

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
                        end
                    end
                end
            end
            CImGui.EndChild()
        end
    end
end

export ShowFilePicker, FilePickerState