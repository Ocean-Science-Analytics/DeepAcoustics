function handles = render_ann_boxes(current_axes,handles,roi, fill_heigth)
%% This function draws rectangles in the focus view and page view

axis_xlim = get(current_axes,'Xlim');
axis_ylim = get(current_axes,'Ylim');


% Find calls within the current window
calls_in_page = find( (handles.data.anncalls.Box(:,1) >= axis_xlim(1) & handles.data.anncalls.Box(:,1) < axis_xlim(2)  ) ...
    | ( handles.data.anncalls.Box(:,1) + handles.data.anncalls.Box(:,3)  >= axis_xlim(1) & handles.data.anncalls.Box(:,1) + handles.data.anncalls.Box(:,3)  <= axis_xlim(2) )...
    | ( handles.data.anncalls.Box(:,1)<=  axis_xlim(1) & handles.data.anncalls.Box(:,1) + handles.data.anncalls.Box(:,3) >=  axis_xlim(2) )...
    );

boxes = handles.data.anncalls.Box(calls_in_page,:);

% Draw labels if there are any labels other than 'Call'
% if ~isempty(calls_in_page) any(handles.data.calls.Type ~= 'Call')
    LabelVisible = 'on'; % use 'hover' to only display labels on mouse over2
% else
%     LabelVisible = 'off';
% end

% Loop through all calls
for box_number = 1:length(calls_in_page)
    current_tag = num2str(calls_in_page(box_number));
    
    if fill_heigth
        boxes(box_number,2) = axis_ylim(1);
        boxes(box_number,4) = axis_ylim(2);
    end
    
    line_width = 0.5;
    box_color = [91, 207, 244] / 255; 
    line_style = '-';
    
    if roi
        
        % Only display a label if it isn't just "Call"
        if handles.data.anncalls.Type(calls_in_page(box_number)) == {'Call'}
            label = '';
        else
            label = char(handles.data.anncalls.Type(calls_in_page(box_number)));
        end
        
        % Add a new rectangle if there isn't a handle for one yet, or
        % update an existing one
        if box_number > length(handles.FocusWindowAnnRectangles) % draw a new rectangle if we need more
            c = uicontextmenu;
            handles.FocusWindowAnnRectangles{box_number} = drawrectangle(...
                'Position', boxes(box_number, :),...
                'Parent', current_axes,...
                'Color', box_color,...
                'FaceAlpha', 0,...
                'LineWidth', line_width,...
                'Tag', current_tag,...
                'uicontextmenu', c,...
                'label', label,...
                'LabelAlpha', .5,...
                'LabelVisible', LabelVisible);
            addlistener(handles.FocusWindowAnnRectangles{box_number},'ROIClicked',@callBoxDeleteCallback);
            addlistener(handles.FocusWindowAnnRectangles{box_number},'ROIMoved', @roiMovedCallback);
        else
            set(handles.FocusWindowAnnRectangles{box_number},...
                'Position', boxes(box_number, :),...
                'Color', box_color,...
                'LineWidth', line_width,...
                'Tag', current_tag,...
                'Visible', true,...
                'label', label,...
                'LabelVisible', LabelVisible);
        end
        
    else
        % Add a new rectangle if there isn't a handle for one yet, or
        % update an existing one
        if box_number > length(handles.PageWindowAnnRectangles)
            handles.PageWindowAnnRectangles{box_number} = rectangle(current_axes,...
                'Position',  boxes(box_number, :),...
                'LineWidth', line_width,...
                'LineStyle', line_style,...
                'EdgeColor', box_color,...
                'PickableParts', 'none');
        else
            set(handles.PageWindowAnnRectangles{box_number},...
                'Position',  boxes(box_number, :),...
                'EdgeColor', box_color,...
                'LineWidth', line_width,...
                'Visible', true)
        end
        
    end
end

% Make any extra boxes invisible
if roi
    for i = length(calls_in_page)+1:length(handles.FocusWindowAnnRectangles)
        handles.FocusWindowAnnRectangles{i}.Visible = false;
    end
else
    for i = length(calls_in_page)+1:length(handles.PageWindowAnnRectangles)
        handles.PageWindowAnnRectangles{i}.Visible = false;
    end
end

end

