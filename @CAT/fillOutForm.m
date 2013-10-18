function fillOutForm(setupCat)
%% CAT.fillOutForm(setupCat)
% fillOutForm is a (static) method of the CAT class. Given the cell  array
% setupCat it fills out the protocat template. 
% Note that setupCat must have exactly length == 11 and an input order as
% indicated in protocat.

for i = 1:length(setupCat)
    if isa(setupCat{i},'function_handle')
        setupCat{i} = func2str(setupCat{i});
    elseif isnumeric(setupCat{i})
        setupCat{i} = mat2str(setupCat{i});
    elseif isa(setupCat{i},'Distribution')
        setupCat{i} = Dist2str(setupCat{i});
    elseif isstr(setupCat{i})
        setupCat{i} = strcat('''',setupCat{i},'''');
    end
end

n = 1;
while exist(strcat('kitten_form',num2str(n)),'file')
    n = n+1;
end
fidnew = fopen(strcat('kitten_form',num2str(n),'.m'),'w+');
fid = fopen('protocat.m');


tline = fgets(fid);
i = 1;
while ischar(tline)
    tline = fgets(fid);
    
    if ischar(tline) && ~isempty(strfind(tline,'XXX'))
        if isempty(setupCat{i})
            tnew = strrep(tline, tline, strcat('%% ',tline));
        else
            tnew = strrep(tline, 'XXX', setupCat{i});
        end
        i = i + 1;
    elseif ischar(tline)
        tnew = tline;
    else
        tnew = '\n \n %% This file was generated for you by the fillOutForm function.';
    end
    fprintf(fidnew,tnew);

end

fclose(fid);
fclose(fidnew);
