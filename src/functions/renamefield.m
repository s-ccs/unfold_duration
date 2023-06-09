% Function to rename fields in a structure array
function structOut = renamefield(structIn, oldField, newField)                         
    for i = 1:length(structIn)          
        structIn = setfield(structIn,{i},newField,getfield(structIn(i),oldField));                
    end         
structOut = rmfield(structIn,oldField);                    
end
