function t = parse_column(t,col)
tmp = cellfun(@(x)strsplit(x,'-'),t{:,col},'UniformOutput',false);
t.(col) = cellfun(@(x)str2num(x),cellfun(@(x)x{2},tmp,'UniformOutput',false));
end
