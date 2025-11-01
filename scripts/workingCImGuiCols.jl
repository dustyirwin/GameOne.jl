    # scrolling columns
    if CImGui.TreeNode("Vertical Scrolling")
        # --- Header ---
        CImGui.BeginChild("##header", ImVec2(0, CImGui.GetTextLineHeightWithSpacing() + unsafe_load(CImGui.GetStyle().ItemSpacing).y))
        CImGui.Columns(3, C_NULL, true)  # Enable borders for resizing
        CImGui.Text("ID"); CImGui.NextColumn()
        CImGui.Text("Name"); CImGui.NextColumn()
        CImGui.Text("Path"); CImGui.NextColumn()
        # After drawing header, record column widths
        global header_col_widths = [CImGui.GetColumnWidth(i) for i in 0:2]
        CImGui.Columns(1)
        CImGui.Separator()
        CImGui.EndChild()

        # --- Data Table ---
        CImGui.BeginChild("##verticalscrollingregion", ImVec2(0, 60))
        CImGui.Columns(3, C_NULL, true)  # Enable borders for resizing
        # Set data table column widths to match header
        if @isdefined header_col_widths
            for i in 0:2
                CImGui.SetColumnWidth(i, header_col_widths[i+1])
            end
        end
        for i = 0:9
            CImGui.Text(@sprintf("%04d", i))
            CImGui.NextColumn()
            CImGui.Text("Foobar")
            CImGui.NextColumn()
            CImGui.Text(@sprintf("/path/foobar/%04d/", i))
            CImGui.NextColumn()
        end
        CImGui.Columns(1)
        CImGui.EndChild()
        CImGui.TreePop()
    end

    # --- Horizontal Scrolling ---
    if CImGui.TreeNode("Horizontal Scrolling")
        CImGui.SetNextWindowContentSize((1500.0, 0.0))
        CImGui.BeginChild("##HorizontalScrollingRegion", ImVec2(0, CImGui.GetFontSize() * 20), false, CImGui.ImGuiWindowFlags_HorizontalScrollbar)
        CImGui.Columns(10)
        ITEMS_COUNT = 2000
        
        clipper = CImGui.Clipper()
        CImGui.Begin(clipper, ITEMS_COUNT)
        while CImGui.Step(clipper)
            s = clipper.DisplayStart
            e = clipper.DisplayEnd - 1
            for i = s:e, j = 0:9
                CImGui.Text("Line $i Column $j...")
                CImGui.NextColumn()
            end
        end

        CImGui.Columns(1)
        CImGui.EndChild()
        CImGui.TreePop()
    end