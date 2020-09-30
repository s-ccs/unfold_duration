ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"&fn.overlap=="overlap-1";
%ix = fn.overlapdist == "uniform" & fn.shape=="box" & fn.overlapmod == "overlapmod-1.5.mat" 
plot_result(fn(ix,:))
