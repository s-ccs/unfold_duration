function copy_figure_to_axis(h_source,h_target)
hFigIAxes = findobj('Parent',h_source,'Type','axes');

if ~isempty(hFigIAxes)
    for hAxes = hFigIAxes'
        %hAxes = hFigIAxes(1);  % assume just the one axes
        copyobj(get(hAxes,'Children'),h_target);
        
        for prop= {'XLim','YLim','ZLim','xlabel','ylabel','XTick','XTickLabel','YTick','YTickLabel','title'}
            set(h_target,prop{1},get(hAxes,prop{1}))
        end
        
    end
end
end